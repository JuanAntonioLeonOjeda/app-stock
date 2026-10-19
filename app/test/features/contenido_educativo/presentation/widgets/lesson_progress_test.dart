import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/lesson_progress.dart';

Future<List<int>> _pump(WidgetTester tester, {int current = 0}) async {
  final selected = <int>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: LessonProgress(
          labels: const ['La idea', 'Cómo se calcula', 'Cómo leerla', 'Test'],
          current: current,
          onSelect: selected.add,
        ),
      ),
    ),
  );
  return selected;
}

void main() {
  group('LessonProgress', () {
    testWidgets('dice en qué paso estás y cómo se llama', (tester) async {
      await _pump(tester, current: 1);

      expect(find.text('Paso 2 de 4 · Cómo se calcula'), findsOneWidget);
    });

    testWidgets('cada punto mide al menos 48 dp para poder pulsarlo', (
      tester,
    ) async {
      await _pump(tester);

      final dots = find.byType(InkWell);
      expect(dots, findsNWidgets(4));
      for (var i = 0; i < 4; i++) {
        final size = tester.getSize(dots.at(i));
        expect(size.width, greaterThanOrEqualTo(48), reason: 'punto $i');
        expect(size.height, greaterThanOrEqualTo(48), reason: 'punto $i');
      }
    });

    testWidgets('pulsar un punto salta a ese paso', (tester) async {
      final selected = await _pump(tester);

      await tester.tap(find.byType(InkWell).at(2));

      expect(selected, [2]);
    });
  });
}
