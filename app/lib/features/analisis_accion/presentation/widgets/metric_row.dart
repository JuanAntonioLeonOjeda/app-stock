import 'package:flutter/material.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/metric_value_formatter.dart';

/// Una métrica: etiqueta, valor, nota y nota explicativa (criterios 11-12).
class MetricRow extends StatelessWidget {
  const MetricRow({super.key, required this.metric});

  final MetricResult metric;

  @override
  Widget build(BuildContext context) {
    final note = metric.note;
    return ListTile(
      dense: true,
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
