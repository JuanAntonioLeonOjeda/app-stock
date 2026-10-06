import 'package:flutter/material.dart';

/// Una sección de una ficha: título y contenido.
class TopicSection extends StatelessWidget {
  const TopicSection({
    super.key,
    required this.title,
    this.text,
    this.child,
    this.icon,
  }) : assert(text != null || child != null);

  final String title;
  final String? text;
  final Widget? child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
              ],
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
            ],
          ),
          const SizedBox(height: 6),
          ?child,
          if (text case final body?)
            Text(body, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
