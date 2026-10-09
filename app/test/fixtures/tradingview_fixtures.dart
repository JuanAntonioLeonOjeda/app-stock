import 'dart:convert';
import 'dart:io';

/// Cuerpo de una respuesta real de TradingView guardada en
/// `test/fixtures/tradingview/<name>.json` (`flutter test` se ejecuta desde
/// app/). Para capturar más: `tool/capture_tradingview_fixtures.sh`.
String readTradingViewFixture(String name) =>
    File('test/fixtures/tradingview/$name.json').readAsStringSync();

/// Transcripción real del canal de gráficos de TradingView (ver
/// `tool/capture_tradingview_chart.mjs`): los mensajes enviados y los
/// paquetes recibidos, tal cual.
({List<String> sent, List<String> received}) readChartTranscript(String name) {
  final json = jsonDecode(readTradingViewFixture(name)) as Map<String, Object?>;
  return (
    sent: [for (final m in json['sent']! as List<Object?>) m! as String],
    received: [
      for (final m in json['received']! as List<Object?>) m! as String,
    ],
  );
}
