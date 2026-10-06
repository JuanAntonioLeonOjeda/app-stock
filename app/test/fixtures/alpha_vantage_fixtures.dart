import 'dart:io';

/// Cuerpo de una respuesta real de Alpha Vantage guardada en
/// `test/fixtures/alpha_vantage/<name>.json` (`flutter test` se ejecuta
/// desde app/). Para capturar más: `tool/capture_fixtures.sh`.
String readAlphaVantageFixture(String name) =>
    File('test/fixtures/alpha_vantage/$name.json').readAsStringSync();
