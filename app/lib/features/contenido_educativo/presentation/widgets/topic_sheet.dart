import 'package:flutter/material.dart';
import 'package:stock_app/features/contenido_educativo/application/use_cases/load_educational_content_use_case.dart';
import 'package:stock_app/features/contenido_educativo/presentation/content_texts.dart';
import 'package:stock_app/features/contenido_educativo/presentation/controllers/topic_controller.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/block_content_view.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/educational_notice.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/metric_content_view.dart';

/// Abre en una hoja inferior la explicación de una métrica o de un bloque.
///
/// La hoja es dueña de su controller: lo crea al montarse y lo libera cuando
/// desaparece, también tras la animación de cierre.
Future<void> showTopicSheet(
  BuildContext context, {
  required LoadEducationalContentUseCase loadContent,
  required String topicId,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => FractionallySizedBox(
    heightFactor: 0.9,
    child: _OwnedTopicSheet(loadContent: loadContent, topicId: topicId),
  ),
);

/// Crea el [TopicController] de una hoja y lo libera con ella.
class _OwnedTopicSheet extends StatefulWidget {
  const _OwnedTopicSheet({required this.loadContent, required this.topicId});

  final LoadEducationalContentUseCase loadContent;
  final String topicId;

  @override
  State<_OwnedTopicSheet> createState() => _OwnedTopicSheetState();
}

class _OwnedTopicSheetState extends State<_OwnedTopicSheet> {
  late final TopicController _controller = TopicController(
    loadContent: widget.loadContent,
    initialTopicId: widget.topicId,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TopicSheet(controller: _controller);
}

/// Contenido de la hoja de un tema: ficha de métrica o de bloque, con botón
/// para volver al tema anterior (criterio 3).
class TopicSheet extends StatefulWidget {
  const TopicSheet({super.key, required this.controller});

  final TopicController controller;

  @override
  State<TopicSheet> createState() => _TopicSheetState();
}

class _TopicSheetState extends State<TopicSheet> {
  TopicController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    if (_controller.content == null) _controller.load();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    builder: (context, _) => Column(
      children: [
        _header(context),
        Expanded(child: _body()),
      ],
    ),
  );

  Widget _header(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
    child: Row(
      children: [
        if (_controller.canGoBack)
          IconButton(
            tooltip: 'Volver',
            icon: const Icon(Icons.arrow_back),
            onPressed: _controller.goBack,
          )
        else
          const SizedBox(width: 48),
        const Spacer(),
        IconButton(
          tooltip: 'Cerrar',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    ),
  );

  Widget _body() {
    final content = _controller.content;
    if (content == null) {
      if (_controller.error != null) return _error();
      return const Center(child: CircularProgressIndicator());
    }
    final metric = _controller.currentMetric;
    final block = _controller.currentBlock;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        if (metric != null)
          MetricContentView(
            metric: metric,
            content: content,
            selectedOption: _controller.selectedOption,
            onSelectOption: _controller.selectOption,
            onOpenTopic: _controller.openTopic,
          )
        else if (block != null)
          BlockContentView(
            block: block,
            content: content,
            onOpenTopic: _controller.openTopic,
          )
        else
          const Text(unknownTopicText),
        const EducationalNotice(),
      ],
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
