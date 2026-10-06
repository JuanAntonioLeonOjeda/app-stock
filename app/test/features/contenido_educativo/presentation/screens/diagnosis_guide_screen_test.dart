import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/contenido_educativo/application/use_cases/load_educational_content_use_case.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/educational_content.dart';
import 'package:stock_app/features/contenido_educativo/domain/exceptions/educational_content_exception.dart';
import 'package:stock_app/features/contenido_educativo/presentation/content_texts.dart';
import 'package:stock_app/features/contenido_educativo/presentation/controllers/topic_controller.dart';
import 'package:stock_app/features/contenido_educativo/presentation/screens/diagnosis_guide_screen.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/educational_notice.dart';

import '../../application/fake_ports.dart';
import '../tall_screen.dart';

Future<void> _pump(WidgetTester tester, {FakeEducationalContent? port}) async {
  useTallScreen(tester);
  await tester.pumpWidget(
    MaterialApp(
      home: DiagnosisGuideScreen(
        controller: TopicController(
          loadContent: LoadEducationalContentUseCase(
            port ?? FakeEducationalContent(),
          ),
          initialTopicId: guideTopicId,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('DiagnosisGuideScreen', () {
    testWidgets('muestra las secciones de la guía (criterio 8)', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text('Veredicto'), findsOneWidget);
      expect(find.text('Qué significa el veredicto.'), findsOneWidget);
      expect(find.text('Confianza'), findsOneWidget);
    });

    testWidgets('muestra "Qué mirar antes de invertir" con sus preguntas', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text('Qué mirar antes de invertir'), findsOneWidget);
      expect(find.text('Preguntas para hacerse.'), findsOneWidget);
      expect(find.text('¿Entiendo el negocio?'), findsOneWidget);
      expect(find.text('¿Es dinero que no necesitaré?'), findsOneWidget);
    });

    testWidgets('incluye el aviso de que no es una recomendación', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text(educationalNoticeText), findsOneWidget);
    });

    testWidgets('si el contenido falla, avisa y permite reintentar', (
      tester,
    ) async {
      final port = FakeEducationalContent(
        error: const InvalidContentException('roto'),
      );
      await _pump(tester, port: port);

      expect(find.text(contentLoadErrorText), findsOneWidget);
      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      expect(port.loadCalls, 2);
    });
  });
}
