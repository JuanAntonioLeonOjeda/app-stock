import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/contenido_educativo/presentation/lesson_steps.dart';

import '../sample_content.dart';

void main() {
  group('lessonStepsFor', () {
    final content = sampleContent();

    test('una ficha completa sigue el orden idea → pregunta', () {
      final steps = lessonStepsFor(content.metricById('per')!);

      expect(steps.map((s) => s.runtimeType), [
        IdeaStep,
        CalculationStep,
        ReadingStep,
        PitfallStep,
        PitfallStep,
        ActivityStep,
        ActivityStep,
        ActivityStep,
        ActivityStep,
        ActivityStep,
        QuestionStep,
      ]);
    });

    test('hay una tarjeta por cada trampa, numeradas desde 1', () {
      final pitfalls = lessonStepsFor(content.metricById('per')!)
          .whereType<PitfallStep>()
          .toList();

      expect(pitfalls.map((p) => p.number), [1, 2]);
      expect(pitfalls.first.text, 'Un beneficio puntual.');
    });

    test('una ficha sin actividades salta directamente a la pregunta', () {
      final steps = lessonStepsFor(content.metricById('peg')!);

      expect(steps.whereType<ActivityStep>(), isEmpty);
      expect(steps.last, isA<QuestionStep>());
    });
  });
}
