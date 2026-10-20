import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/scale_bar.dart';

import '../../sample_content.dart';

Future<void> _pump(WidgetTester tester, {double? marker}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ScaleBar(scale: sampleScale(), markerValue: marker),
      ),
    ),
  ),
);

void main() {
  group('ScaleBar', () {
    testWidgets('rotula las fronteras de los tramos con la unidad', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text('8x'), findsOneWidget);
      expect(find.text('18,3x'), findsOneWidget);
      expect(find.text('25x'), findsOneWidget);
      expect(find.text('50x'), findsOneWidget);
    });

    testWidgets('un lector de pantalla recibe la descripción de los tramos', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);

      expect(
        find.bySemanticsLabel(RegExp('tramo favorable de 8x a 18,3x')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('cada tramo lleva su icono: el color no es la única pista', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('la descripción incluye el valor del marcador y su tramo', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, marker: 20);

      expect(
        find.bySemanticsLabel(RegExp('Valor actual: 20x, tramo intermedio')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('en una pantalla estrecha no se pisan las etiquetas', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(230, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await _pump(tester);

      final labels = [
        for (final text in ['8x', '18,3x', '25x', '50x'])
          if (find.text(text).evaluate().isNotEmpty)
            tester.getRect(find.text(text)),
      ];
      for (var i = 1; i < labels.length; i++) {
        expect(labels[i].left, greaterThanOrEqualTo(labels[i - 1].right));
      }
      expect(find.text('8x'), findsOneWidget);
      expect(find.text('50x'), findsOneWidget);
    });

    testWidgets('sin marcador no pinta la flecha', (tester) async {
      await _pump(tester);

      expect(find.byIcon(Icons.arrow_drop_down), findsNothing);
    });

    testWidgets('con marcador pinta la flecha', (tester) async {
      await _pump(tester, marker: 20);

      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    });

    testWidgets('un marcador fuera de la escala no se sale de la barra', (
      tester,
    ) async {
      await _pump(tester, marker: 500);

      expect(tester.takeException(), isNull);
      final arrow = tester.getRect(find.byIcon(Icons.arrow_drop_down));
      final bar = tester.getRect(find.byType(ScaleBar));
      expect(arrow.right, lessThanOrEqualTo(bar.right + arrow.width));
    });

    testWidgets('cabe en una pantalla estrecha sin desbordar', (tester) async {
      tester.view.physicalSize = const Size(200, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await _pump(tester, marker: 20);

      expect(tester.takeException(), isNull);
    });
  });
}
