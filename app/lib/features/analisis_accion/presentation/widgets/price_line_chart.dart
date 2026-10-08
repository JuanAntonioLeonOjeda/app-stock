import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:stock_app/features/analisis_accion/domain/chart/chart_range.dart';
import 'package:stock_app/features/analisis_accion/domain/chart/exchange_clock.dart';
import 'package:stock_app/features/analisis_accion/domain/chart/price_series.dart';
import 'package:stock_app/features/analisis_accion/presentation/controllers/price_chart_controller.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/metric_value_formatter.dart';

/// Alto de la gráfica.
const priceChartHeight = 260.0;

/// Etiquetas que se ven en el eje horizontal, como máximo.
const _axisLabels = 4;

/// Etiquetas de hora que caben en el eje del día; con más, se salta alguna.
const _maxClockLabels = 6;

/// Líneas de la gráfica, en el orden de `lineBarsData`.
enum _Line { close, shortAverage, longAverage }

/// La hora que se muestra para un instante en UTC: la de la bolsa si su zona
/// horaria es conocida y, si no, la del dispositivo (criterio 64).
DateTime displayTime(DateTime utc, String? timezone) =>
    exchangeWallClock(utc, timezone) ?? utc.toLocal();

/// Línea de cierres con las medias opcionales, el máximo y el mínimo marcados y
/// la fecha y el precio al tocar (criterios 46-51 y 59-62).
///
/// En el día y la semana el eje horizontal es el orden de las velas y no el
/// tiempo, para que las sesiones queden pegadas sin huecos de noche ni de fin de
/// semana.
class PriceLineChart extends StatelessWidget {
  const PriceLineChart({
    super.key,
    required this.view,
    required this.range,
    required this.currency,
  });

