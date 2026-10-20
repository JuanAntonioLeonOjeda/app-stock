import 'package:flutter/material.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/educational_content.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/metric_content.dart';
import 'package:stock_app/features/contenido_educativo/presentation/content_texts.dart';
import 'package:stock_app/features/contenido_educativo/presentation/controllers/lesson_controller.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/educational_notice.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/lesson_progress.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/lesson_step_view.dart';

/// Recorrido a pantalla completa de una métrica o de un concepto de la
/// gráfica, en tarjetas cortas (criterios 72-73 y 90).
///
/// Una métrica relacionada se abre en la misma pantalla y el botón de volver
/// regresa a la anterior. El [controller] lo crea quien abre la pantalla y esta
/// lo libera al cerrarse (la ruta es de un solo uso).
class MetricLessonScreen extends StatefulWidget {
  const MetricLessonScreen({super.key, required this.controller});

  final LessonController controller;

  @override
  State<MetricLessonScreen> createState() => _MetricLessonScreenState();
}

class _MetricLessonScreenState extends State<MetricLessonScreen> {
  LessonController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    if (_controller.content == null) _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    // El botón atrás del sistema también regresa a la ficha anterior antes
    // de cerrar la pantalla.
    builder: (context, _) => PopScope(
      canPop: !_controller.canGoBack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _controller.goBack();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: _controller.canGoBack
              ? IconButton(
                  tooltip: 'Volver a la ficha anterior',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _controller.goBack,
                )
              : null,
          title: const Text('Aprender'),
        ),
        body: SafeArea(child: _body()),
      ),
    ),
  );

  Widget _body() {
    final content = _controller.content;
    if (content == null) {
      if (_controller.error != null) return _error();
      return const Center(child: CircularProgressIndicator());
    }
    final metric = _controller.currentMetric;
    if (metric == null) return const Center(child: Text(unknownTopicText));
    // La clave rehace el paginador al cambiar de ficha: vuelve al primer paso.
    return _LessonPager(
      key: ValueKey(_controller.currentTopicId),
      controller: _controller,
      metric: metric,
      content: content,
    );
  }

  Widget _error() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(contentLoadErrorText),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _controller.load,
          child: const Text('Reintentar'),
        ),
      ],
    ),
  );
}

/// Las tarjetas de una ficha con su indicador y los botones de avance.
class _LessonPager extends StatefulWidget {
  const _LessonPager({
    super.key,
    required this.controller,
    required this.metric,
    required this.content,
  });

  final LessonController controller;
  final MetricContent metric;
  final EducationalContent content;

  @override
  State<_LessonPager> createState() => _LessonPagerState();
}

class _LessonPagerState extends State<_LessonPager> {
  final PageController _pages = PageController();

  LessonController get _controller => widget.controller;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = _controller.steps;
    final metric = widget.metric;
    final content = widget.content;
    return Column(
      children: [
        LessonProgress(
          labels: [for (final step in steps) step.label],
          current: _controller.currentStep,
          onSelect: _goTo,
        ),
        Expanded(
          child: PageView.builder(
            controller: _pages,
            itemCount: steps.length,
            onPageChanged: _controller.goToStep,
            itemBuilder: (context, index) => LessonStepView(
              step: steps[index],
              index: index,
              metric: metric,
              content: content,
              controller: _controller,
            ),
          ),
        ),
        _navigation(steps.length),
      ],
    );
  }

  Widget _navigation(int count) {
    final isLast = _controller.currentStep == count - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: _controller.currentStep == 0
                    ? null
                    : () => _goTo(_controller.currentStep - 1),
                icon: const Icon(Icons.chevron_left),
                label: const Text('Anterior'),
              ),
              const Spacer(),
              if (isLast)
                FilledButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Terminar'),
                )
              else
                FilledButton.icon(
                  onPressed: () => _goTo(_controller.currentStep + 1),
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('Siguiente'),
                ),
            ],
          ),
          if (isLast) const EducationalNotice(),
        ],
      ),
    );
  }

  void _goTo(int index) => _pages.animateToPage(
    index,
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeOut,
  );
}
