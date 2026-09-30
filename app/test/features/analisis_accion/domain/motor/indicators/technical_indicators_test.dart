import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/indicators/technical_indicators.dart';

List<double> _flat(int length, [double value = 100]) =>
    List.filled(length, value);

List<double> _rising(int length) => [
  for (var i = 1; i <= length; i++) i.toDouble(),
];

void main() {
  group('sma', () {
    test('es la media de los últimos n cierres', () {
      expect(sma([1, 2, 3, 4, 5], 3), 4);
    });

    test('devuelve null si no hay suficientes cierres', () {
      expect(sma([1, 2], 3), isNull);
    });
  });

  group('emaSeries', () {
    test('usa la media simple como semilla y después suaviza con k', () {
      // k = 2/(3+1) = 0,5; semilla = media(1, 2, 3) = 2.
      expect(emaSeries([1, 2, 3, 4, 5], 3), [2, 3, 4]);
    });

    test('devuelve null si no hay suficientes valores', () {
      expect(emaSeries([1, 2], 3), isNull);
    });
  });

  group('rsi', () {
    test('es 100 en una serie solo alcista', () {
      expect(rsi(_rising(30)), 100);
    });

    test('es 50 en una serie plana', () {
      expect(rsi(_flat(30)), 50);
    });

    test('es 50 si las subidas y las bajadas se compensan', () {
      final alternating = [for (var i = 0; i < 15; i++) i.isEven ? 10.0 : 11.0];

      expect(rsi(alternating), closeTo(50, 1e-9));
    });

    test('devuelve null con menos de 15 cierres', () {
      expect(rsi(_rising(14)), isNull);
    });
  });

  group('macd', () {
    test('es cero en una serie plana', () {
      final result = macd(_flat(40));

      expect(result, isNotNull);
      expect(result!.line, closeTo(0, 1e-9));
      expect(result.histogram, closeTo(0, 1e-9));
    });

    test('tras una subida brusca el histograma es positivo y creciente', () {
      final result = macd([..._flat(40), 110]);

      expect(result!.histogram, greaterThan(0));
      expect(result.histogram, greaterThan(result.previousHistogram));
    });

    test('devuelve null con menos de 35 cierres', () {
      expect(macd(_flat(34)), isNull);
    });
  });

  group('smaSlope', () {
    test('es cero en una serie plana', () {
      expect(smaSlope(_flat(220)), 0);
    });

    test('compara la media actual con la de hace 20 sesiones', () {
      // Media de 21..220 = 120,5; media de 1..200 = 100,5.
      expect(smaSlope(_rising(220)), closeTo(120.5 / 100.5 - 1, 1e-12));
    });

    test('devuelve null con menos de 220 cierres', () {
      expect(smaSlope(_flat(219)), isNull);
    });
  });

  group('maxDrawdown', () {
    test('es la mayor caída desde un máximo previo', () {
      final closes = <double>[..._flat(248), 120, 90, 110, 100];

      expect(maxDrawdown(closes), closeTo(-0.25, 1e-12));
    });

    test('es cero si el precio nunca cae', () {
      expect(maxDrawdown(_rising(252)), 0);
    });

    test('devuelve null con menos de un año de sesiones', () {
      expect(maxDrawdown(_flat(251)), isNull);
    });
  });

  group('maxOfLast', () {
    test('es el máximo de la ventana', () {
      expect(maxOfLast([500, ..._flat(251), 130]), 130);
    });

    test('devuelve null si la ventana no está completa', () {
      expect(maxOfLast(_flat(251)), isNull);
    });
  });
}
