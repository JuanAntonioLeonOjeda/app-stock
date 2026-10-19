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
      expect(find.text('30x'), findsOneWidget);
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
