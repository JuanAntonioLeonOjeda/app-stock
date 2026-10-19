import 'package:flutter/material.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/formula_diagram.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/learning_activity.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/reading_scale.dart';
import 'package:stock_app/features/contenido_educativo/presentation/controllers/lesson_controller.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/activities/compare_activity_view.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/activities/order_activity_view.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/activities/predict_activity_view.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/activities/simulator_activity_view.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/activities/spot_trap_activity_view.dart';

/// Elige la vista de [activity] y la conecta con el [controller], que guarda
/// lo respondido en el paso [step].
class ActivityView extends StatelessWidget {
  const ActivityView({
    super.key,
    required this.activity,
    required this.step,
    required this.controller,
    required this.diagram,
    required this.scale,
  });

  final LearningActivity activity;
  final int step;
  final LessonController controller;

  /// Fórmula de la ficha: la necesita el simulador.
  final FormulaDiagram? diagram;
  final ReadingScale? scale;

  @override
  Widget build(BuildContext context) {
    final diagram = this.diagram;
    return switch (activity) {
      final SimulatorActivity simulator when diagram != null =>
        SimulatorActivityView(
          activity: simulator,
          diagram: diagram,
          scale: scale,
          values: controller.simulatorValues(step),
          onChanged: (key, value) =>
              controller.setSimulatorValue(step, key, value),
          onReset: () => controller.resetSimulator(step),
        ),
      // El parser no deja un simulador sin fórmula; esto solo cubre el tipo.
      SimulatorActivity() => const SizedBox.shrink(),
      final SpotTrapActivity trap => SpotTrapActivityView(
        activity: trap,
        tapped: controller.trapsTapped(step),
        onTap: (index) => controller.tapTrapItem(step, index),
      ),
      final CompareActivity compare => CompareActivityView(
        activity: compare,
        answerIsA: controller.compareAnswer(step),
        onAnswer: (isA) => controller.answerCompare(step, isA: isA),
      ),
      final PredictActivity predict => PredictActivityView(
        activity: predict,
        selected: controller.predictAnswer(step),
        onSelect: (option) => controller.answerPredict(step, option),
      ),
      final OrderActivity order => OrderActivityView(
        activity: order,
        order: controller.orderOf(step, order),
        isChecked: controller.isOrderChecked(step),
        isCorrect: controller.isOrderCorrect(step, order),
        onReorder: (oldIndex, newIndex) =>
            controller.reorder(step, order, oldIndex, newIndex),
        onCheck: () => controller.checkOrder(step),
        onRetry: () => controller.retryOrder(step),
      ),
    };
  }
}
