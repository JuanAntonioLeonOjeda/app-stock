// Formato compacto con el que se guarda el histórico en la caché: una lista de
// `[segundos, apertura, máximo, mínimo, cierre, volumen]` por vela, unos 45
// bytes cada una (≈ 270 KB para 6.000 velas) en lugar de objetos con claves.

import 'dart:convert';

import 'package:stock_app/features/analisis_accion/domain/entities/daily_bar.dart';
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
