import 'package:flutter/material.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/labels.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/metric_guidance.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/metric_value_formatter.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/guidance_tags.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/show_info.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/verdict_badge.dart';

/// "Lo esencial": las pocas métricas que un principiante debería mirar
/// primero, con un semáforo y la pregunta que responde cada una (criterios
/// 98-105). Explica, no recomienda.
class EssentialsCard extends StatelessWidget {
  const EssentialsCard({super.key, required this.result, this.showInfo});

  final AnalysisResult result;

  /// Abre la explicación de una métrica; sin ella las filas no se pulsan.
  final ShowInfo? showInfo;

  /// Las esenciales que tiene el resultado, en el orden de las preguntas.
  List<(EssentialMetric, MetricResult)> _rows() {
    final byId = {
      for (final block in result.blocks)
        for (final metric in block.metrics) metric.id: metric,
    };
    return [
      for (final essential in essentialMetrics)
        if (byId[essential.id] case final metric?) (essential, metric),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows();
    if (rows.isEmpty) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Lo esencial', style: text.titleMedium),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
              child: Text(
                'Empieza por estas seis preguntas; toca una para ver qué mide. El '
                'color orienta sobre cada dato; no es una recomendación de '
                'compra ni de venta. '
                '"$tradeRepublicTagText" marca lo que también ves en esa app.',
                style: text.bodySmall,
              ),
            ),
            for (final (essential, metric) in rows)
              _row(context, essential, metric),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    EssentialMetric essential,
    MetricResult metric,
  ) {
    final signal = signalForScore(metric.score);
    final color = verdictColor(signal, Theme.of(context).colorScheme);
    final open = showInfo;
    return ListTile(
      dense: true,
      onTap: open == null ? null : () => open(context, metric.id),
      leading: Semantics(
        label: 'Semáforo: ${signalLabel(signal)}',
        excludeSemantics: true,
        child: Icon(Icons.circle, color: color),
      ),
      title: Text(essential.question),
      subtitle: Wrap(
        spacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            signalLabel(signal),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            [
              '${metric.label}: '
                  '${formatMetricValue(metric.value, metric.format)}',
              if (metric.score == null) ?metric.note,
            ].join(' · '),
          ),
          if (isInTradeRepublic(metric.id))
            const GuidanceTag(text: tradeRepublicTagText),
        ],
      ),
      trailing: open == null ? null : const Icon(Icons.info_outline),
    );
  }
}
