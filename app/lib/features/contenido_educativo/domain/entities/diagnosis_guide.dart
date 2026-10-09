/// Una sección de la guía del diagnóstico.
class GuideSection {
  const GuideSection({required this.title, required this.body});

  final String title;
  final String body;
}

/// Guía para leer el diagnóstico: veredicto, nota, confianza, avisos y datos
/// que faltan, más las preguntas "Qué mirar antes de invertir".
class DiagnosisGuide {
  DiagnosisGuide({
    required List<GuideSection> sections,
    required this.checklistTitle,
    required this.checklistIntro,
    required List<String> checklist,
  }) : sections = List.unmodifiable(sections),
       checklist = List.unmodifiable(checklist);

  final List<GuideSection> sections;
  final String checklistTitle;
  final String checklistIntro;

  /// Preguntas para hacerse; no dicen qué decidir.
  final List<String> checklist;
}
