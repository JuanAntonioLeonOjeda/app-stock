import 'package:flutter/material.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/block_content.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/educational_content.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/related_metrics.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/topic_section.dart';

/// La ficha de un bloque: qué pregunta responde, qué métricas usa y cómo
/// usarlo (criterio 7).
class BlockContentView extends StatelessWidget {
  const BlockContentView({
    super.key,
    required this.block,
    required this.content,
    required this.onOpenTopic,
  });

  final BlockContent block;
  final EducationalContent content;
  final ValueChanged<String> onOpenTopic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = {
      for (final id in block.metricIds)
        if (content.metricById(id) case final metric?) id: metric.title,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(block.title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(block.summary, style: theme.textTheme.titleSmall),
        TopicSection(
          title: 'Qué pregunta responde',
          icon: Icons.help_outline,
          text: block.answers,
        ),
        TopicSection(
          title: 'Cómo usarlo',
          icon: Icons.tips_and_updates_outlined,
          text: block.howToUse,
        ),
        TopicSection(
          title: 'Métricas de este bloque',
          icon: Icons.list_alt,
          child: RelatedMetrics(titlesById: metrics, onOpen: onOpenTopic),
        ),
      ],
    );
  }
}
