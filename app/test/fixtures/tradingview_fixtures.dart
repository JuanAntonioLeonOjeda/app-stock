import 'dart:io';

/// Cuerpo de una respuesta real de TradingView guardada en
/// `test/fixtures/tradingview/<name>.json` (`flutter test` se ejecuta desde
/// app/). Para capturar más: `tool/capture_tradingview_fixtures.sh`.
String readTradingViewFixture(String name) =>
    File('test/fixtures/tradingview/$name.json').readAsStringSync();
