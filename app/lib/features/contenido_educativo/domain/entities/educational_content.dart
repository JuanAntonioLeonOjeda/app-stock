import 'package:stock_app/features/contenido_educativo/domain/entities/block_content.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/diagnosis_guide.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/metric_content.dart';

/// Id de tema de la guía del diagnóstico.
const guideTopicId = 'guia_diagnostico';

/// Si [topicId] es el de un bloque (`bloque_valoracion`...) y no el de una
/// métrica o un concepto: unos y otros se abren de forma distinta.
bool isBlockTopicId(String topicId) => topicId.startsWith('bloque_');

/// Todo el contenido didáctico de la app.
class EducationalContent {
  EducationalContent({
    required List<MetricContent> metrics,
    required List<MetricContent> concepts,
    required List<BlockContent> blocks,
    required this.guide,
  }) : metrics = List.unmodifiable(metrics),
       concepts = List.unmodifiable(concepts),
       blocks = List.unmodifiable(blocks),
       _metricsById = {for (final metric in metrics) metric.id: metric},
       _conceptsById = {for (final concept in concepts) concept.id: concept},
       _blocksById = {for (final block in blocks) block.id: block};

  /// Métricas del motor en el orden del archivo de contenido.
  final List<MetricContent> metrics;

  /// Conceptos de la gráfica de precio (`media_50`, `media_200`...): tienen la
  /// misma estructura que una métrica pero no son métricas del motor.
  final List<MetricContent> concepts;
  final List<BlockContent> blocks;
  final DiagnosisGuide guide;

  final Map<String, MetricContent> _metricsById;
  final Map<String, MetricContent> _conceptsById;
  final Map<String, BlockContent> _blocksById;

  /// Una métrica del motor; los conceptos no cuentan.
  MetricContent? metricById(String id) => _metricsById[id];

  /// La explicación de una métrica o de un concepto de la gráfica.
  MetricContent? explanationById(String id) =>
      _metricsById[id] ?? _conceptsById[id];

  BlockContent? blockById(String id) => _blocksById[id];
}
