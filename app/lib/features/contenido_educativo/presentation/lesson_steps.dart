import 'package:stock_app/features/contenido_educativo/domain/entities/check_question.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/learning_activity.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/metric_content.dart';

/// Una tarjeta del recorrido de una ficha (criterio 72): una sola idea.
sealed class LessonStep {
  const LessonStep();

  /// Título corto, para el indicador de pasos.
  String get label;
}

/// La analogía cotidiana con su ilustración.
class IdeaStep extends LessonStep {
  const IdeaStep();

  @override
  String get label => 'La idea';
}

/// La fórmula por piezas y el ejemplo inventado.
class CalculationStep extends LessonStep {
  const CalculationStep();

  @override
  String get label => 'Cómo se calcula';
}

/// La barra de tramos o la leyenda, y el texto de cómo leerla.
class ReadingStep extends LessonStep {
  const ReadingStep();

  @override
  String get label => 'Cómo leerla';
}

/// Una trampa típica; hay una tarjeta por cada una.
class PitfallStep extends LessonStep {
  const PitfallStep({required this.text, required this.number});

  final String text;

  /// Posición entre las trampas de la ficha, empezando en 1.
  final int number;

  @override
  String get label => 'Cuándo engaña';
}

/// Una actividad interactiva distinta del test.
class ActivityStep extends LessonStep {
  const ActivityStep({required this.activity});

  final LearningActivity activity;

  @override
  String get label => 'Practica';
}

/// La pregunta de comprobación, con las métricas relacionadas debajo.
class QuestionStep extends LessonStep {
  const QuestionStep({required this.question});

  final CheckQuestion question;

  @override
  String get label => 'Comprueba';
}

/// Los pasos de [metric] en orden: idea → cálculo → lectura → trampas →
/// actividades → pregunta.
List<LessonStep> lessonStepsFor(MetricContent metric) => [
  const IdeaStep(),
  const CalculationStep(),
  const ReadingStep(),
  for (var i = 0; i < metric.whenItMisleads.length; i++)
    PitfallStep(text: metric.whenItMisleads[i], number: i + 1),
  for (final activity in metric.activities) ActivityStep(activity: activity),
  QuestionStep(question: metric.question),
];
