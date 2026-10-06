import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/metric_value_formatter.dart';

void main() {
  group('formatMetricValue', () {
    test('una fracción se muestra como porcentaje con un decimal', () {
      expect(formatMetricValue(0.025, MetricFormat.percent), '2,5 %');
      expect(formatMetricValue(-0.143, MetricFormat.percent), '-14,3 %');
    });

    test('un múltiplo lleva "x"', () {
      expect(formatMetricValue(15.66, MetricFormat.multiple), '15,7x');
    });

    test('un decimal lleva dos decimales', () {
      expect(formatMetricValue(0.708, MetricFormat.decimal), '0,71');
    });

    test('un recuento es un entero', () {
      expect(formatMetricValue(3, MetricFormat.count), '3');
    });

    test('sin valor muestra "sin dato", nunca 0', () {
      for (final format in MetricFormat.values) {
        expect(formatMetricValue(null, format), noDataText, reason: '$format');
      }
    });
  });

  group('formatScore', () {
    test('una nota lleva un decimal', () {
      expect(formatScore(8.3), '8,3');
      expect(formatScore(10), '10,0');
    });

    test('sin nota muestra un guion', () {
      expect(formatScore(null), '–');
    });
  });

  group('otros formatos', () {
    test('la cobertura es un porcentaje sin decimales', () {
      expect(formatWholePercent(0.8), '80 %');
    });

    test('el precio lleva dos decimales y la divisa', () {
      expect(formatPrice(219.99, 'USD'), '219,99 USD');
      expect(formatPrice(219.99, null), '219,99');
      expect(formatPrice(null, 'USD'), noDataText);
    });

    test('la fecha es dd/mm/aaaa', () {
      expect(formatDate(DateTime(2026, 9, 3)), '03/09/2026');
    });
  });

  group('formatAge', () {
    test('en minutos, horas o días, con singular y plural', () {
      expect(formatAge(const Duration(seconds: 20)), 'hace 1 minuto');
      expect(formatAge(const Duration(minutes: 5)), 'hace 5 minutos');
      expect(formatAge(const Duration(hours: 1, minutes: 30)), 'hace 1 hora');
      expect(formatAge(const Duration(hours: 7)), 'hace 7 horas');
      expect(formatAge(const Duration(days: 3, hours: 2)), 'hace 3 días');
    });
  });
}
