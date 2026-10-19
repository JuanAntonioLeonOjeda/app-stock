import 'package:flutter/material.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/learning_activity.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/activities/activity_feedback.dart';

/// Predecir antes de mirar (criterio 84): se elige una opción y después se
/// enseña el dato que lo confirma.
class PredictActivityView extends StatelessWidget {
  const PredictActivityView({
    super.key,
    required this.activity,
    required this.selected,
    required this.onSelect,
  });

  final PredictActivity activity;
  final int? selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final choice = selected;
    final isCorrect = choice == activity.correctIndex;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(activity.text, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < activity.options.length; i++)
              ChoiceChip(
                label: Text(activity.options[i]),
                selected: choice == i,
                onSelected: (_) => onSelect(i),
              ),
          ],
        ),
        if (choice != null) ...[
          const SizedBox(height: 12),
          ActivityFeedback(
            title: isCorrect ? '¡Correcto!' : 'No exactamente.',
            text: activity.explanation,
            isPositive: isCorrect,
          ),
          const SizedBox(height: 8),
          ActivityFeedback(
            title: 'Lo que dicen los datos',
            text: activity.reveal,
          ),
        ],
      ],
    );
  }
}
