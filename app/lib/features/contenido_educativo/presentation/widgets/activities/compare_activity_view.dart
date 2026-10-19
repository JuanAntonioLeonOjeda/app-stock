import 'package:flutter/material.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/learning_activity.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/activities/activity_feedback.dart';

/// Comparar dos empresas inventadas y responder una pregunta sobre ellas
/// (criterio 83). Nunca dice cuál conviene comprar.
class CompareActivityView extends StatelessWidget {
  const CompareActivityView({
    super.key,
    required this.activity,
    required this.answerIsA,
    required this.onAnswer,
  });

  final CompareActivity activity;

  /// `true` si eligió la empresa A, `false` la B, `null` si no ha respondido.
  final bool? answerIsA;
  final ValueChanged<bool> onAnswer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final answer = answerIsA;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Sector: ${activity.sector}', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        _table(theme),
        const SizedBox(height: 12),
        Text(activity.question, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _choice(activity.companyA, isA: true, answer: answer),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _choice(activity.companyB, isA: false, answer: answer),
            ),
          ],
        ),
        if (answer != null) ...[
          const SizedBox(height: 12),
          ActivityFeedback(
            title: answer == activity.correctIsA
                ? '¡Correcto!'
                : 'No exactamente.',
            text: activity.explanation,
            isPositive: answer == activity.correctIsA,
          ),
        ],
      ],
    );
  }

  Widget _table(ThemeData theme) => Table(
    columnWidths: const {0: FlexColumnWidth(1.4)},
    border: TableBorder(
      horizontalInside: BorderSide(color: theme.colorScheme.outlineVariant),
    ),
    children: [
      TableRow(
        children: [
          const SizedBox.shrink(),
          _cell(activity.companyA, theme.textTheme.titleSmall),
          _cell(activity.companyB, theme.textTheme.titleSmall),
        ],
      ),
      for (final row in activity.rows)
        TableRow(
          children: [
            _cell(row.label, theme.textTheme.bodyMedium),
            _cell(row.a, theme.textTheme.bodyLarge),
            _cell(row.b, theme.textTheme.bodyLarge),
          ],
        ),
    ],
  );

  Widget _cell(String text, TextStyle? style) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    child: Text(text, style: style),
  );

  Widget _choice(String label, {required bool isA, required bool? answer}) =>
      answer == isA
      ? FilledButton(onPressed: () => onAnswer(isA), child: Text(label))
      : OutlinedButton(onPressed: () => onAnswer(isA), child: Text(label));
}
