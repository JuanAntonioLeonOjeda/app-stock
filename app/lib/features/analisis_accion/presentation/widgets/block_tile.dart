import 'package:flutter/material.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/labels.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/metric_value_formatter.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/metric_row.dart';

/// Un bloque plegable con su nota y cobertura; al desplegarlo muestra sus
/// métricas (criterios 10-11).
class BlockTile extends StatelessWidget {
  const BlockTile({super.key, required this.block});

  final BlockResult block;

  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      title: Text(blockLabel(block.block)),
      subtitle: Text('Cobertura ${formatWholePercent(block.coverage)}'),
      trailing: Text(
        formatScore(block.score),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      children: [for (final metric in block.metrics) MetricRow(metric: metric)],
    ),
  );
}
