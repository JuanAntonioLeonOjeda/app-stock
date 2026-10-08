// Protocolo del canal de gráficos de TradingView (WebSocket no oficial): cómo
// se enmarcan los mensajes, qué se pide y cómo se lee la serie de velas.
// Todo son funciones puras, probadas con una transcripción real guardada.

import 'dart:convert';

import 'package:stock_app/features/analisis_accion/domain/entities/daily_bar.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';

/// Id de la serie que se pide; en la respuesta llega bajo esta clave.
const _seriesId = 'sds_1';
const _symbolId = 'sds_sym_1';

/// Margen relativo con el que un cierre puede quedar fuera de [mínimo, máximo]
/// por redondeos del ajuste de splits antes de descartar la vela.
const _rangeTolerance = 1e-6;

/// Enmarca un mensaje como `~m~<longitud>~m~<texto>`. La longitud cuenta
/// unidades UTF-16, igual que `length` en Dart.
String frameMessage(String text) => '~m~${text.length}~m~$text';

/// Parte un paquete recibido en sus mensajes. Un paquete puede traer varios.
///
/// Lanza `InvalidResponseException` si el marco está mal formado.
List<String> splitFrames(String payload) {
  final messages = <String>[];
  var position = 0;
  while (position < payload.length) {
    if (!payload.startsWith('~m~', position)) {
      throw const InvalidResponseException('Paquete sin marco ~m~');
    }
    final lengthStart = position + 3;
    final lengthEnd = payload.indexOf('~m~', lengthStart);
    final length = lengthEnd < 0
        ? null
        : int.tryParse(payload.substring(lengthStart, lengthEnd));
    if (length == null) {
      throw const InvalidResponseException('Longitud de marco ilegible');
    }
    final textStart = lengthEnd + 3;
    if (textStart + length > payload.length) {
      throw const InvalidResponseException('Marco truncado');
    }
    messages.add(payload.substring(textStart, textStart + length));
    position = textStart + length;
  }
  return messages;
}

/// Resolución de las velas diarias en el protocolo.
const dailyResolution = 'D';

