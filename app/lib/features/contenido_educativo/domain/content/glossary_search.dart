import 'package:stock_app/features/contenido_educativo/domain/entities/metric_content.dart';

const _accents = {
  'á': 'a',
  'é': 'e',
  'í': 'i',
  'ó': 'o',
  'ú': 'u',
  'ü': 'u',
  'ñ': 'n',
};

/// Minúsculas y sin tildes, para comparar textos al buscar.
String normalizeForSearch(String text) {
  final lower = text.toLowerCase();
  return [for (final char in lower.split('')) _accents[char] ?? char].join();
}

/// Las métricas cuyo título o resumen contienen [query], sin mayúsculas ni
/// tildes. Un texto vacío las devuelve todas.
List<MetricContent> filterMetrics(List<MetricContent> metrics, String query) {
  final needle = normalizeForSearch(query.trim());
  if (needle.isEmpty) return metrics;
  return [
    for (final metric in metrics)
      if (normalizeForSearch('${metric.title} ${metric.summary}')
          .contains(needle))
        metric,
  ];
}
