import 'package:flutter/material.dart';
import 'package:stock_app/features/contenido_educativo/application/use_cases/load_educational_content_use_case.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/educational_content.dart';
import 'package:stock_app/features/contenido_educativo/presentation/controllers/topic_controller.dart';
import 'package:stock_app/features/contenido_educativo/presentation/screens/diagnosis_guide_screen.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/topic_sheet.dart';

/// Abre la explicación de [topicId]: la guía a pantalla completa (tiene
/// varias secciones) y cualquier otro tema, una métrica o un bloque, en una
/// hoja inferior, para seguir viendo el resultado debajo.
void openEducationalTopic(
  BuildContext context, {
  required LoadEducationalContentUseCase loadContent,
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
  showTopicSheet(context, loadContent: loadContent, topicId: topicId);
}
