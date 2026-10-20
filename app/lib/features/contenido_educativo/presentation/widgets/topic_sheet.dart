import 'package:flutter/material.dart';
import 'package:stock_app/features/contenido_educativo/application/use_cases/load_educational_content_use_case.dart';
import 'package:stock_app/features/contenido_educativo/presentation/content_texts.dart';
import 'package:stock_app/features/contenido_educativo/presentation/controllers/topic_controller.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/block_content_view.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/educational_notice.dart';

/// Abre en una hoja inferior la explicación de un bloque.
///
/// La hoja es dueña de su controller: lo crea al montarse y lo libera cuando
/// desaparece, también tras la animación de cierre. [onOpenTopic] se llama al
/// pulsar una de las métricas del bloque.
Future<void> showTopicSheet(
  BuildContext context, {
  required LoadEducationalContentUseCase loadContent,
  required String topicId,
  required ValueChanged<String> onOpenTopic,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => FractionallySizedBox(
    heightFactor: 0.9,
    child: _OwnedTopicSheet(
      loadContent: loadContent,
      topicId: topicId,
      onOpenTopic: onOpenTopic,
    ),
  ),
);

/// Crea el [TopicController] de una hoja y lo libera con ella.
class _OwnedTopicSheet extends StatefulWidget {
  const _OwnedTopicSheet({
    required this.loadContent,
    required this.topicId,
    required this.onOpenTopic,
  });

  final LoadEducationalContentUseCase loadContent;
  final String topicId;
  final ValueChanged<String> onOpenTopic;

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
  Widget build(BuildContext context) =>
      TopicSheet(controller: _controller, onOpenTopic: widget.onOpenTopic);
}

/// Contenido de la hoja de un bloque (criterio 7).
class TopicSheet extends StatefulWidget {
  const TopicSheet({
    super.key,
    required this.controller,
    required this.onOpenTopic,
  });

  final TopicController controller;
  final ValueChanged<String> onOpenTopic;

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

  Widget _header(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: IconButton(
        tooltip: 'Cerrar',
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
    ),
  );

  Widget _body() {
    final content = _controller.content;
    if (content == null) {
      if (_controller.error != null) return _error();
      return const Center(child: CircularProgressIndicator());
    }
    final block = _controller.currentBlock;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        if (block != null)
          BlockContentView(
            block: block,
            content: content,
            onOpenTopic: widget.onOpenTopic,
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
