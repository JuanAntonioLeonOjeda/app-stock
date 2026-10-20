import 'package:flutter/material.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/check_question.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/educational_content.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/metric_content.dart';
import 'package:stock_app/features/contenido_educativo/presentation/controllers/lesson_controller.dart';
import 'package:stock_app/features/contenido_educativo/presentation/illustrations/illustration_for.dart';
import 'package:stock_app/features/contenido_educativo/presentation/lesson_steps.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/activities/activity_view.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/check_question_card.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/example_box.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/formula_diagram_view.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/reading_legend_view.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/related_metrics.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/scale_bar.dart';

/// Una tarjeta del recorrido: pinta el [step] de [metric] y reenvía lo que
/// pulsa el usuario al [controller].
class LessonStepView extends StatelessWidget {
  const LessonStepView({
    super.key,
    required this.step,
    required this.index,
    required this.metric,
    required this.content,
    required this.controller,
  });

  final LessonStep step;

  /// Posición del paso en el recorrido; indexa lo respondido en el controller.
  final int index;
  final MetricContent metric;
  final EducationalContent content;
  final LessonController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(metric.title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            step.label,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          ..._body(context),
        ],
      ),
    );
  }

  List<Widget> _body(BuildContext context) => switch (step) {
    IdeaStep() => _idea(context),
    CalculationStep() => _calculation(context),
    ReadingStep() => _reading(context),
    PitfallStep(:final text, :final number, :final total) => _pitfall(
      context,
      text,
      number,
      total,
    ),
    ActivityStep(:final activity) => [
      ActivityView(
        activity: activity,
        step: index,
        controller: controller,
        diagram: metric.formulaDiagram,
        scale: controller.scale,
      ),
    ],
    QuestionStep(:final question) => _question(context, question),
  };

  List<Widget> _idea(BuildContext context) => [
    if (illustrationFor(metric.id) case final illustration?) ...[
      illustration,
      const SizedBox(height: 16),
    ],
    Text(metric.intuition, style: Theme.of(context).textTheme.bodyLarge),
  ];

  List<Widget> _calculation(BuildContext context) => [
    Text(metric.formula, style: Theme.of(context).textTheme.bodyLarge),
    if (metric.formulaDiagram case final diagram?) ...[
      const SizedBox(height: 16),
      FormulaDiagramView(diagram: diagram),
    ],
    const SizedBox(height: 16),
    ExampleBox(text: metric.example),
  ];

  List<Widget> _reading(BuildContext context) {
    final scale = controller.scale;
    return [
      if (scale != null) ScaleBar(scale: scale),
      if (scale == null && metric.legend.isNotEmpty)
        ReadingLegendView(rows: metric.legend),
      const SizedBox(height: 16),
      Text(metric.howToRead, style: Theme.of(context).textTheme.bodyLarge),
    ];
  }

  List<Widget> _pitfall(
    BuildContext context,
    String text,
    int number,
    int total,
  ) {
    final theme = Theme.of(context);
    return [
      if (total > 1) ...[
        Text('Trampa $number de $total', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
      ],
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_outlined, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
        ],
      ),
    ];
  }

  List<Widget> _question(BuildContext context, CheckQuestion question) {
    final related = {
      for (final id in metric.combinesWith)
        if (content.explanationById(id) case final other?) id: other.title,
    };
    return [
      CheckQuestionCard(
        question: question,
        selectedIndex: controller.selectedOption,
        onSelect: controller.selectOption,
      ),
      if (related.isNotEmpty) ...[
        const SizedBox(height: 24),
        Text(
          'Sigue aprendiendo',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        RelatedMetrics(titlesById: related, onOpen: controller.openTopic),
      ],
    ];
  }
}
