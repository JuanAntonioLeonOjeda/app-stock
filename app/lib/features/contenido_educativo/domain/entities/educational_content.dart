import 'package:stock_app/features/contenido_educativo/domain/entities/block_content.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/diagnosis_guide.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/metric_content.dart';

/// Id de tema de la guía del diagnóstico.
const guideTopicId = 'guia_diagnostico';

/// Todo el contenido didáctico de la app.
class EducationalContent {
  EducationalContent({
    required List<MetricContent> metrics,
    required List<BlockContent> blocks,
    required this.guide,
  }) : metrics = List.unmodifiable(metrics),
       blocks = List.unmodifiable(blocks),
       _metricsById = {for (final metric in metrics) metric.id: metric},
       _blocksById = {for (final block in blocks) block.id: block};

  /// Métricas en el orden del archivo de contenido.
  final List<MetricContent> metrics;
  final List<BlockContent> blocks;
  final DiagnosisGuide guide;

  final Map<String, MetricContent> _metricsById;
  final Map<String, BlockContent> _blocksById;

  MetricContent? metricById(String id) => _metricsById[id];

  BlockContent? blockById(String id) => _blocksById[id];
}
