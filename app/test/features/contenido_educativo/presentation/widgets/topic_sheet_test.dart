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
  String topic = 'per',
}) {
  return TopicController(
    loadContent: LoadEducationalContentUseCase(port),
    initialTopicId: topic,
  );
}

Future<TopicController> _pump(
  WidgetTester tester, {
  FakeEducationalContent? port,
  String topic = 'per',
}) async {
  useTallScreen(tester);
  final controller = _controller(
    port ?? FakeEducationalContent(),
    topic: topic,
  );
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: TopicSheet(controller: controller)),
    ),
  );
  await tester.pump();
  return controller;
}

void main() {
  group('TopicSheet ficha de métrica', () {
    testWidgets('muestra todas las secciones de la ficha (criterio 1)', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text('PER 12 meses'), findsOneWidget);
      expect(find.text('Cuántos años de beneficio pagas.'), findsOneWidget);
      expect(find.text('La idea'), findsOneWidget);
      expect(find.text('Una analogía cotidiana.'), findsOneWidget);
      expect(find.text('Cómo se calcula'), findsOneWidget);
      expect(find.text('Ejemplo inventado'), findsOneWidget);
      expect(find.text('Cómo leerla'), findsOneWidget);
      expect(find.text('Cuándo engaña'), findsOneWidget);
      expect(find.text('Se combina con'), findsOneWidget);
      expect(find.text('Comprueba lo que has aprendido'), findsOneWidget);
      expect(find.text(educationalNoticeText), findsOneWidget);
    });

    testWidgets('las métricas relacionadas se ven con su título', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.widgetWithText(ActionChip, 'PEG'), findsOneWidget);
    });

    testWidgets('pulsar una relacionada abre su ficha y se puede volver', (
      tester,
    ) async {
      await _pump(tester);

      await tester.tap(find.widgetWithText(ActionChip, 'PEG'));
      await tester.pump();

      expect(find.text('El PER ajustado por crecimiento.'), findsOneWidget);
      await tester.tap(find.byTooltip('Volver'));
      await tester.pump();
      expect(find.text('Cuántos años de beneficio pagas.'), findsOneWidget);
    });

    testWidgets('sin tema anterior no hay botón de volver', (tester) async {
      await _pump(tester);

      expect(find.byTooltip('Volver'), findsNothing);
    });

    testWidgets('al cambiar de ficha la respuesta elegida se borra', (
      tester,
    ) async {
      await _pump(tester);
      await tester.tap(find.text('Otra cosa'));
      await tester.pump();
      expect(find.text('¡Correcto!'), findsOneWidget);

      await tester.tap(find.widgetWithText(ActionChip, 'PEG'));
      await tester.pump();

      expect(find.text('¡Correcto!'), findsNothing);
    });

    testWidgets('responder la pregunta muestra la explicación (criterio 5)', (
      tester,
    ) async {
      await _pump(tester);

      await tester.tap(find.text('Una cosa'));
      await tester.pump();

      expect(find.text('Porque sí mide otra cosa.'), findsOneWidget);
    });
  });

  group('TopicSheet ficha de bloque', () {
    testWidgets('muestra qué responde, cómo usarlo y sus métricas', (
      tester,
    ) async {
      await _pump(tester, topic: 'bloque_valoracion');

      expect(find.text('Bloque bloque_valoracion'), findsOneWidget);
      expect(find.text('Qué pregunta responde'), findsOneWidget);
      expect(find.text('Cómo usarlo'), findsOneWidget);
      expect(find.widgetWithText(ActionChip, 'PER 12 meses'), findsOneWidget);
      expect(find.widgetWithText(ActionChip, 'PEG'), findsOneWidget);
    });

    testWidgets('pulsar una métrica del bloque abre su ficha', (tester) async {
      await _pump(tester, topic: 'bloque_valoracion');

      await tester.tap(find.widgetWithText(ActionChip, 'PEG'));
      await tester.pump();

      expect(find.text('El PER ajustado por crecimiento.'), findsOneWidget);
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
    testWidgets('abre la hoja con la ficha y se cierra', (tester) async {
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
                topicId: 'rsi',
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(
        find.text('Si el precio ha subido o bajado muy rápido.'),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pumpAndSettle();
      expect(
        find.text('Si el precio ha subido o bajado muy rápido.'),
        findsNothing,
      );
    });
  });
}
