import 'package:flutter/material.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/diagnosis_guide.dart';
import 'package:stock_app/features/contenido_educativo/presentation/content_texts.dart';
import 'package:stock_app/features/contenido_educativo/presentation/controllers/topic_controller.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/educational_notice.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/topic_section.dart';

/// "¿Cómo leer este diagnóstico?" y "Qué mirar antes de invertir"
/// (criterios 8-10). Es dueña de su [controller] (lo libera al cerrarse).
class DiagnosisGuideScreen extends StatefulWidget {
  const DiagnosisGuideScreen({super.key, required this.controller});

  final TopicController controller;

  @override
  State<DiagnosisGuideScreen> createState() => _DiagnosisGuideScreenState();
}

class _DiagnosisGuideScreenState extends State<DiagnosisGuideScreen> {
  TopicController get _controller => widget.controller;

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
    appBar: AppBar(title: const Text('¿Cómo leer este diagnóstico?')),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => _body(),
      ),
    ),
  );

  Widget _body() {
    final content = _controller.content;
    if (content == null) {
      if (_controller.error != null) return _error();
      return const Center(child: CircularProgressIndicator());
    }
    final guide = content.guide;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final section in guide.sections)
          TopicSection(title: section.title, text: section.body),
        _checklist(guide),
        const EducationalNotice(),
      ],
    );
  }

  Widget _checklist(DiagnosisGuide guide) => TopicSection(
    title: guide.checklistTitle,
    icon: Icons.fact_check_outlined,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(guide.checklistIntro),
        const SizedBox(height: 8),
        for (final question in guide.checklist)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.check_box_outline_blank),
            title: Text(question),
          ),
      ],
    ),
  );

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
