import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/exchange_rate_series.dart';

// Jueves 1, viernes 2 y lunes 5 de octubre de 2026 (el fin de semana no hay tipo).
final _thursday = DateTime.utc(2026, 10, 1);
final _friday = DateTime.utc(2026, 10, 2);
final _monday = DateTime.utc(2026, 10, 5);

ExchangeRateSeries _series() => ExchangeRateSeries(
  currency: 'JPY',
  points: [
    RatePoint(_monday, 178),
    RatePoint(_thursday, 176),
    RatePoint(_friday, 177),
  ],
);

void main() {
  group('ExchangeRateSeries', () {
    test('ordena los puntos del más antiguo al más reciente', () {
      final series = _series();

      expect(series.points.map((p) => p.date), [_thursday, _friday, _monday]);
      expect(series.latest?.date, _monday);
    });

    test('el tipo de un día con publicación es el de ese día', () {
      expect(_series().rateOn(_friday), 177);
    });

    test(
      'un sábado o un domingo valen el último tipo publicado (criterio 87)',
      () {
        expect(_series().rateOn(DateTime.utc(2026, 10, 3)), 177);
        expect(_series().rateOn(DateTime.utc(2026, 10, 4)), 177);
      },
    );

    test('un día posterior al último tipo vale el último', () {
      expect(_series().rateOn(DateTime.utc(2026, 10, 20)), 178);
    });

    test('antes del primer tipo no hay tipo, y no se inventa uno', () {
      expect(_series().rateOn(DateTime.utc(2026, 9, 30)), isNull);
      expect(_series().pointOn(DateTime.utc(2000, 1, 1)), isNull);
    });

    test('ignora la hora del día consultado', () {
      expect(_series().rateOn(DateTime.utc(2026, 10, 2, 23, 59)), 177);
      expect(_series().rateOn(DateTime.utc(2026, 10, 1, 0, 0, 1)), 176);
    });

    test('pointOn dice a qué día corresponde el tipo usado', () {
      expect(_series().pointOn(DateTime.utc(2026, 10, 4))?.date, _friday);
    });

    test('una serie vacía no da ningún tipo', () {
      final empty = ExchangeRateSeries(currency: 'JPY', points: const []);

      expect(empty.isEmpty, isTrue);
      expect(empty.latest, isNull);
      expect(empty.rateOn(_friday), isNull);
    });

    test('con muchos puntos encuentra el tipo correcto', () {
      final start = DateTime.utc(2001);
      final series = ExchangeRateSeries(
        currency: 'USD',
        points: [
          for (var i = 0; i < 6000; i++)
            RatePoint(start.add(Duration(days: i)), 1 + i / 10000),
        ],
      );

      expect(series.rateOn(start.add(const Duration(days: 4321))), 1.4321);
    });
  });
}
