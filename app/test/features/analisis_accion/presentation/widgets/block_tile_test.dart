import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/stock_analyzer.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/block_tile.dart';

import '../../domain/motor/synthetic_companies.dart';

BlockResult _valuation() => const StockAnalyzer()
    .analyze(qualityCompany(), referenceDate: referenceDate)
    .blocks
    .firstWhere((b) => b.block == Block.valuation);

void main() {
  group('BlockTile', () {
    testWidgets('el icono del bloque abre su tema, sin desplegarlo', (
      tester,
    ) async {
      final opened = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlockTile(
              block: _valuation(),
              showInfo: (_, topicId) => opened.add(topicId),
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Qué mide Valoración'));
      await tester.pump();

      expect(opened, ['bloque_valoracion']);
      expect(find.text('PER 12 meses'), findsNothing);
    });

    testWidgets('al desplegar, cada métrica tiene su icono', (tester) async {
      final opened = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BlockTile(
                block: _valuation(),
                showInfo: (_, topicId) => opened.add(topicId),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Valoración'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Qué es PEG'));

      expect(opened, ['peg']);
    });

    testWidgets('sin showInfo no hay iconos de información', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BlockTile(block: _valuation())),
        ),
      );

      expect(find.byIcon(Icons.info_outline), findsNothing);
    });
  });
}
