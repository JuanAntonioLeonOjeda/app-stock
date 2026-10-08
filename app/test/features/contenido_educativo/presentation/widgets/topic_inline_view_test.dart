import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/contenido_educativo/application/use_cases/load_educational_content_use_case.dart';
import 'package:stock_app/features/contenido_educativo/domain/exceptions/educational_content_exception.dart';
import 'package:stock_app/features/contenido_educativo/presentation/content_texts.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/educational_notice.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/topic_inline_view.dart';

import '../../application/fake_ports.dart';
import '../tall_screen.dart';

Future<List<String>> _pump(
  WidgetTester tester, {
  FakeEducationalContent? port,
  String topic = 'per',
}) async {
  useTallScreen(tester);
  final related = <String>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: TopicInlineView(
            loadContent: LoadEducationalContentUseCase(
              port ?? FakeEducationalContent(),
            ),
            topicId: topic,
            onOpenTopic: related.add,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return related;
}

void main() {
  group('TopicInlineView', () {
    testWidgets('lee el contenido al mostrarse y pinta la ficha', (
      tester,
    ) async {
      final port = FakeEducationalContent();

      await _pump(tester, port: port);

      expect(port.loadCalls, 1);
      expect(find.text('PER 12 meses'), findsOneWidget);
      expect(find.text('Cómo leerla'), findsOneWidget);
      expect(find.text('Comprueba lo que has aprendido'), findsOneWidget);
    });

    testWidgets('un concepto de la gráfica se ve como una ficha', (
      tester,
    ) async {
      await _pump(tester, topic: 'media_50');

      expect(find.text('Media de 50 sesiones'), findsOneWidget);
      expect(find.text('Cómo leerla'), findsOneWidget);
      expect(find.text('Comprueba lo que has aprendido'), findsOneWidget);
    });

    testWidgets('mientras carga muestra un indicador', (tester) async {
      final port = FakeEducationalContent()..gate = Completer<void>();
      await _pump(tester, port: port);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      port.gate!.complete();
      await tester.pump();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets(
      'una métrica relacionada se abre aparte, sin cambiar la ficha',
      (tester) async {
        final related = await _pump(tester);

        await tester.tap(find.widgetWithText(ActionChip, 'PEG'));

        expect(related, ['peg']);
        expect(find.text('PER 12 meses'), findsOneWidget);
      },
    );

    testWidgets('responder la pregunta muestra la explicación', (tester) async {
      await _pump(tester);

      await tester.tap(find.text('Otra cosa'));
      await tester.pump();

      expect(find.text('¡Correcto!'), findsOneWidget);
    });

    testWidgets(
      'un bloque muestra su ficha y el aviso educativo (criterio 7)',
      (tester) async {
        await _pump(tester, topic: 'bloque_valoracion');

        expect(find.text('Qué pregunta responde'), findsOneWidget);
        expect(find.text('Cómo usarlo'), findsOneWidget);
        expect(find.text(educationalNoticeText), findsOneWidget);
      },
    );

    testWidgets('una ficha de métrica no repite el aviso grande', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text(educationalNoticeText), findsNothing);
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

    testWidgets('un tema sin explicación lo dice', (tester) async {
      await _pump(tester, topic: 'no_existe');

      expect(find.text(unknownTopicText), findsOneWidget);
    });

    testWidgets('al ocultarse libera el controller sin errores', (
      tester,
    ) async {
      await _pump(tester);

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      expect(tester.takeException(), isNull);
    });
  });
}
