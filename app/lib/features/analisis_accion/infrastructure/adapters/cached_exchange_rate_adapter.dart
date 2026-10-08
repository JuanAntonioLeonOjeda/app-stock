import 'dart:convert';

import 'package:stock_app/features/analisis_accion/domain/entities/exchange_rate_series.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';
import 'package:stock_app/features/analisis_accion/domain/ports/cache_port.dart';
import 'package:stock_app/features/analisis_accion/domain/ports/exchange_rate_port.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/exchange_rate_http.dart';

/// Los tipos se publican una vez al día: pedirlos más a menudo no da datos
/// nuevos (criterio 95).
const _cacheTtl = Duration(hours: 6);

const _millisPerDay = 24 * 60 * 60 * 1000;

/// [ExchangeRatePort] que guarda en caché los tipos de [_inner], sea cual sea
/// su origen (BCE o respaldo), y une las peticiones simultáneas de una moneda.
class CachedExchangeRateAdapter implements ExchangeRatePort {
  CachedExchangeRateAdapter({required this._inner, required this._cache});

  final ExchangeRatePort _inner;
  final CachePort _cache;

  /// Peticiones en curso, por moneda: la cabecera y la gráfica piden la misma.
  final Map<String, Future<ExchangeRateSeries>> _downloads = {};

  @override
  Future<ExchangeRateSeries> fetchRates(
    String isoCode, {
    bool forceRefresh = false,
  }) async {
    final code = validCurrencyCode(isoCode);
    if (code == null) throw NotFoundException('Moneda no válida: $isoCode');
    if (!forceRefresh) {
      final cached = await _read(code);
      if (cached != null) return cached;
    }
    return _downloads.putIfAbsent(
      code,
      () => _download(code, forceRefresh).whenComplete(() {
        // Con cuerpo y sin devolver nada: `remove` devuelve este mismo Future
        // y `whenComplete` se esperaría a sí mismo para siempre.
        _downloads.remove(code);
      }),
    );
  }

  Future<ExchangeRateSeries> _download(String code, bool forceRefresh) async {
    final series = await _inner.fetchRates(code, forceRefresh: forceRefresh);
    await _cache.write(_key(code), encodeRates(series), _cacheTtl);
    return series;
  }

  /// Lo guardado, o `null` si no hay o ya no se puede interpretar.
  Future<ExchangeRateSeries?> _read(String code) async {
    final cached = await _cache.read(_key(code));
    if (cached == null) return null;
    try {
      return decodeRates(cached, code);
    } on MarketDataException {
      return null;
    }
  }

  static String _key(String code) => 'fx:v1:$code';
}

/// Los tipos como texto compacto para la caché: `[[días desde 1970, tipo]]`.
String encodeRates(ExchangeRateSeries series) => jsonEncode([
  for (final point in series.points)
    [point.date.millisecondsSinceEpoch ~/ _millisPerDay, point.unitsPerEuro],
]);

/// Los tipos guardados por [encodeRates].
///
/// Lanza `InvalidResponseException` si el texto no tiene ese formato.
ExchangeRateSeries decodeRates(String text, String currency) {
  final Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException {
    throw const InvalidResponseException('Tipos guardados ilegibles');
  }
  if (decoded is! List<Object?>) {
    throw const InvalidResponseException('Tipos guardados sin lista');
  }
  return ExchangeRateSeries(
    currency: currency,
    points: [for (final entry in decoded) _point(entry)],
  );
}

RatePoint _point(Object? entry) {
  if (entry case [final num days, final num rate]) {
    return RatePoint(
      DateTime.fromMillisecondsSinceEpoch(
        days.round() * _millisPerDay,
        isUtc: true,
      ),
      rate.toDouble(),
    );
  }
  throw const InvalidResponseException('Tipo guardado ilegible');
}
