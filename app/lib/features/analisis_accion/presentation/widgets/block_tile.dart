import 'package:flutter/material.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/labels.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/metric_value_formatter.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/info_builder.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/metric_row.dart';

/// Un bloque plegable con su nota y cobertura; al desplegarlo muestra sus
/// métricas (criterios 10-11). Su icono de información despliega el bloque y
/// muestra arriba qué responde y cómo usarlo; al pulsarlo otra vez se oculta
/// (criterio 7 de `contenido_educativo`).
class BlockTile extends StatefulWidget {
  const BlockTile({super.key, required this.block, this.buildInfo});

  final BlockResult block;
  final InfoBuilder? buildInfo;

  @override
  State<BlockTile> createState() => _BlockTileState();
}

class _BlockTileState extends State<BlockTile> {
  final _tileController = ExpansibleController();
  bool _isInfoVisible = false;

  void _toggleInfo() {
    final willShow = !_isInfoVisible;
    setState(() => _isInfoVisible = willShow);
    // Al pedir la explicación, el bloque se despliega para que se vea.
    if (willShow && !_tileController.isExpanded) _tileController.expand();
  }

  @override
  Widget build(BuildContext context) {
    final block = widget.block;
    final buildInfo = widget.buildInfo;
    return Card(
      child: ExpansionTile(
        controller: _tileController,
        leading: buildInfo == null ? null : _infoButton(block),
        title: Text(blockLabel(block.block)),
        subtitle: Text('Cobertura ${formatWholePercent(block.coverage)}'),
        trailing: Text(
          formatScore(block.score),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        children: [
          if (buildInfo != null && _isInfoVisible)
            buildInfo(context, blockTopicId(block.block)),
          for (final metric in block.metrics)
            MetricRow(metric: metric, buildInfo: buildInfo),
        ],
      ),
    );
  }

  Widget _infoButton(BlockResult block) {
    final label = blockLabel(block.block);
    return IconButton(
      tooltip: _isInfoVisible ? 'Ocultar qué mide $label' : 'Qué mide $label',
      isSelected: _isInfoVisible,
      icon: const Icon(Icons.info_outline),
      selectedIcon: const Icon(Icons.info),
      onPressed: _toggleInfo,
    );
  }
}
