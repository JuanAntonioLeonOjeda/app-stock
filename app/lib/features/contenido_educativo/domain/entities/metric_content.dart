import 'package:stock_app/features/contenido_educativo/domain/entities/check_question.dart';

/// Ficha didáctica de una métrica del motor de análisis.
///
/// [id] es el mismo id estable de la métrica (`per`, `roic`...): enlaza el
/// motor, `references/metricas.md` y este contenido.
class MetricContent {
  MetricContent({
    required this.id,
    required this.title,
    required this.summary,
    required this.intuition,
    required this.formula,
    required this.example,
    required this.howToRead,
    required this.whenItMisleads,
    required List<String> combinesWith,
    required this.question,
  }) : combinesWith = List.unmodifiable(combinesWith);

  final String id;
  final String title;

  /// Una frase para la vista compacta.
  final String summary;

  /// Analogía cotidiana.
  final String intuition;

  /// En palabras, indicando de qué estado financiero sale cada dato.
  final String formula;

  /// Cifras redondas inventadas; nunca datos de una empresa real.
  final String example;

  /// Qué valores se consideran altos o bajos, como orientación.
  final String howToRead;

  /// Trampas típicas.
  final String whenItMisleads;

  /// Ids de métricas relacionadas.
  final List<String> combinesWith;
  final CheckQuestion question;
}
