import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/contenido_educativo/application/use_cases/get_metric_scale_use_case.dart';
import 'package:stock_app/features/contenido_educativo/application/use_cases/load_educational_content_use_case.dart';
import 'package:stock_app/features/contenido_educativo/domain/exceptions/educational_content_exception.dart';
import 'package:stock_app/features/contenido_educativo/presentation/content_texts.dart';
import 'package:stock_app/features/contenido_educativo/presentation/controllers/lesson_controller.dart';
import 'package:stock_app/features/contenido_educativo/presentation/screens/metric_lesson_screen.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/educational_notice.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/reading_legend_view.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/scale_bar.dart';

import '../../application/fake_ports.dart';
import '../../sample_content.dart';

Future<LessonController> _pump(
  WidgetTester tester, {
  FakeEducationalContent? port,
  String topic = 'per',
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final controller = LessonController(
    loadContent: LoadEducationalContentUseCase(
      port ?? FakeEducationalContent(),
    ),
    initialTopicId: topic,
    getMetricScale: GetMetricScaleUseCase(
      FakeMetricScales({'per': sampleScale()}),
    ),
  );
  await tester.pumpWidget(
    MaterialApp(home: MetricLessonScreen(controller: controller)),
  );
  await tester.pumpAndSettle();
  return controller;
}

Future<void> _next(WidgetTester tester, [int times = 1]) async {
  for (var i = 0; i < times; i++) {
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
  }
}

void main() {
  group('MetricLessonScreen recorrido', () {
    testWidgets(
      'empieza en la idea y muestra en qué paso estás (criterio 72)',
      (tester) async {
        await _pump(tester);

        expect(find.text('La idea'), findsWidgets);
        expect(find.text('Una analogía cotidiana.'), findsOneWidget);
        expect(find.textContaining('Paso 1 de 11'), findsOneWidget);
      },
    );

    testWidgets('Siguiente y Anterior pasan de tarjeta (criterio 73)', (
      tester,
    ) async {
      final controller = await _pump(tester);

      await _next(tester);
      expect(controller.currentStep, 1);
      expect(find.text('Cómo se calcula'), findsWidgets);

      await tester.tap(find.text('Anterior'));
      await tester.pumpAndSettle();
      expect(controller.currentStep, 0);
    });

    testWidgets('en el primer paso Anterior está desactivado', (tester) async {
      await _pump(tester);

      final button = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Anterior'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets(
      'el indicador permite saltar a un paso sin hacer los anteriores',
      (tester) async {
        final controller = await _pump(tester);

        await tester.tap(find.bySemanticsLabel(RegExp('Paso 11 de 11')));
        await tester.pumpAndSettle();

        expect(controller.currentStep, 10);
        expect(find.text('¿Qué mide?'), findsOneWidget);
      },
    );

    testWidgets('el último paso ofrece Terminar y repite el aviso educativo', (
      tester,
    ) async {
      await _pump(tester);

      await _next(tester, 10);

      expect(find.text('Terminar'), findsOneWidget);
      expect(find.text('Siguiente'), findsNothing);
      expect(find.text(educationalNoticeText), findsOneWidget);
    });

    testWidgets('responder la pregunta final muestra la explicación', (
      tester,
    ) async {
      await _pump(tester);
      await _next(tester, 10);

      await tester.tap(find.text('Otra cosa'));
      await tester.pump();

      expect(find.text('¡Correcto!'), findsOneWidget);
      expect(find.text('Porque sí mide otra cosa.'), findsOneWidget);
    });
  });

  group('MetricLessonScreen tarjetas', () {
    testWidgets(
      'el cálculo dibuja la fórmula por piezas y el ejemplo inventado',
      (tester) async {
        await _pump(tester);

        await _next(tester);

        expect(find.text('Pieza precio'), findsOneWidget);
        expect(find.text('Mercado'), findsOneWidget);
        expect(find.text('Cuenta de resultados'), findsOneWidget);
        expect(find.text('Ejemplo inventado'), findsOneWidget);
      },
    );

    testWidgets('cómo leerla con escala del motor dibuja la barra', (
      tester,
    ) async {
      await _pump(tester);

      await _next(tester, 2);

      expect(find.byType(ScaleBar), findsOneWidget);
      expect(find.byType(ReadingLegendView), findsNothing);
    });

    testWidgets('cómo leerla sin escala dibuja la leyenda', (tester) async {
      await _pump(tester, topic: 'rsi');

      await _next(tester, 2);

      expect(find.byType(ScaleBar), findsNothing);
      expect(find.byType(ReadingLegendView), findsOneWidget);
      expect(find.text('Por encima de 70'), findsOneWidget);
    });

    testWidgets('cada trampa tiene su propia tarjeta y su contador', (
      tester,
    ) async {
      await _pump(tester);

      await _next(tester, 3);
      expect(find.text('Un beneficio puntual.'), findsOneWidget);
      expect(find.text('Trampa 1 de 2'), findsOneWidget);
      await _next(tester);
      expect(find.text('Beneficios negativos.'), findsOneWidget);
      expect(find.text('Trampa 2 de 2'), findsOneWidget);
    });
  });

  group('MetricLessonScreen actividades', () {
    testWidgets('el simulador mueve el resultado y lo sitúa en la escala', (
      tester,
    ) async {
      await _pump(tester);
      await _next(tester, 5);
      expect(find.text('Mueve el precio.'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);

      await tester.drag(find.byType(Slider).first, const Offset(400, 0));
      await tester.pump();

      expect(find.textContaining('Tramo'), findsWidgets);
      expect(find.textContaining('orientación'), findsOneWidget);
    });

    testWidgets('volver al ejemplo restaura los valores del simulador', (
      tester,
    ) async {
      await _pump(tester);
      await _next(tester, 5);
      await tester.drag(find.byType(Slider).first, const Offset(400, 0));
      await tester.pump();

      await tester.tap(find.text('Volver al ejemplo'));
      await tester.pump();

      expect(find.text('Precio pieza: 30'), findsNothing);
      expect(find.text('Pieza precio: 30'), findsOneWidget);
    });

    testWidgets('detectar la trampa explica el dato pulsado y deja seguir', (
      tester,
    ) async {
      await _pump(tester);
      await _next(tester, 6);

      await tester.tap(find.text('Dato 0'));
      await tester.pump();
      expect(find.text('Este dato no es la trampa'), findsOneWidget);

      await tester.tap(find.text('Dato 2'));
      await tester.pump();
      expect(find.text('¡Ahí está la trampa!'), findsOneWidget);
      expect(find.text('Explicación del dato 2.'), findsOneWidget);
    });

    testWidgets('comparar explica la respuesta, acierte o no', (tester) async {
      await _pump(tester);
      await _next(tester, 7);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Norte'));
      await tester.pump();

      expect(find.text('No exactamente.'), findsOneWidget);
      expect(find.text('Porque debe menos años de beneficio.'), findsOneWidget);
    });

    testWidgets('predecir muestra la explicación y el dato que lo confirma', (
      tester,
    ) async {
      await _pump(tester);
      await _next(tester, 8);

      await tester.tap(find.text('Bajo'));
      await tester.pump();

      expect(find.text('¡Correcto!'), findsOneWidget);
      expect(find.text('Suelen quedar en torno al 3 %.'), findsOneWidget);
    });

    testWidgets('ordenar: comprobar un orden mal puesto invita a repetir', (
      tester,
    ) async {
      await _pump(tester);
      await _next(tester, 9);

      await tester.tap(find.text('Comprobar'));
      await tester.pump();

      expect(find.text('Casi: prueba otra vez.'), findsOneWidget);
      expect(find.text('El PER mide años de beneficio.'), findsOneWidget);
      expect(find.text('8x'), findsOneWidget);
    });

    testWidgets('ordenar: repetir vuelve a pedir la comprobación', (
      tester,
    ) async {
      await _pump(tester);
      await _next(tester, 9);
      await tester.tap(find.text('Comprobar'));
      await tester.pump();

      await tester.tap(find.text('Repetir'));
      await tester.pump();

      expect(find.text('Comprobar'), findsOneWidget);
    });

    testWidgets('lo respondido se conserva al ir y volver de una tarjeta', (
      tester,
    ) async {
      await _pump(tester);
      await _next(tester, 8);
      await tester.tap(find.text('Bajo'));
      await tester.pump();

      await _next(tester);
      await tester.tap(find.text('Anterior'));
      await tester.pumpAndSettle();

      expect(find.text('Suelen quedar en torno al 3 %.'), findsOneWidget);
    });
  });

  group('MetricLessonScreen métricas relacionadas', () {
    testWidgets('pulsar una relacionada abre su ficha en la misma pantalla', (
      tester,
    ) async {
      final controller = await _pump(tester);
      await _next(tester, 10);

      await tester.tap(find.widgetWithText(ActionChip, 'PEG'));
      await tester.pumpAndSettle();

      expect(controller.currentTopicId, 'peg');
      expect(controller.currentStep, 0);
      expect(find.text('PEG'), findsWidgets);
    });

    testWidgets('el botón de volver regresa a la ficha anterior', (
      tester,
    ) async {
      final controller = await _pump(tester);
      await _next(tester, 10);
      await tester.tap(find.widgetWithText(ActionChip, 'PEG'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Volver a la ficha anterior'));
      await tester.pumpAndSettle();

      expect(controller.currentTopicId, 'per');
      expect(find.text('PER 12 meses'), findsWidgets);
    });

    testWidgets('el botón atrás del sistema regresa a la ficha anterior', (
      tester,
    ) async {
      final controller = await _pump(tester);
      await _next(tester, 10);
      await tester.tap(find.widgetWithText(ActionChip, 'PEG'));
      await tester.pumpAndSettle();
      expect(controller.currentTopicId, 'peg');

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(controller.currentTopicId, 'per');
      expect(find.byType(MetricLessonScreen), findsOneWidget);
    });

    testWidgets('sin ficha anterior no hay botón de volver a la anterior', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.byTooltip('Volver a la ficha anterior'), findsNothing);
    });
  });

  group('MetricLessonScreen estados', () {
    testWidgets('mientras carga muestra un indicador', (tester) async {
      final port = FakeEducationalContent()..gate = Completer<void>();
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = LessonController(
        loadContent: LoadEducationalContentUseCase(port),
        initialTopicId: 'per',
        getMetricScale: GetMetricScaleUseCase(FakeMetricScales({})),
      );
      await tester.pumpWidget(
        MaterialApp(home: MetricLessonScreen(controller: controller)),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      port.gate!.complete();
      await tester.pumpAndSettle();
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

    testWidgets('un tema sin explicación lo dice', (tester) async {
      await _pump(tester, topic: 'no_existe');

      expect(find.text(unknownTopicText), findsOneWidget);
    });
  });
}
