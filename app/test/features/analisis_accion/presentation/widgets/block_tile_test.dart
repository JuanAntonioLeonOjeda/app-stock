import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/stock_analyzer.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/block_tile.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/info_builder.dart';

import '../../domain/motor/synthetic_companies.dart';

BlockResult _valuation() => const StockAnalyzer()
    .analyze(qualityCompany(), referenceDate: referenceDate)
    .blocks
    .firstWhere((b) => b.block == Block.valuation);

Widget _fakeInfo(BuildContext context, String topicId) =>
    Text('Explicación de $topicId');

Future<void> _pump(WidgetTester tester, {InfoBuilder? buildInfo}) {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: BlockTile(block: _valuation(), buildInfo: buildInfo),
        ),
      ),
    ),
  );
}

void main() {
  group('BlockTile', () {
    testWidgets('empieza plegado y sin explicación', (tester) async {
      await _pump(tester, buildInfo: _fakeInfo);

      expect(find.text('Explicación de bloque_valoracion'), findsNothing);
      expect(find.text('PER 12 meses'), findsNothing);
    });

    testWidgets(
      'el icono despliega el bloque y muestra su explicación arriba',
      (tester) async {
        await _pump(tester, buildInfo: _fakeInfo);

        await tester.tap(find.byTooltip('Qué mide Valoración'));
        await tester.pumpAndSettle();

        expect(find.text('Explicación de bloque_valoracion'), findsOneWidget);
        expect(find.text('PER 12 meses'), findsOneWidget);
        final infoTop = tester
            .getTopLeft(find.text('Explicación de bloque_valoracion'))
            .dy;
        final firstMetricTop = tester.getTopLeft(find.text('PER 12 meses')).dy;
        expect(infoTop, lessThan(firstMetricTop));
      },
    );

    testWidgets('pulsarlo otra vez oculta la explicación (criterio 7)', (
      tester,
    ) async {
      await _pump(tester, buildInfo: _fakeInfo);
      await tester.tap(find.byTooltip('Qué mide Valoración'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Ocultar qué mide Valoración'));
      await tester.pumpAndSettle();

      expect(find.text('Explicación de bloque_valoracion'), findsNothing);
      expect(find.text('PER 12 meses'), findsOneWidget);
    });

    testWidgets('si el bloque ya estaba desplegado, el icono solo muestra la '
        'explicación', (tester) async {
      await _pump(tester, buildInfo: _fakeInfo);
      await tester.tap(find.text('Valoración'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Qué mide Valoración'));
      await tester.pumpAndSettle();

      expect(find.text('Explicación de bloque_valoracion'), findsOneWidget);
      expect(find.text('PER 12 meses'), findsOneWidget);
    });

    testWidgets('al desplegar, cada métrica tiene su propia explicación', (
      tester,
    ) async {
      await _pump(tester, buildInfo: _fakeInfo);
      await tester.tap(find.text('Valoración'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Qué es PEG'));
      await tester.pumpAndSettle();

      expect(find.text('Explicación de peg'), findsOneWidget);
      expect(find.text('Explicación de per'), findsNothing);
    });

    testWidgets('sin buildInfo no hay iconos de información', (tester) async {
      await _pump(tester);

      expect(find.byIcon(Icons.info_outline), findsNothing);
    });
  });
}
