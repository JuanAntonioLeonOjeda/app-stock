import 'package:flutter/material.dart';
import 'package:stock_app/features/analisis_accion/domain/chart/chart_range.dart';
import 'package:stock_app/features/analisis_accion/domain/chart/exchange_clock.dart';
import 'package:stock_app/features/analisis_accion/domain/chart/price_series.dart';
import 'package:stock_app/features/analisis_accion/presentation/controllers/price_chart_controller.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/labels.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/metric_value_formatter.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/info_builder.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/price_line_chart.dart';

/// Pie con la fuente y el tipo de ajuste (criterio 52).
const priceChartSourceText =
    'Datos de TradingView. Precios ajustados por splits, sin dividendos.';

/// Texto cuando el histórico no se ha podido cargar (criterio 53).
const priceChartErrorText = 'No se ha podido cargar la gráfica.';

/// La gráfica de precio de la pestaña Resumen: selector de periodo, máximo y
/// mínimo, la línea con las medias opcionales y el pie de fuente.
///
/// Con [buildInfo], la gráfica y cada media tienen un icono que despliega justo
/// debajo su explicación (criterios 68-69 de `contenido_educativo`).
class PriceChartPanel extends StatefulWidget {
  const PriceChartPanel({
    super.key,
    required this.controller,
    required this.currency,
    this.buildInfo,
  });

  final PriceChartController controller;
  final String? currency;
  final InfoBuilder? buildInfo;

  @override
  State<PriceChartPanel> createState() => _PriceChartPanelState();
}

class _PriceChartPanelState extends State<PriceChartPanel> {
  PriceChartController get controller => widget.controller;
  String? get currency => widget.currency;

  /// Explicaciones desplegadas ahora mismo, por id de tema.
  final Set<String> _openInfo = {};

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final view = controller.view;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(context),
          _inlineInfo(priceChartTopicId),
          // Si falla una recarga y ya había datos, se siguen viendo.
          if (view != null && controller.error != null) _errorNotice(),
          _rangeSelector(),
          const SizedBox(height: 8),
          if (view == null)
            _empty()
          else ...[
            _extremes(context, view),
            const SizedBox(height: 8),
            PriceLineChart(
              view: view,
              range: controller.range,
              currency: currency,
            ),
            const SizedBox(height: 4),
            // Las medias son de sesiones diarias: no aplican al día ni a la
            // semana (criterio 63).
            if (!view.isIntraday) _averageSwitches(),
            const SizedBox(height: 8),
            Text(
              view.isIntraday ? _intradayCaption(view) : priceChartSourceText,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      );
    },
  );

  Widget _title(BuildContext context) => Row(
    children: [
      Text(
        'Evolución del precio',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      if (widget.buildInfo != null)
        _infoButton(priceChartTopicId, 'cómo leer la gráfica'),
    ],
  );

  /// Icono que muestra u oculta la explicación del tema [topicId].
  Widget _infoButton(String topicId, String about) {
    final isOpen = _openInfo.contains(topicId);
    return IconButton(
      tooltip: isOpen ? 'Ocultar $about' : 'Qué es $about',
      isSelected: isOpen,
      iconSize: 20,
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.info_outline),
      selectedIcon: const Icon(Icons.info),
      onPressed: () => setState(() {
        if (!_openInfo.remove(topicId)) _openInfo.add(topicId);
      }),
    );
  }

  /// La explicación de [topicId] justo debajo, si está desplegada.
  Widget _inlineInfo(String topicId) {
    final buildInfo = widget.buildInfo;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.topCenter,
      child: buildInfo != null && _openInfo.contains(topicId)
          ? Card(child: buildInfo(context, topicId))
          : const SizedBox(width: double.infinity),
    );
  }

  /// Pie del día y de la semana: qué se ve, en qué hora y con qué retraso
  /// (criterio 64).
  String _intradayCaption(PriceChartView view) {
    final last = view.closes.last.date;
    final wall = displayTime(last, view.timezone);
    final scope = controller.range == ChartRange.day
        ? 'Sesión del ${formatDate(wall)}.'
        : 'Últimas ${view.sessionStarts.length} sesiones.';
    final clock = exchangeWallClock(last, view.timezone) != null
        ? 'Horas de la bolsa.'
        : 'Horas de tu dispositivo.';
    final delay = view.delay;
    final lag = delay == null
        ? ''
        : ' Datos con ${formatDelay(delay)} de retraso.';
    return '$scope $clock$lag Datos de TradingView.';
  }

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
        onPressed: controller.retry,
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
    String describe(String label, ChartPoint point) {
      final when = view.isIntraday
          ? formatMoment(displayTime(point.date, view.timezone))
          : formatDate(point.date);
      return '$label ${formatPrice(point.value, currency)} · $when';
    }

    return Wrap(
      spacing: 16,
      children: [
        Text(describe('Máx', extremes.high), style: style),
        Text(describe('Mín', extremes.low), style: style),
      ],
    );
  }

  Widget _averageSwitches() {
    final hasInfo = widget.buildInfo != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilterChip(
              label: const Text('Media $shortAverageSessions'),
              selected: controller.showShortAverage,
              onSelected: (value) =>
                  controller.setShortAverage(isVisible: value),
            ),
            if (hasInfo)
              _infoButton(
                shortAverageTopicId,
                'la media de $shortAverageSessions sesiones',
              ),
            FilterChip(
              label: const Text('Media $longAverageSessions'),
              selected: controller.showLongAverage,
              onSelected: (value) =>
                  controller.setLongAverage(isVisible: value),
            ),
            if (hasInfo)
              _infoButton(
                longAverageTopicId,
                'la media de $longAverageSessions sesiones',
              ),
          ],
        ),
        _inlineInfo(shortAverageTopicId),
        _inlineInfo(longAverageTopicId),
      ],
    );
  }
}
