import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/chart/chart_range.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/metric_value_formatter.dart';

void main() {
  group('formatChartAxisDate', () {
    final date = DateTime.utc(2025, 9, 12);

    test('en periodos de hasta un año muestra día y mes', () {
      expect(formatChartAxisDate(date, ChartRange.month1), '12 sep');
      expect(formatChartAxisDate(date, ChartRange.year1), '12 sep');
    });

    test('en periodos largos muestra mes y año de dos cifras', () {
      expect(formatChartAxisDate(date, ChartRange.years5), 'sep 25');
      expect(formatChartAxisDate(date, ChartRange.all), 'sep 25');
    });

    test('los doce meses tienen su abreviatura', () {
      final months = [
        for (var m = 1; m <= 12; m++)
          formatChartAxisDate(DateTime.utc(2026, m, 1), ChartRange.month1),
      ];
      expect(months, [
        '1 ene',
        '1 feb',
        '1 mar',
        '1 abr',
        '1 may',
        '1 jun',
        '1 jul',
        '1 ago',
        '1 sep',
        '1 oct',
        '1 nov',
        '1 dic',
      ]);
    });

    test('un año anterior al 2010 conserva el cero inicial', () {
      expect(
        formatChartAxisDate(DateTime.utc(2005, 3, 1), ChartRange.all),
        'mar 05',
      );
    });
  });

  group('formatChartAxisPrice', () {
    test('sin decimales por encima de 1.000', () {
      expect(formatChartAxisPrice(14630.4), '14.630');
    });

    test('un decimal entre 10 y 1.000', () {
      expect(formatChartAxisPrice(75.55), '75,5');
    });

    test('dos decimales por debajo de 10', () {
      expect(formatChartAxisPrice(3.6267), '3,63');
    });
  });

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
