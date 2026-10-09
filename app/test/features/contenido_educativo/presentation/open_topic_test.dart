import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/contenido_educativo/application/use_cases/load_educational_content_use_case.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/educational_content.dart';
import 'package:stock_app/features/contenido_educativo/presentation/open_topic.dart';
import 'package:stock_app/features/contenido_educativo/presentation/screens/diagnosis_guide_screen.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/topic_sheet.dart';

import '../application/fake_ports.dart';
import 'tall_screen.dart';

Future<void> _open(WidgetTester tester, String topicId) async {
  useTallScreen(tester);
  final loadContent = LoadEducationalContentUseCase(FakeEducationalContent());
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => openEducationalTopic(
            context,
            loadContent: loadContent,
            topicId: topicId,
          ),
          child: const Text('abrir'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  group('openEducationalTopic', () {
    testWidgets('la guía se abre a pantalla completa', (tester) async {
      await _open(tester, guideTopicId);

      expect(find.byType(DiagnosisGuideScreen), findsOneWidget);
      expect(find.byType(TopicSheet), findsNothing);
    });

    testWidgets('una métrica se abre en una hoja inferior', (tester) async {
      await _open(tester, 'per');

      expect(find.byType(TopicSheet), findsOneWidget);
      expect(find.byType(DiagnosisGuideScreen), findsNothing);
      expect(find.text('PER 12 meses'), findsOneWidget);
    });

    testWidgets('un bloque también se abre en una hoja', (tester) async {
      await _open(tester, 'bloque_tecnico');

      expect(find.byType(TopicSheet), findsOneWidget);
    });
  });
}
