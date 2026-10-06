import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/contenido_educativo/application/use_cases/load_educational_content_use_case.dart';
import 'package:stock_app/features/contenido_educativo/application/use_cases/search_glossary_use_case.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/educational_content.dart';
import 'package:stock_app/features/contenido_educativo/domain/exceptions/educational_content_exception.dart';
import 'package:stock_app/features/contenido_educativo/presentation/content_texts.dart';
import 'package:stock_app/features/contenido_educativo/presentation/controllers/glossary_controller.dart';
import 'package:stock_app/features/contenido_educativo/presentation/screens/glossary_screen.dart';

import '../../application/fake_ports.dart';
import '../tall_screen.dart';

Future<List<String>> _pump(
  WidgetTester tester, {
  FakeEducationalContent? port,
}) async {
  useTallScreen(tester);
  final opened = <String>[];
  final controller = GlossaryController(
    loadContent: LoadEducationalContentUseCase(
      port ?? FakeEducationalContent(),
    ),
    searchGlossary: const SearchGlossaryUseCase(),
  );
  await tester.pumpWidget(
    MaterialApp(
      home: GlossaryScreen(
        controller: controller,
        openTopic: (_, topicId) => opened.add(topicId),
      ),
    ),
  );
  await tester.pump();
  return opened;
}

void main() {
  group('GlossaryScreen', () {
    testWidgets('muestra la guía y las métricas agrupadas por bloque', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text('¿Cómo leer este diagnóstico?'), findsOneWidget);
      expect(find.text('Bloque bloque_valoracion'), findsOneWidget);
      expect(find.text('Bloque bloque_tecnico'), findsOneWidget);
      expect(find.text('PER 12 meses'), findsOneWidget);
      expect(find.text('Cuántos años de beneficio pagas.'), findsOneWidget);
      expect(find.text('RSI'), findsOneWidget);
    });

    testWidgets('pulsar una métrica abre su tema', (tester) async {
      final opened = await _pump(tester);

      await tester.tap(find.text('PEG'));

      expect(opened, ['peg']);
    });

    testWidgets('pulsar la guía abre el tema de la guía', (tester) async {
      final opened = await _pump(tester);

      await tester.tap(find.text('¿Cómo leer este diagnóstico?'));

      expect(opened, [guideTopicId]);
    });

    testWidgets('el icono de un bloque abre la ficha del bloque', (
      tester,
    ) async {
      final opened = await _pump(tester);

      await tester.tap(find.byTooltip('Qué mide este bloque').first);

      expect(opened, ['bloque_valoracion']);
    });

    testWidgets('el buscador filtra sin distinguir tildes', (tester) async {
      await _pump(tester);

      await tester.enterText(find.byType(TextField), 'CUANTOS anos');
      await tester.pump();

      expect(find.text('PER 12 meses'), findsOneWidget);
      expect(find.text('PEG'), findsNothing);
      expect(find.text('RSI'), findsNothing);
      expect(find.text('Bloque bloque_tecnico'), findsNothing);
    });

    testWidgets('sin coincidencias lo indica', (tester) async {
      await _pump(tester);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump();

      expect(find.text('No hay ninguna métrica que coincida.'), findsOneWidget);
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
