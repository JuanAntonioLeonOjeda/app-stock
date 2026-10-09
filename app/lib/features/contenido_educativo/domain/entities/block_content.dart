/// Explicación de uno de los 5 bloques del análisis.
class BlockContent {
  BlockContent({
    required this.id,
    required this.title,
    required this.summary,
    required this.answers,
    required List<String> metricIds,
    required this.howToUse,
  }) : metricIds = List.unmodifiable(metricIds);

  /// Id de tema estable (`bloque_valoracion`...).
  final String id;
  final String title;
  final String summary;

  /// La pregunta que responde el bloque.
  final String answers;

  /// Ids de las métricas del bloque, en el orden en que se muestran.
  final List<String> metricIds;
  final String howToUse;
}
