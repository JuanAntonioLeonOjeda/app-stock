import 'package:flutter/material.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/metric_content.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/reading_scale.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/reading_legend_view.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/scale_bar.dart';

/// Versión corta de una ficha, para desplegarla en la fila del resultado
/// (criterio 89): el resumen, la barra de tramos (o la leyenda) y un botón
/// que abre el recorrido paso a paso.
class MetricQuickView extends StatelessWidget {
  const MetricQuickView({
    super.key,
    required this.metric,
    required this.scale,
    required this.onOpenLesson,
  });

  final MetricContent metric;

  /// Escala del motor; `null` si la métrica no tiene.
  final ReadingScale? scale;
  final VoidCallback onOpenLesson;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = this.scale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(metric.title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(metric.summary, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 12),
        if (scale != null) ScaleBar(scale: scale),
        if (scale == null && metric.legend.isNotEmpty)
          ReadingLegendView(rows: metric.legend),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed: onOpenLesson,
            icon: const Icon(Icons.school_outlined),
            label: const Text('Aprender paso a paso'),
          ),
        ),
      ],
    );
  }
}
