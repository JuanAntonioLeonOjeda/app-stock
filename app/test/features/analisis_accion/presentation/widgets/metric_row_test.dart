import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/stock_analyzer.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/metric_row.dart';

import '../../domain/motor/synthetic_companies.dart';

MetricResult _per() {
  final result = const StockAnalyzer().analyze(
    qualityCompany(),
    referenceDate: referenceDate,
  );
  return result.blocks.first.metrics.firstWhere((m) => m.id == 'per');
}

void main() {
  group('MetricRow', () {
    testWidgets('con showInfo muestra el icono y abre el tema de la métrica', (
      tester,
    ) async {
      final opened = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetricRow(
              metric: _per(),
              showInfo: (_, topicId) => opened.add(topicId),
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Qué es PER 12 meses'));

      expect(opened, ['per']);
    });

    testWidgets('sin showInfo no hay icono de información', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MetricRow(metric: _per())),
        ),
      );

      expect(find.byIcon(Icons.info_outline), findsNothing);
      expect(find.text('PER 12 meses'), findsOneWidget);
    });
  });
}
