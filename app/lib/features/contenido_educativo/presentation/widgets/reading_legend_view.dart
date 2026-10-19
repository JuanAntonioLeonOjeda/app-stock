import 'package:flutter/material.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/reading_scale.dart';
import 'package:stock_app/features/contenido_educativo/presentation/tone_style.dart';

/// Cómo leer una métrica sin escala por tramos (criterio 79): una fila por
/// situación, con su color y su icono.
class ReadingLegendView extends StatelessWidget {
  const ReadingLegendView({super.key, required this.rows});

  final List<LegendRow> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  toneIcon(row.tone),
                  color: toneColor(context, row.tone),
                  semanticLabel: toneLabel(row.tone),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(row.condition, style: theme.textTheme.titleSmall),
                      Text(row.meaning, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
