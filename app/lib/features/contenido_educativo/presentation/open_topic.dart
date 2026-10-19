import 'package:flutter/material.dart';
import 'package:stock_app/features/contenido_educativo/application/use_cases/get_metric_scale_use_case.dart';
import 'package:stock_app/features/contenido_educativo/application/use_cases/load_educational_content_use_case.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/educational_content.dart';
import 'package:stock_app/features/contenido_educativo/presentation/controllers/lesson_controller.dart';
import 'package:stock_app/features/contenido_educativo/presentation/controllers/topic_controller.dart';
import 'package:stock_app/features/contenido_educativo/presentation/screens/diagnosis_guide_screen.dart';
import 'package:stock_app/features/contenido_educativo/presentation/screens/metric_lesson_screen.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/topic_sheet.dart';

/// Abre la explicación de [topicId]: la guía y las métricas (con sus
/// conceptos) a pantalla completa, y un bloque en una hoja inferior, para
/// seguir viendo el resultado debajo.
void openEducationalTopic(
  BuildContext context, {
  required LoadEducationalContentUseCase loadContent,
  required GetMetricScaleUseCase getMetricScale,
  required String topicId,
}) {
  if (topicId == guideTopicId) {
    // El controller se crea fuera del builder: la ruta puede reconstruirlo.
    final controller = TopicController(
      loadContent: loadContent,
      initialTopicId: topicId,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DiagnosisGuideScreen(controller: controller),
      ),
    );
    return;
  }
  if (isBlockTopicId(topicId)) {
    showTopicSheet(
      context,
      loadContent: loadContent,
      topicId: topicId,
      onOpenTopic: (metricId) => openEducationalTopic(
        context,
        loadContent: loadContent,
        getMetricScale: getMetricScale,
        topicId: metricId,
      ),
    );
    return;
  }
  final controller = LessonController(
    loadContent: loadContent,
    initialTopicId: topicId,
    getMetricScale: getMetricScale,
  );
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => MetricLessonScreen(controller: controller),
    ),
  );
}
