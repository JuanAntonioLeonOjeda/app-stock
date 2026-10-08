import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/ecb_rate_parser.dart';

import '../../../../fixtures/exchange_rates_fixtures.dart';

Matcher _invalid(String fragment) => throwsA(
  isA<InvalidResponseException>().having(
    (e) => e.details,
    'details',
    contains(fragment),
  ),
);

void main() {
  group('parseEcbRates', () {
    test('convierte la respuesta real del yen en tipos por día', () {
      final series = parseEcbRates(readRateFixture('ecb_jpy.json'), 'JPY');

      expect(series.currency, 'JPY');
      expect(series.points, hasLength(14));
      expect(series.points.first.date, DateTime.utc(2026, 9, 21));
      expect(series.points.first.unitsPerEuro, 180.7);
    });

    test('los puntos van ascendentes y en UTC, sin hora', () {
      final series = parseEcbRates(readRateFixture('ecb_jpy.json'), 'JPY');

      for (var i = 1; i < series.points.length; i++) {
        expect(
          series.points[i].date.isAfter(series.points[i - 1].date),
          isTrue,
        );
      }
      expect(series.points.every((p) => p.date.isUtc), isTrue);
      expect(series.points.every((p) => p.date.hour == 0), isTrue);
    });

    test(
      'el BCE no publica en fin de semana: no hay puntos en sábado ni domingo',
      () {
        final series = parseEcbRates(readRateFixture('ecb_jpy.json'), 'JPY');

        expect(
          series.points.any(
            (p) =>
                p.date.weekday == DateTime.saturday ||
                p.date.weekday == DateTime.sunday,
          ),
          isFalse,
        );
      },
    );

    test('usa el índice de cada observación para su fecha', () {
      const body = '''
{"dataSets":[{"series":{"0:0:0:0:0":{"observations":{"1":[2.5],"0":[2.0]}}}}],
 "structure":{"dimensions":{"observation":[{"values":[{"id":"2026-01-05"},{"id":"2026-01-06"}]}]}}}''';

      final series = parseEcbRates(body, 'USD');

      expect(series.points.map((p) => p.date), [
        DateTime.utc(2026, 1, 5),
        DateTime.utc(2026, 1, 6),
      ]);
      expect(series.points.map((p) => p.unitsPerEuro), [2.0, 2.5]);
    });

    test('ignora las observaciones sin número, con tipo no positivo o fuera de índice', () {
      const body = '''
{"dataSets":[{"series":{"0:0:0:0:0":{"observations":{"0":[1.1],"1":[null],"2":[0],"3":[-4],"9":[7.7],"x":[8.8]}}}}],
 "structure":{"dimensions":{"observation":[{"values":[{"id":"2026-01-05"},{"id":"2026-01-06"},{"id":"2026-01-07"},{"id":"2026-01-08"}]}]}}}''';

      final series = parseEcbRates(body, 'USD');

      expect(series.points, hasLength(1));
      expect(series.points.single.unitsPerEuro, 1.1);
    });

    test('una serie vacía es NotFound', () {
      const body = '''
{"dataSets":[{"series":{}}],
 "structure":{"dimensions":{"observation":[{"values":[]}]}}}''';

      expect(
        () => parseEcbRates(body, 'USD'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('un cuerpo que no es JSON es inválido', () {
      expect(
        () => parseEcbRates('<html>mantenimiento</html>', 'JPY'),
        _invalid('JSON'),
      );
    });

    test('sin fechas en la estructura es inválido', () {
      expect(
        () => parseEcbRates('{"dataSets":[{"series":{}}]}', 'JPY'),
        _invalid('fechas'),
      );
    });

    test('con una fecha ilegible es inválido', () {
      const body = '''
{"dataSets":[{"series":{"0":{"observations":{"0":[1.0]}}}}],
 "structure":{"dimensions":{"observation":[{"values":[{"id":"ayer"}]}]}}}''';

      expect(() => parseEcbRates(body, 'USD'), _invalid('fecha'));
    });

    test('sin observaciones en la serie es inválido', () {
      const body = '''
{"dataSets":[{"series":{"0":{"x":1}}}],
 "structure":{"dimensions":{"observation":[{"values":[{"id":"2026-01-05"}]}]}}}''';

      expect(() => parseEcbRates(body, 'USD'), _invalid('observaciones'));
    });

    test('sin series en el conjunto de datos es inválido', () {
      const body = '''
{"dataSets":[{}],
 "structure":{"dimensions":{"observation":[{"values":[{"id":"2026-01-05"}]}]}}}''';

      expect(() => parseEcbRates(body, 'USD'), _invalid('series'));
    });
  });
}
