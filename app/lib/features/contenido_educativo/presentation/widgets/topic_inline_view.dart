import 'package:flutter/material.dart';
import 'package:stock_app/features/contenido_educativo/application/use_cases/load_educational_content_use_case.dart';
import 'package:stock_app/features/contenido_educativo/presentation/content_texts.dart';
import 'package:stock_app/features/contenido_educativo/presentation/controllers/topic_controller.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/block_content_view.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/educational_notice.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/metric_content_view.dart';

/// La explicación de una métrica o de un bloque para mostrarla en el sitio,
/// debajo del dato que se está mirando (criterios 1, 2b y 7).
///
/// Es dueña de su controller: lo crea al montarse y lo libera al ocultarse, así
/// que la respuesta de la pregunta se descarta al ocultar la explicación y no
/// se guarda nada. El contenido se lee la primera vez que se muestra.
///
/// [onOpenTopic] se llama al pulsar una métrica relacionada: esa métrica puede
/// estar en otro bloque, así que se abre aparte en vez de en el sitio.
class TopicInlineView extends StatefulWidget {
  const TopicInlineView({
    super.key,
    required this.loadContent,
    required this.topicId,
    required this.onOpenTopic,
  });

  final LoadEducationalContentUseCase loadContent;
  final String topicId;
  final ValueChanged<String> onOpenTopic;

  @override
  State<TopicInlineView> createState() => _TopicInlineViewState();
}

class _TopicInlineViewState extends State<TopicInlineView> {
  late final TopicController _controller = TopicController(
    loadContent: widget.loadContent,
    initialTopicId: widget.topicId,
  );

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    child: ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => _body(),
    ),
  );

  Widget _body() {
    final content = _controller.content;
    if (content == null) {
      if (_controller.error != null) return _error();
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final metric = _controller.currentMetric;
    final block = _controller.currentBlock;
    if (metric != null) {
      return MetricContentView(
        metric: metric,
        content: content,
        selectedOption: _controller.selectedOption,
        onSelectOption: _controller.selectOption,
        onOpenTopic: widget.onOpenTopic,
      );
    }
    if (block != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BlockContentView(
            block: block,
            content: content,
            onOpenTopic: widget.onOpenTopic,
          ),
          const EducationalNotice(),
        ],
      );
    }
    return const Text(unknownTopicText);
  }

  Widget _error() => Column(
    children: [
      const Text(contentLoadErrorText),
      const SizedBox(height: 8),
      FilledButton(
        onPressed: _controller.load,
        child: const Text('Reintentar'),
      ),
    ],
  );
}
