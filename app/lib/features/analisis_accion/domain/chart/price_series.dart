// Cálculos puros para dibujar la gráfica de precio. Todo parte de velas
// diarias en orden ascendente y nunca inventa datos: donde no hay suficientes
// sesiones, no hay punto.

import 'package:stock_app/features/analisis_accion/domain/chart/chart_range.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/daily_bar.dart';

/// Un punto de una línea de la gráfica.
class ChartPoint {
  const ChartPoint(this.date, this.value);

  final DateTime date;
  final double value;
}

/// Máximo y mínimo de una serie de puntos.
typedef CloseExtremes = ({ChartPoint high, ChartPoint low});

/// Las velas del periodo [range], contando hacia atrás desde la última. Si el
/// histórico es más corto, devuelve todo lo que hay (criterio 47).
List<DailyBar> sliceRange(List<DailyBar> bars, ChartRange range) {
  final days = range.days;
  if (bars.isEmpty || days == null) return bars;
  final cutoff = bars.last.date.subtract(Duration(days: days));
  return [
    for (final bar in bars)
      if (!bar.date.isBefore(cutoff)) bar,
  ];
}

/// Cierres diarios como puntos.
List<ChartPoint> closePoints(List<DailyBar> bars) => [
  for (final bar in bars) ChartPoint(bar.date, bar.close),
];

/// Media móvil simple de [period] cierres, alineada con [bars]: la posición
/// `i` es `null` mientras no haya [period] sesiones hasta ella (criterio 50).
List<ChartPoint?> movingAverageSeries(List<DailyBar> bars, int period) {
  if (period <= 0) return List.filled(bars.length, null);
  final series = <ChartPoint?>[];
  var windowSum = 0.0;
  for (var i = 0; i < bars.length; i++) {
    windowSum += bars[i].close;
    if (i >= period) windowSum -= bars[i - period].close;
    series.add(
      i >= period - 1 ? ChartPoint(bars[i].date, windowSum / period) : null,
    );
  }
  return series;
}

/// Reduce [points] a unos [maxPoints] sin perder la forma: en cada tramo
/// conserva el máximo y el mínimo, y siempre el primer y el último punto
/// (criterio 51).
List<ChartPoint> downsample(List<ChartPoint> points, {int maxPoints = 500}) {
  if (maxPoints < 4 || points.length <= maxPoints) return points;
  final bucketCount = maxPoints ~/ 2 - 1;
  final keep = <int>{0, points.length - 1};
  for (var bucket = 0; bucket < bucketCount; bucket++) {
    final start = bucket * points.length ~/ bucketCount;
    final end = (bucket + 1) * points.length ~/ bucketCount;
    var low = start;
    var high = start;
    for (var i = start; i < end; i++) {
      // Con empates gana el más reciente, igual que en `closeExtremes`, para
      // que el punto marcado como máximo o mínimo nunca se pierda al agrupar.
      if (points[i].value <= points[low].value) low = i;
      if (points[i].value >= points[high].value) high = i;
    }
    keep
      ..add(low)
      ..add(high);
  }
  final sorted = keep.toList()..sort();
  return [for (final index in sorted) points[index]];
}

/// El máximo y el mínimo de [points], o `null` si está vacía (criterio 48).
/// Si hay empates, gana el más reciente.
CloseExtremes? closeExtremes(List<ChartPoint> points) {
  if (points.isEmpty) return null;
  var high = points.first;
  var low = points.first;
  for (final point in points) {
    if (point.value >= high.value) high = point;
    if (point.value <= low.value) low = point;
  }
  return (high: high, low: low);
}
