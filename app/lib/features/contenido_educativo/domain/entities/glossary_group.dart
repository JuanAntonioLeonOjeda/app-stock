import 'package:stock_app/features/contenido_educativo/domain/entities/block_content.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/metric_content.dart';

/// Las métricas de un bloque que coinciden con una búsqueda del glosario.
class GlossaryGroup {
  GlossaryGroup({required this.block, required List<MetricContent> metrics})
    : metrics = List.unmodifiable(metrics);

  final BlockContent block;
  final List<MetricContent> metrics;
}