/// Una vela tal como llega, con el instante exacto en que empieza.
class Candle {
  const Candle({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  /// Instante de inicio, en UTC.
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;
}

/// La vela como diaria: su fecha es el día en UTC (medianoche).
DailyBar toDailyBar(Candle candle) => DailyBar(
  date: DateTime.utc(candle.time.year, candle.time.month, candle.time.day),
  open: candle.open,
  high: candle.high,
  low: candle.low,
  close: candle.close,
  volume: candle.volume,
);

/// Mensajes (ya enmarcados) que piden [bars] velas de [ticker] con la
/// [resolution] dada (`"D"` diaria, `"5"` o `"30"` minutos), con precios
/// ajustados por splits.
List<String> buildHistoryRequest({
  required String session,
  required String ticker,
  required int bars,
  String resolution = dailyResolution,
}) {
  String call(String method, List<Object> params) =>
      frameMessage(jsonEncode({'m': method, 'p': params}));
  final symbol = jsonEncode({'symbol': ticker, 'adjustment': 'splits'});
  return [
    call('set_auth_token', ['unauthorized_user_token']),
    call('chart_create_session', [session, '']),
    call('resolve_symbol', [session, _symbolId, '=$symbol']),
    call('create_series', [
      session,
      _seriesId,
      's1',
      _symbolId,
      resolution,
      bars,
      '',
    ]),
  ];
}

/// Lo que puede decir el servidor sobre la petición.
sealed class ChartEvent {
  const ChartEvent();
}

/// Latido `~h~n`: hay que devolverlo tal cual, enmarcado.
final class Heartbeat extends ChartEvent {
  const Heartbeat(this.text);

  final String text;
}

/// Un trozo de la serie de velas (puede haber varios).
final class BarsReceived extends ChartEvent {
  const BarsReceived(this.candles);

  final List<Candle> candles;
}

/// El servidor ha resuelto el símbolo: da la zona horaria de la bolsa y, según
/// la bolsa, el retraso de los precios.
final class SymbolResolved extends ChartEvent {
  const SymbolResolved({this.timezone, this.delay});

  final String? timezone;
  final Duration? delay;
}

/// El servidor ha terminado de enviar la serie.
final class SeriesCompleted extends ChartEvent {
  const SeriesCompleted();
}

/// El símbolo no existe para el servidor.
final class SymbolNotFound extends ChartEvent {
  const SymbolNotFound();
}

/// Un error del servidor que no es un símbolo inexistente.
final class ServerError extends ChartEvent {
  const ServerError(this.details);

  final String details;
}

/// Mensajes que no hacen falta (sesión, carga, símbolo resuelto...).
final class IgnoredMessage extends ChartEvent {
  const IgnoredMessage();
}

/// Interpreta un mensaje ya separado del marco.
///
/// Lanza `InvalidResponseException` si es un JSON ilegible o una serie con
/// otra forma.
ChartEvent parseChartMessage(String message) {
  if (message.startsWith('~h~')) return Heartbeat(message);
  final Object? decoded;
  try {
    decoded = jsonDecode(message);
  } on FormatException {
    throw const InvalidResponseException('Mensaje que no es JSON');
  }
  if (decoded is! Map<String, Object?>) return const IgnoredMessage();
  final method = decoded['m'];
  return switch (method) {
    'timescale_update' => BarsReceived(_candles(decoded)),
    'symbol_resolved' => _symbolResolved(decoded),
    'series_completed' => const SeriesCompleted(),
    'symbol_error' => const SymbolNotFound(),
    'series_error' || 'critical_error' => ServerError(method as String),
    _ => const IgnoredMessage(),
  };
}

SymbolResolved _symbolResolved(Map<String, Object?> message) {
  final params = message['p'];
  final info = params is List<Object?> && params.length > 2 ? params[2] : null;
  if (info is! Map<String, Object?>) return const SymbolResolved();
  final timezone = info['timezone'];
  final delay = info['delay'];
  return SymbolResolved(
    timezone: timezone is String && timezone.isNotEmpty ? timezone : null,
    delay: delay is num && delay > 0 ? Duration(seconds: delay.round()) : null,
  );
}

List<Candle> _candles(Map<String, Object?> message) {
  final params = message['p'];
  final series = params is List<Object?> && params.length > 1
      ? params[1]
      : null;
  final data = series is Map<String, Object?> ? series[_seriesId] : null;
  final entries = data is Map<String, Object?> ? data['s'] : null;
  if (entries is! List<Object?>) {
    throw const InvalidResponseException('timescale_update sin serie');
  }
  return [for (final entry in entries) ?_candle(entry)];
}

/// Una vela, o `null` si es incoherente y hay que descartarla (criterio 57).
Candle? _candle(Object? entry) {
  final values = entry is Map<String, Object?> ? entry['v'] : null;
  if (values is! List<Object?> || values.length < 5) return null;
  final numbers = [
    for (final value in values)
      if (value is num) value.toDouble() else null,
  ];
  final seconds = numbers[0];
  final open = numbers[1];
  final high = numbers[2];
  final low = numbers[3];
  final close = numbers[4];
  if (seconds == null ||
      open == null ||
      high == null ||
      low == null ||
      close == null) {
    return null;
  }
  if ([open, high, low, close].any((v) => !v.isFinite || v <= 0)) return null;
  final margin = high * _rangeTolerance;
  if (high < low || close > high + margin || close < low - margin) return null;
  final moment = DateTime.fromMillisecondsSinceEpoch(
    (seconds * 1000).round(),
    isUtc: true,
  );
  return Candle(
    time: moment,
    open: open,
    high: high,
    low: low,
    close: close,
    volume: numbers.length > 5 ? (numbers[5] ?? 0).round() : 0,
  );
}

/// Une los trozos de velas recibidos: sin instantes repetidos (gana el último)
/// y de la más antigua a la más reciente.
List<Candle> mergeCandles(Iterable<List<Candle>> chunks) {
  final byTime = <DateTime, Candle>{};
  for (final chunk in chunks) {
    for (final candle in chunk) {
      byTime[candle.time] = candle;
    }
  }
  return byTime.values.toList()..sort((a, b) => a.time.compareTo(b.time));
}
