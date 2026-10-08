// Formato compacto con el que se guarda el histórico en la caché: una lista de
// `[segundos, apertura, máximo, mínimo, cierre, volumen]` por vela, unos 45
// bytes cada una (≈ 270 KB para 6.000 velas) en lugar de objetos con claves.

import 'dart:convert';

import 'package:stock_app/features/analisis_accion/domain/entities/daily_bar.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/intraday_bar.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/intraday_series.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';

/// El histórico como texto para la caché.
String encodeHistory(List<DailyBar> bars) => jsonEncode([
  for (final bar in bars)
    [
      bar.date.millisecondsSinceEpoch ~/ 1000,
      bar.open,
      bar.high,
      bar.low,
      bar.close,
      bar.volume,
    ],
]);

/// El histórico guardado por [encodeHistory].
///
/// Lanza `InvalidResponseException` si el texto no tiene ese formato.
List<DailyBar> decodeHistory(String text) {
  final Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException {
    throw const InvalidResponseException('Histórico guardado ilegible');
  }
  if (decoded is! List<Object?>) {
    throw const InvalidResponseException('Histórico guardado sin lista');
  }
  return [for (final entry in decoded) _bar(entry)];
}

DailyBar _bar(Object? entry) {
  if (entry is! List<Object?> || entry.length != 6) {
    throw const InvalidResponseException('Vela guardada con otra forma');
  }
  final numbers = [
    for (final value in entry)
      if (value is num)
        value.toDouble()
      else
        throw const InvalidResponseException('Vela guardada con un no número'),
  ];
  return DailyBar(
    date: DateTime.fromMillisecondsSinceEpoch(
      numbers[0].round() * 1000,
      isUtc: true,
    ),
    open: numbers[1],
    high: numbers[2],
    low: numbers[3],
    close: numbers[4],
    volume: numbers[5].round(),
  );
}

/// Las velas intradía como texto para la caché: la zona, el retraso en
/// segundos y una lista de `[segundos, cierre]` por vela.
String encodeIntraday(IntradaySeries series) => jsonEncode({
  'tz': series.timezone,
  'delay': series.delay?.inSeconds,
  'bars': [
    for (final bar in series.bars)
      [bar.time.millisecondsSinceEpoch ~/ 1000, bar.close],
  ],
});

/// Las velas intradía guardadas por [encodeIntraday].
///
/// Lanza `InvalidResponseException` si el texto no tiene ese formato.
IntradaySeries decodeIntraday(String text) {
  final Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException {
    throw const InvalidResponseException('Intradía guardado ilegible');
  }
  if (decoded is! Map<String, Object?>) {
    throw const InvalidResponseException('Intradía guardado sin objeto');
  }
  final bars = decoded['bars'];
  if (bars is! List<Object?>) {
    throw const InvalidResponseException('Intradía guardado sin velas');
  }
  final timezone = decoded['tz'];
  final delay = decoded['delay'];
  return IntradaySeries(
    bars: [for (final entry in bars) _intradayBar(entry)],
    timezone: timezone is String ? timezone : null,
    delay: delay is num ? Duration(seconds: delay.round()) : null,
  );
}

IntradayBar _intradayBar(Object? entry) {
  if (entry case [final num seconds, final num close]) {
    return IntradayBar(
      time: DateTime.fromMillisecondsSinceEpoch(
        seconds.round() * 1000,
        isUtc: true,
      ),
      close: close.toDouble(),
    );
  }
  throw const InvalidResponseException('Vela intradía guardada ilegible');
}
