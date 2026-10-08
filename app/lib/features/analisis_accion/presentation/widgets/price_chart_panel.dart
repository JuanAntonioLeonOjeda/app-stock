import 'package:flutter/material.dart';
import 'package:stock_app/features/analisis_accion/domain/chart/chart_range.dart';
import 'package:stock_app/features/analisis_accion/domain/chart/price_series.dart';
import 'package:stock_app/features/analisis_accion/presentation/controllers/price_chart_controller.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/labels.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/metric_value_formatter.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/price_line_chart.dart';

/// Pie con la fuente y el tipo de ajuste (criterio 52).
const priceChartSourceText =
    'Datos de TradingView. Precios ajustados por splits, sin dividendos.';

/// Texto cuando el histórico no se ha podido cargar (criterio 53).
const priceChartErrorText = 'No se ha podido cargar la gráfica.';

/// La gráfica de precio de la pestaña Resumen: selector de periodo, máximo y
/// mínimo, la línea con las medias opcionales y el pie de fuente.
class PriceChartPanel extends StatelessWidget {
  const PriceChartPanel({
    super.key,
    required this.controller,
    required this.currency,
  });

  final PriceChartController controller;
  final String? currency;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final view = controller.view;
      if (view == null) return _empty();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.error != null) _errorNotice(),
          _rangeSelector(),
          const SizedBox(height: 8),
          _extremes(context, view),
          const SizedBox(height: 8),
          PriceLineChart(
            view: view,
            range: controller.range,
            currency: currency,
          ),
          const SizedBox(height: 4),
          _averageSwitches(),
          const SizedBox(height: 8),
          Text(
            priceChartSourceText,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    },
  );

  Widget _empty() {
    if (controller.error != null) return _errorNotice();
    return const SizedBox(
      height: priceChartHeight,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _errorNotice() => Card(
    child: ListTile(
      leading: const Icon(Icons.show_chart),
      title: const Text(priceChartErrorText),
      trailing: TextButton(
        onPressed: controller.load,
        child: const Text('Reintentar'),
      ),
    ),
  );

  Widget _rangeSelector() => Wrap(
    spacing: 8,
    children: [
      for (final range in ChartRange.values)
        ChoiceChip(
          label: Text(chartRangeLabel(range)),
          selected: controller.range == range,
          onSelected: (_) => controller.selectRange(range),
        ),
    ],
  );

  /// Máximo y mínimo de cierre del periodo, con su valor y su fecha
  /// (criterio 48).
  Widget _extremes(BuildContext context, PriceChartView view) {
    final extremes = view.extremes;
    if (extremes == null) return const SizedBox.shrink();
    final style = Theme.of(context).textTheme.bodyMedium;
    String describe(String label, ChartPoint point) =>
        '$label ${formatPrice(point.value, currency)} · '
        '${formatDate(point.date)}';
    return Wrap(
      spacing: 16,
      children: [
        Text(describe('Máx', extremes.high), style: style),
        Text(describe('Mín', extremes.low), style: style),
      ],
    );
  }

  Widget _averageSwitches() => Wrap(
    spacing: 8,
    children: [
      FilterChip(
        label: const Text('Media $shortAverageSessions'),
        selected: controller.showShortAverage,
        onSelected: (value) => controller.setShortAverage(isVisible: value),
      ),
      FilterChip(
        label: const Text('Media $longAverageSessions'),
        selected: controller.showLongAverage,
        onSelected: (value) => controller.setLongAverage(isVisible: value),
      ),
    ],
  );
}
