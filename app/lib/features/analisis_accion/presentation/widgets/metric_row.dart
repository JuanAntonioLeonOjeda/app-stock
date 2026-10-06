import 'package:flutter/material.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/metric_value_formatter.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/show_info.dart';

/// Una métrica: etiqueta, valor, nota y nota explicativa (criterios 11-12), y
/// un icono para leer qué mide (criterios 1-2 de `contenido_educativo`).
class MetricRow extends StatelessWidget {
  const MetricRow({super.key, required this.metric, this.showInfo});

  final MetricResult metric;
  final ShowInfo? showInfo;

  @override
  Widget build(BuildContext context) {
    final note = metric.note;
    final showInfo = this.showInfo;
    return ListTile(
      dense: true,
      leading: showInfo == null
          ? null
          : IconButton(
              tooltip: 'Qué es ${metric.label}',
              icon: const Icon(Icons.info_outline),
              onPressed: () => showInfo(context, metric.id),
            ),
      title: Text(metric.label),
      subtitle: Text(
        [formatMetricValue(metric.value, metric.format), ?note].join(' · '),
      ),
      trailing: Text(
        formatScore(metric.score),
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
