import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/bde_rate_parser.dart';

import '../../../../fixtures/exchange_rates_fixtures.dart';

String _csv() => latin1.decode(readRateFixtureBytes('bde_tc_1_1.csv'));

void main() {
  group('parseBdeRates', () {
    test('lee la columna del yen del CSV real', () {
      final series = parseBdeRates(_csv(), 'JPY');

      expect(series.currency, 'JPY');
      expect(series.points.first.date, DateTime.utc(1999, 1, 4));
      expect(series.points.first.unitsPerEuro, 133.73);
      expect(series.latest?.date, DateTime.utc(2026, 10, 7));
      expect(series.latest?.unitsPerEuro, 176.85);
    });

    test('lee otra columna sin mezclar monedas', () {
      final usd = parseBdeRates(_csv(), 'USD');
      final gbp = parseBdeRates(_csv(), 'GBP');

      expect(usd.points.first.unitsPerEuro, 1.1789);
      expect(gbp.points.first.unitsPerEuro, 0.7111);
    });

    test('entiende las fechas en español: ENE y OCT', () {
      final series = parseBdeRates(_csv(), 'USD');

      expect(series.points.map((p) => p.date.month), contains(1));
      expect(series.points.map((p) => p.date.month), contains(10));
    });

    test('no confunde las líneas de fuente y notas con datos', () {
      final series = parseBdeRates(_csv(), 'JPY');

      // 3 filas del principio y 10 del final.
      expect(series.points, hasLength(13));
    });

    test('una moneda con todo huecos ("_") es NotFound', () {
      // El lev búlgaro desaparece al entrar Bulgaria en el euro y la columna
      // solo trae "_" en estas filas.
      expect(
        () => parseBdeRates(_csv(), 'BGN'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('una moneda que el Banco de España no publica es NotFound', () {
      expect(
        () => parseBdeRates(_csv(), 'TWD'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('salta los días con hueco y conserva el resto', () {
      const csv = '''
"CÓDIGO DE LA SERIE",DTCCBCEUSDEUR.B,DTCCBCEJPYEUR.B,
"NÚMERO SECUENCIAL",1,2,
"04 ENE 1999",1.1789,"_",
"05 ENE 1999",1.1790,130.9600,
"06 ENE 1999",1.1743,,
"07 ENE 1999",1.1700,131.0000,''';

      final series = parseBdeRates(csv, 'JPY');

      expect(series.points.map((p) => p.date.day), [5, 7]);
    });

    test('acepta saltos de línea de Windows y de Unix', () {
      const crlf =
          '"CÓDIGO DE LA SERIE",DTCCBCEUSDEUR.B,\r\n"04 ENE 1999",1.1,\r\n';
      const lf = '"CÓDIGO DE LA SERIE",DTCCBCEUSDEUR.B,\n"04 ENE 1999",1.1,\n';

      expect(parseBdeRates(crlf, 'USD').points, hasLength(1));
      expect(parseBdeRates(lf, 'USD').points, hasLength(1));
    });

    test('un mes desconocido es respuesta inválida', () {
      const csv = '"CÓDIGO DE LA SERIE",DTCCBCEUSDEUR.B,\n"04 XXX 1999",1.1,\n';

      expect(
        () => parseBdeRates(csv, 'USD'),
        throwsA(isA<InvalidResponseException>()),
      );
    });

    test('si la primera línea ya no es la esperada, es respuesta inválida', () {
      expect(
        () => parseBdeRates('<html>cambiado</html>', 'USD'),
        throwsA(isA<InvalidResponseException>()),
      );
      expect(
        () => parseBdeRates('', 'USD'),
        throwsA(isA<InvalidResponseException>()),
      );
    });
  });
}
