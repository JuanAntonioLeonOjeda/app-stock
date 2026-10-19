import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/contenido_educativo/application/use_cases/get_metric_scale_use_case.dart';
import 'package:stock_app/features/contenido_educativo/application/use_cases/load_educational_content_use_case.dart';
import 'package:stock_app/features/contenido_educativo/domain/exceptions/educational_content_exception.dart';
import 'package:stock_app/features/contenido_educativo/presentation/content_texts.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/educational_notice.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/metric_quick_view.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/reading_legend_view.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/scale_bar.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/topic_inline_view.dart';

import '../../application/fake_ports.dart';
import '../../sample_content.dart';
import '../tall_screen.dart';

Future<List<String>> _pump(
  WidgetTester tester, {
  FakeEducationalContent? port,
  String topic = 'per',
}) async {
  useTallScreen(tester);
  final opened = <String>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: TopicInlineView(
            loadContent: LoadEducationalContentUseCase(
              port ?? FakeEducationalContent(),
            ),
            getMetricScale: GetMetricScaleUseCase(
              FakeMetricScales({'per': sampleScale()}),
            ),
            topicId: topic,
            onOpenTopic: opened.add,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return opened;
}

void main() {
  group('TopicInlineView', () {
    testWidgets('lee el contenido al mostrarse y pinta la versión corta', (
      tester,
    ) async {
      final port = FakeEducationalContent();

      await _pump(tester, port: port);

      expect(port.loadCalls, 1);
      expect(find.byType(MetricQuickView), findsOneWidget);
      expect(find.text('PER 12 meses'), findsOneWidget);
      expect(find.text('Cuántos años de beneficio pagas.'), findsOneWidget);
    });

    testWidgets('una métrica con escala dibuja la barra de tramos', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.byType(ScaleBar), findsOneWidget);
      expect(find.byType(ReadingLegendView), findsNothing);
    });

    testWidgets('una métrica sin escala pero con leyenda la muestra', (
      tester,
    ) async {
      await _pump(tester, topic: 'rsi');

      expect(find.byType(ScaleBar), findsNothing);
      expect(find.byType(ReadingLegendView), findsOneWidget);
    });

    testWidgets('un concepto de la gráfica se ve como versión corta', (
      tester,
    ) async {
      await _pump(tester, topic: 'media_50');

      expect(find.text('Media de 50 sesiones'), findsOneWidget);
      expect(find.text('Aprender paso a paso'), findsOneWidget);
    });

    testWidgets('"Aprender paso a paso" abre el recorrido de esa métrica', (
      tester,
    ) async {
      final opened = await _pump(tester);

      await tester.tap(find.text('Aprender paso a paso'));

      expect(opened, ['per']);
    });

    testWidgets('la versión corta no despliega la ficha entera', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text('Cómo se calcula'), findsNothing);
      expect(find.text('Comprueba lo que has aprendido'), findsNothing);
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
      'un bloque muestra su ficha y el aviso educativo (criterio 7)',
      (tester) async {
        await _pump(tester, topic: 'bloque_valoracion');

        expect(find.text('Qué pregunta responde'), findsOneWidget);
        expect(find.text('Cómo usarlo'), findsOneWidget);
        expect(find.text(educationalNoticeText), findsOneWidget);
      },
    );

    testWidgets('pulsar una métrica de un bloque pide abrirla', (tester) async {
      final opened = await _pump(tester, topic: 'bloque_valoracion');

      await tester.tap(find.widgetWithText(ActionChip, 'PEG'));

      expect(opened, ['peg']);
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
