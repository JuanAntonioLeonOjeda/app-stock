import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/currency/euro_conversion.dart';
import 'package:stock_app/features/analisis_accion/domain/currency/quote_currency.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/exchange_rate_series.dart';

final _friday = DateTime.utc(2026, 10, 2);

ExchangeRateSeries _rates(String currency, double unitsPerEuro) =>
    ExchangeRateSeries(
      currency: currency,
      points: [RatePoint(_friday, unitsPerEuro)],
    );

void main() {
  group('toEuros', () {
    test('divide entre el tipo de la moneda por euro', () {
      final euros = toEuros(
        17700,
        currency: const QuoteCurrency('JPY'),
        rates: _rates('JPY', 177),
        day: _friday,
      );

      expect(euros, closeTo(100, 1e-9));
    });

    test('una acción en euros no cambia ni necesita tipos', () {
      expect(
        toEuros(
          42.5,
          currency: const QuoteCurrency('EUR'),
          rates: null,
          day: _friday,
        ),
        42.5,
      );
    });

    test('los peniques se dividen entre 100 antes de aplicar el tipo de la libra (criterio 91)', () {
      // 500,4 GBX = 5,004 GBP; con 0,85 GBP por euro son 5,8870… euros.
      final euros = toEuros(
        500.4,
        currency: resolveQuoteCurrency('GBX')!,
        rates: _rates('GBP', 0.85),
        day: _friday,
      );

      expect(euros, closeTo(5.004 / 0.85, 1e-9));
    });

    test('un sábado usa el tipo del viernes', () {
      final euros = toEuros(
        354,
        currency: const QuoteCurrency('JPY'),
        rates: _rates('JPY', 177),
        day: DateTime.utc(2026, 10, 3),
      );

      expect(euros, closeTo(2, 1e-9));
    });

    test('sin tipo para ese día no se inventa un valor', () {
      expect(
        toEuros(
          100,
          currency: const QuoteCurrency('JPY'),
          rates: _rates('JPY', 177),
          day: DateTime.utc(2026, 9, 1),
        ),
        isNull,
      );
    });

    test('sin serie de tipos devuelve null', () {
      expect(
        toEuros(
          100,
          currency: const QuoteCurrency('JPY'),
          rates: null,
          day: _friday,
        ),
        isNull,
      );
    });

    test('un tipo no positivo no se usa', () {
      expect(
        toEuros(
          100,
          currency: const QuoteCurrency('JPY'),
          rates: _rates('JPY', 0),
          day: _friday,
        ),
        isNull,
      );
    });

    test('un precio de 0 sigue siendo 0 euros', () {
      expect(
        toEuros(
          0,
          currency: const QuoteCurrency('USD'),
          rates: _rates('USD', 1.1),
          day: _friday,
        ),
        0,
      );
    });
  });
}