  final PriceChartView view;
  final ChartRange range;
  final String? currency;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final lines = _lines(colors);
    final closes = view.closes;
    if (closes.isEmpty) return const SizedBox(height: priceChartHeight);
    final minX = _x(0, closes.first);
    final maxX = _x(closes.length - 1, closes.last);
    final values = [
      for (final line in lines)
        for (final spot in line.spots) spot.y,
    ];
    final low = values.reduce((a, b) => a < b ? a : b);
    final high = values.reduce((a, b) => a > b ? a : b);
    // Con una serie plana el rango sería cero: se deja un margen mínimo.
    final padding = high > low ? (high - low) * 0.08 : high.abs() * 0.05 + 1;
    return SizedBox(
      height: priceChartHeight,
      child: LineChart(
        LineChartData(
          minX: minX,
          maxX: maxX == minX ? minX + 1 : maxX,
          minY: low - padding,
          maxY: high + padding,
          lineBarsData: lines,
          gridData: const FlGridData(drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: _titles(context, minX, maxX),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touched) => [
                for (final spot in touched) _tooltip(spot),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Posición horizontal de un punto: el orden en el día y la semana y el
  /// instante en los periodos largos.
  double _x(int index, ChartPoint point) => view.isIntraday
      ? index.toDouble()
      : point.date.millisecondsSinceEpoch.toDouble();

  List<LineChartBarData> _lines(ColorScheme colors) {
    final extremes = view.extremes;
    return [
      _line(
        view.closes,
        colors.primary,
        width: 2,
        markers: [?extremes?.high, ?extremes?.low],
        fill: true,
        markerStroke: colors.surface,
      ),
      if (view.shortAverage.isNotEmpty)
        _line(view.shortAverage, colors.tertiary, width: 1.5),
      if (view.longAverage.isNotEmpty)
        _line(view.longAverage, colors.error, width: 1.5),
    ];
  }

  LineChartBarData _line(
    List<ChartPoint> points,
    Color color, {
    required double width,
    List<ChartPoint> markers = const [],
    bool fill = false,
    Color markerStroke = Colors.white,
  }) {
    final markedDates = {for (final marker in markers) marker.date};
    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(_x(i, points[i]), points[i].value),
    ];
    final markedX = {
      for (var i = 0; i < points.length; i++)
        if (markedDates.contains(points[i].date)) spots[i].x,
    };
    return LineChartBarData(
      spots: spots,
      color: color,
      barWidth: width,
      dotData: FlDotData(
        checkToShowDot: (spot, _) => markedX.contains(spot.x),
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: 5,
          color: color,
          strokeWidth: 2,
          strokeColor: markerStroke,
        ),
      ),
      belowBarData: BarAreaData(
        show: fill,
        color: color.withValues(alpha: 0.08),
      ),
    );
  }

  FlTitlesData _titles(BuildContext context, double minX, double maxX) {
    final style = Theme.of(context).textTheme.bodySmall;
    return FlTitlesData(
      topTitles: const AxisTitles(),
      leftTitles: const AxisTitles(),
      rightTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 52,
          getTitlesWidget: (value, meta) => SideTitleWidget(
            meta: meta,
            child: Text(formatChartAxisPrice(value), style: style),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: view.isIntraday
            ? _intradayBottomTitles(style)
            : _dailyBottomTitles(style, minX, maxX),
      ),
    );
  }

  SideTitles _dailyBottomTitles(TextStyle? style, double minX, double maxX) {
    final interval = maxX > minX ? (maxX - minX) / _axisLabels : 1.0;
    return SideTitles(
      showTitles: true,
      reservedSize: 28,
      interval: interval,
      getTitlesWidget: (value, meta) {
        // Sin etiquetas en los extremos del rango para que no se pisen.
        if (value == meta.min || value == meta.max) {
          return const SizedBox.shrink();
        }
        final date = DateTime.fromMillisecondsSinceEpoch(
          value.round(),
          isUtc: true,
        );
        return SideTitleWidget(
          meta: meta,
          child: Text(formatChartAxisDate(date, range), style: style),
        );
      },
    );
  }

  /// Etiquetas del día (horas en punto) o de la semana (el día de cada
  /// sesión), en la hora de la bolsa.
  SideTitles _intradayBottomTitles(TextStyle? style) {
    final labels = _intradayLabels();
    return SideTitles(
      showTitles: true,
      reservedSize: 28,
      interval: 1,
      getTitlesWidget: (value, meta) {
        final label = labels[value.round()];
        if (label == null) return const SizedBox.shrink();
        return SideTitleWidget(
          meta: meta,
          child: Text(label, style: style),
        );
      },
    );
  }

  /// Texto del eje por posición de vela; las que no tienen etiqueta no están.
  Map<int, String> _intradayLabels() {
    final wall = [
      for (final point in view.closes) displayTime(point.date, view.timezone),
    ];
    if (range == ChartRange.week) {
      return {
        for (final start in view.sessionStarts)
          start: formatWeekdayAndDay(wall[start]),
      };
    }
    final hours = [
      for (var i = 0; i < wall.length; i++)
        if (wall[i].minute == 0) i,
    ];
    // Si no caben, se saltan horas alternas.
    final step = (hours.length / _maxClockLabels).ceil().clamp(1, 24);
    return {
      for (var i = 0; i < hours.length; i += step)
        hours[i]: formatClock(wall[hours[i]]),
    };
  }

  LineTooltipItem _tooltip(LineBarSpot spot) {
    final kind = _lineKind(spot.barIndex);
    final label = switch (kind) {
      _Line.close => _closeLabel(spot.x),
      _Line.shortAverage => 'Media $shortAverageSessions',
      _Line.longAverage => 'Media $longAverageSessions',
    };
    return LineTooltipItem(
      '$label\n${formatPrice(spot.y, currency)}',
      TextStyle(
        color: Colors.white,
        fontWeight: kind == _Line.close ? FontWeight.bold : null,
      ),
    );
  }

  /// Fecha (periodos largos) o día y hora de la bolsa (día y semana) del punto
  /// tocado.
  String _closeLabel(double x) {
    if (!view.isIntraday) {
      return formatDate(
        DateTime.fromMillisecondsSinceEpoch(x.round(), isUtc: true),
      );
    }
    final index = x.round().clamp(0, view.closes.length - 1);
    return formatMoment(displayTime(view.closes[index].date, view.timezone));
  }

  /// Qué línea es la de la posición [index] de `lineBarsData` (las medias solo
  /// existen si tienen datos).
  _Line _lineKind(int index) {
    final kinds = [
      _Line.close,
      if (view.shortAverage.isNotEmpty) _Line.shortAverage,
      if (view.longAverage.isNotEmpty) _Line.longAverage,
    ];
    return kinds[index.clamp(0, kinds.length - 1)];
  }
}
