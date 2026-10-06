import 'package:flutter/material.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/educational_content.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/glossary_group.dart';
import 'package:stock_app/features/contenido_educativo/presentation/content_texts.dart';
import 'package:stock_app/features/contenido_educativo/presentation/controllers/glossary_controller.dart';

/// Abre la explicación del tema [topicId]; lo aporta quien monta la pantalla
/// (el composition root), que decide si va en una hoja o a pantalla completa.
typedef OpenTopic = void Function(BuildContext context, String topicId);

/// Glosario: la guía del diagnóstico arriba, un buscador y las métricas por
/// bloque (criterios 11-14). Es dueña de su [controller].
class GlossaryScreen extends StatefulWidget {
  const GlossaryScreen({
    super.key,
    required this.controller,
    required this.openTopic,
  });

  final GlossaryController controller;
  final OpenTopic openTopic;

  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  GlossaryController get _controller => widget.controller;

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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Aprender')),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => _body(context),
      ),
    ),
  );

  Widget _body(BuildContext context) {
    if (_controller.content == null) {
      if (_controller.error != null) return _error();
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text('¿Cómo leer este diagnóstico?'),
            subtitle: const Text('Veredicto, nota, confianza y avisos'),
            onTap: () => widget.openTopic(context, guideTopicId),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Buscar una métrica',
            border: OutlineInputBorder(),
          ),
          onChanged: _controller.search,
        ),
        const SizedBox(height: 8),
        if (_controller.hasNoResults)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No hay ninguna métrica que coincida.'),
          ),
        for (final group in _controller.groups) ..._group(context, group),
      ],
    );
  }

  List<Widget> _group(BuildContext context, GlossaryGroup group) => [
    ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        group.block.title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      trailing: IconButton(
        tooltip: 'Qué mide este bloque',
        icon: const Icon(Icons.info_outline),
        onPressed: () => widget.openTopic(context, group.block.id),
      ),
    ),
    for (final metric in group.metrics)
      Card(
        child: ListTile(
          title: Text(metric.title),
          subtitle: Text(metric.summary),
          onTap: () => widget.openTopic(context, metric.id),
        ),
      ),
  ];

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
