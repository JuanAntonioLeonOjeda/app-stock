import 'package:stock_app/features/contenido_educativo/domain/entities/check_question.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/formula_diagram.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/learning_activity.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/reading_scale.dart';

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
    required List<String> whenItMisleads,
    required List<String> combinesWith,
    required this.question,
    this.formulaDiagram,
    this.legend = const [],
    List<LearningActivity> activities = const [],
  }) : whenItMisleads = List.unmodifiable(whenItMisleads),
       combinesWith = List.unmodifiable(combinesWith),
       activities = List.unmodifiable(activities);

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

  /// Trampas típicas, una por tarjeta.
  final List<String> whenItMisleads;

  /// Ids de métricas relacionadas.
  final List<String> combinesWith;
  final CheckQuestion question;

  /// La fórmula por piezas (criterio 76); `null` mientras la ficha no se ha
  /// migrado al formato visual.
  final FormulaDiagram? formulaDiagram;

  /// Cómo leer el valor cuando el motor no tiene una escala por tramos
  /// (criterio 79); vacía en las demás.
  final List<LegendRow> legend;
  final List<LearningActivity> activities;
}
