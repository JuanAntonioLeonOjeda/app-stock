import 'dart:io';
import 'dart:typed_data';

/// Respuesta real guardada en `test/fixtures/exchange_rates/<name>` (`flutter
/// test` se ejecuta desde app/). Para capturar más:
/// `tool/capture_exchange_rate_fixtures.sh`.
String readRateFixture(String name) =>
    File('test/fixtures/exchange_rates/$name').readAsStringSync();

/// Los mismos bytes sin decodificar: el CSV del Banco de España es latin-1.
Uint8List readRateFixtureBytes(String name) =>
    File('test/fixtures/exchange_rates/$name').readAsBytesSync();
