import 'package:flutter/material.dart';

/// Resultado de una actividad: siempre una explicación, nunca solo
/// "correcto/incorrecto", y sin tono burlón (criterio 85).
class ActivityFeedback extends StatelessWidget {
  const ActivityFeedback({
    super.key,
    required this.title,
    required this.text,
    this.isPositive,
  });

  final String title;
  final String text;

  /// `true` acierto, `false` fallo, `null` informativo.
  final bool? isPositive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = switch (isPositive) {
      true => Icons.check_circle_outline,
      false => Icons.lightbulb_outline,
      null => Icons.info_outline,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(text, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
