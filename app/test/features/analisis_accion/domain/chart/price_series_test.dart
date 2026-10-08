import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/chart/chart_range.dart';
import 'package:stock_app/features/analisis_accion/domain/chart/price_series.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/daily_bar.dart';

final _start = DateTime.utc(2026, 1, 1);

/// Velas diarias consecutivas a partir del 1 de enero de 2026.
List<DailyBar> _bars(List<double> closes) => [
  for (var i = 0; i < closes.length; i++)
    DailyBar(
      date: _start.add(Duration(days: i)),
      open: closes[i],
      high: closes[i],
      low: closes[i],
      close: closes[i],
      volume: 1000,
    ),
];

void main() {
  group('sliceRange', () {
    test('todo devuelve el histórico completo', () {
      final bars = _bars(List.filled(400, 10));

      expect(sliceRange(bars, ChartRange.all), hasLength(400));
    });

    test(
      'un periodo cuenta días naturales hacia atrás desde la última vela',
      () {
        final bars = _bars(List.filled(400, 10));

        final slice = sliceRange(bars, ChartRange.month1);

        // 30 días antes de la última, incluida: 31 velas.
        expect(slice, hasLength(31));
        expect(slice.last.date, bars.last.date);
      },
    );

    test('si el histórico es más corto que el periodo, devuelve todo', () {
      final bars = _bars(List.filled(10, 10));

      expect(sliceRange(bars, ChartRange.year1), hasLength(10));
    });

    test('sin velas devuelve una lista vacía', () {
      expect(sliceRange(const [], ChartRange.months3), isEmpty);
    });
  });

  group('movingAverageSeries', () {
    test('es null hasta tener las sesiones necesarias', () {
      final series = movingAverageSeries(_bars([1, 2, 3, 4, 5]), 3);

      expect(series.map((p) => p?.value), [null, null, 2, 3, 4]);
    });

    test('lleva la fecha de la vela que cierra cada ventana', () {
      final bars = _bars([1, 2, 3, 4]);

      final series = movingAverageSeries(bars, 2);

      expect(series[1]?.date, bars[1].date);
      expect(series[3]?.date, bars[3].date);
    });

    test('con menos velas que el periodo no inventa ningún punto', () {
      final series = movingAverageSeries(_bars([1, 2]), 5);

      expect(series.every((p) => p == null), isTrue);
    });

    test('un periodo no positivo no da ningún punto', () {
      expect(
        movingAverageSeries(_bars([1, 2, 3]), 0).every((p) => p == null),
        isTrue,
      );
    });

    test('coincide con la media calculada a mano en una ventana larga', () {
      final closes = [for (var i = 1; i <= 60; i++) i.toDouble()];

      final series = movingAverageSeries(_bars(closes), 50);

      // Media de 11..60 = 35,5.
      expect(series.last?.value, closeTo(35.5, 1e-9));
    });
  });

  group('downsample', () {
    List<ChartPoint> points(int n) => [
      for (var i = 0; i < n; i++)
        ChartPoint(_start.add(Duration(days: i)), (i % 17) * 1.0),
    ];

    test('con pocos puntos no cambia nada', () {
      final input = points(100);

      expect(downsample(input, maxPoints: 500), same(input));
    });

    test('reduce a un tamaño cercano al pedido', () {
      final result = downsample(points(6000), maxPoints: 500);

      expect(result.length, lessThanOrEqualTo(500));
      expect(result.length, greaterThan(100));
    });

    test('conserva el primer y el último punto', () {
      final input = points(6000);

      final result = downsample(input, maxPoints: 500);

      expect(result.first, same(input.first));
      expect(result.last, same(input.last));
    });

    test('conserva el máximo y el mínimo globales', () {
      final input = points(6000)
        ..[2500] = ChartPoint(_start.add(const Duration(days: 2500)), 999)
        ..[4100] = ChartPoint(_start.add(const Duration(days: 4100)), -999);

      final result = downsample(input, maxPoints: 500);

      expect(result.map((p) => p.value), containsAll([999, -999]));
    });

    test('mantiene el orden cronológico', () {
      final result = downsample(points(6000), maxPoints: 500);

      for (var i = 1; i < result.length; i++) {
        expect(result[i].date.isAfter(result[i - 1].date), isTrue);
      }
    });
  });

  group('downsample con empates', () {
    test(
      'el máximo repetido que marca closeExtremes sobrevive al agrupado',
      () {
        // Máximo igual en dos días del mismo tramo: closeExtremes elige el más
        // reciente y el agrupado debe conservar ese mismo punto.
        final points = [
          for (var i = 0; i < 3000; i++)
            ChartPoint(_start.add(Duration(days: i)), 10),
        ];
        points[1000] = ChartPoint(_start.add(const Duration(days: 1000)), 50);
        points[1001] = ChartPoint(_start.add(const Duration(days: 1001)), 50);
        final high = closeExtremes(points)!.high;

        final reduced = downsample(points, maxPoints: 100);

        expect(high.date, _start.add(const Duration(days: 1001)));
        expect(reduced.map((p) => p.date), contains(high.date));
      },
    );

    test('el mínimo repetido también sobrevive', () {
      final points = [
        for (var i = 0; i < 3000; i++)
          ChartPoint(_start.add(Duration(days: i)), 10),
      ];
      points[2000] = ChartPoint(_start.add(const Duration(days: 2000)), 1);
      points[2001] = ChartPoint(_start.add(const Duration(days: 2001)), 1);
      final low = closeExtremes(points)!.low;

      final reduced = downsample(points, maxPoints: 100);

      expect(reduced.map((p) => p.date), contains(low.date));
    });
  });

  group('closeExtremes', () {
    test('devuelve el máximo y el mínimo con su fecha', () {
      final extremes = closeExtremes(closePoints(_bars([5, 9, 2, 7])));

      expect(extremes?.high.value, 9);
      expect(extremes?.high.date, _start.add(const Duration(days: 1)));
      expect(extremes?.low.value, 2);
      expect(extremes?.low.date, _start.add(const Duration(days: 2)));
    });

    test('sin puntos devuelve null', () {
      expect(closeExtremes(const []), isNull);
    });

    test('con empates gana el más reciente', () {
      final extremes = closeExtremes(closePoints(_bars([9, 3, 9])));

      expect(extremes?.high.date, _start.add(const Duration(days: 2)));
    });
  });
}
