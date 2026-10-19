import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/contenido_educativo/application/use_cases/load_educational_content_use_case.dart';
import 'package:stock_app/features/contenido_educativo/domain/exceptions/educational_content_exception.dart';
import 'package:stock_app/features/contenido_educativo/presentation/content_texts.dart';
import 'package:stock_app/features/contenido_educativo/presentation/controllers/topic_controller.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/educational_notice.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/topic_sheet.dart';

import '../../application/fake_ports.dart';
import '../tall_screen.dart';

TopicController _controller(
  FakeEducationalContent port, {
  String topic = 'bloque_valoracion',
}) {
  return TopicController(
    loadContent: LoadEducationalContentUseCase(port),
    initialTopicId: topic,
  );
}

Future<List<String>> _pump(
  WidgetTester tester, {
  FakeEducationalContent? port,
  String topic = 'bloque_valoracion',
}) async {
  useTallScreen(tester);
  final controller = _controller(
    port ?? FakeEducationalContent(),
    topic: topic,
  );
  addTearDown(controller.dispose);
  final opened = <String>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TopicSheet(controller: controller, onOpenTopic: opened.add),
      ),
    ),
  );
  await tester.pump();
  return opened;
}

void main() {
  group('TopicSheet ficha de bloque', () {
    testWidgets('muestra qué responde, cómo usarlo y sus métricas', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text('Bloque bloque_valoracion'), findsOneWidget);
      expect(find.text('Qué pregunta responde'), findsOneWidget);
      expect(find.text('Cómo usarlo'), findsOneWidget);
      expect(find.widgetWithText(ActionChip, 'PER 12 meses'), findsOneWidget);
      expect(find.widgetWithText(ActionChip, 'PEG'), findsOneWidget);
      expect(find.text(educationalNoticeText), findsOneWidget);
    });

    testWidgets('pulsar una métrica del bloque pide abrir su ficha', (
      tester,
    ) async {
      final opened = await _pump(tester);

      await tester.tap(find.widgetWithText(ActionChip, 'PEG'));

      expect(opened, ['peg']);
    });
  });

  group('TopicSheet estados', () {
    testWidgets('mientras carga muestra un indicador', (tester) async {
      final port = FakeEducationalContent()..gate = Completer<void>();
      await _pump(tester, port: port);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      port.gate!.complete();
      await tester.pump();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
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

    testWidgets('un tema sin explicación lo dice, sin romperse', (
      tester,
    ) async {
      await _pump(tester, topic: 'no_existe');

      expect(find.text(unknownTopicText), findsOneWidget);
    });
  });

  group('showTopicSheet', () {
    testWidgets('abre la hoja con el bloque y se cierra', (tester) async {
      useTallScreen(tester);
      final loadContent = LoadEducationalContentUseCase(
        FakeEducationalContent(),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showTopicSheet(
                context,
                loadContent: loadContent,
                topicId: 'bloque_tecnico',
                onOpenTopic: (_) {},
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Bloque bloque_tecnico'), findsOneWidget);

      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pumpAndSettle();
      expect(find.text('Bloque bloque_tecnico'), findsNothing);
    });
  });
}
