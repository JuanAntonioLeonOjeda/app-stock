import 'package:flutter/material.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/educational_content.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/metric_content.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/check_question_card.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/example_box.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/related_metrics.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/topic_section.dart';

/// Las secciones de la ficha de una métrica (criterio 1).
class MetricContentView extends StatelessWidget {
  const MetricContentView({
    super.key,
    required this.metric,
    required this.content,
    required this.selectedOption,
    required this.onSelectOption,
    required this.onOpenTopic,
  });

  final MetricContent metric;

  /// Todo el contenido, para poner título a las métricas relacionadas.
  final EducationalContent content;
  final int? selectedOption;
  final ValueChanged<int> onSelectOption;
  final ValueChanged<String> onOpenTopic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final related = {
      for (final id in metric.combinesWith)
        if (content.metricById(id) case final other?) id: other.title,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(metric.title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(metric.summary, style: theme.textTheme.titleSmall),
        TopicSection(
          title: 'La idea',
          icon: Icons.lightbulb_outline,
          text: metric.intuition,
        ),
        TopicSection(
          title: 'Cómo se calcula',
          icon: Icons.calculate_outlined,
          text: metric.formula,
        ),
        const SizedBox(height: 12),
        ExampleBox(text: metric.example),
        TopicSection(
          title: 'Cómo leerla',
          icon: Icons.visibility_outlined,
          text: metric.howToRead,
        ),
        TopicSection(
          title: 'Cuándo engaña',
          icon: Icons.warning_amber_outlined,
          text: metric.whenItMisleads,
        ),
        if (related.isNotEmpty)
          TopicSection(
            title: 'Se combina con',
            icon: Icons.link,
            child: RelatedMetrics(titlesById: related, onOpen: onOpenTopic),
          ),
        TopicSection(
          title: 'Comprueba lo que has aprendido',
          icon: Icons.quiz_outlined,
          child: CheckQuestionCard(
            question: metric.question,
            selectedIndex: selectedOption,
            onSelect: onSelectOption,
          ),
        ),
      ],
    );
  }
}
