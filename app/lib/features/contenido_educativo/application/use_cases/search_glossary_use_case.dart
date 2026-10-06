import 'package:stock_app/features/contenido_educativo/domain/content/glossary_search.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/educational_content.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/glossary_group.dart';

/// Las métricas del glosario que coinciden con una búsqueda, agrupadas por
/// bloque. Los bloques sin coincidencias no aparecen.
class SearchGlossaryUseCase {
  const SearchGlossaryUseCase();

  List<GlossaryGroup> call(EducationalContent content, String query) {
    final groups = <GlossaryGroup>[];
    for (final block in content.blocks) {
      final blockMetrics = [
        for (final id in block.metricIds) ?content.metricById(id),
      ];
      final matches = filterMetrics(blockMetrics, query);
      if (matches.isNotEmpty) {
        groups.add(GlossaryGroup(block: block, metrics: matches));
      }
    }
    return groups;
  }
}
