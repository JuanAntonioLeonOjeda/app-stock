import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/stock_analyzer.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/info_builder.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/metric_row.dart';

import '../../domain/motor/synthetic_companies.dart';

MetricResult _per() {
  final result = const StockAnalyzer().analyze(
    qualityCompany(),
    referenceDate: referenceDate,
  );
  return result.blocks.first.metrics.firstWhere((m) => m.id == 'per');
}

/// Explicación de mentira: solo dice de qué tema es.
Widget _fakeInfo(BuildContext context, String topicId) =>
    Text('Explicación de $topicId');

Future<void> _pump(
  WidgetTester tester, {
  InfoBuilder? buildInfo,
  List<MetricResult>? metrics,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            for (final metric in metrics ?? [_per()])
              MetricRow(metric: metric, buildInfo: buildInfo),
          ],
        ),
      ),
    ),
  ),
);

void main() {
  group('MetricRow', () {
    testWidgets('la explicación empieza oculta (criterio 2b)', (tester) async {
      await _pump(tester, buildInfo: _fakeInfo);

      expect(find.text('Explicación de per'), findsNothing);
      expect(find.text('PER 12 meses'), findsOneWidget);
    });

    testWidgets('el icono despliega la explicación justo debajo (criterio 1)', (
      tester,
    ) async {
      await _pump(tester, buildInfo: _fakeInfo);

      await tester.tap(find.byTooltip('Qué es PER 12 meses'));
      await tester.pumpAndSettle();

      expect(find.text('Explicación de per'), findsOneWidget);
      expect(find.text('PER 12 meses'), findsOneWidget);
    });

    testWidgets('pulsarlo otra vez la oculta (criterio 2b)', (tester) async {
      await _pump(tester, buildInfo: _fakeInfo);
      await tester.tap(find.byTooltip('Qué es PER 12 meses'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Ocultar qué es PER 12 meses'));
      await tester.pumpAndSettle();

      expect(find.text('Explicación de per'), findsNothing);
      expect(find.byTooltip('Qué es PER 12 meses'), findsOneWidget);
    });

    testWidgets('cada fila se despliega por separado', (tester) async {
      final result = const StockAnalyzer().analyze(
        qualityCompany(),
        referenceDate: referenceDate,
      );
      final metrics = result.blocks.first.metrics.take(2).toList();
      await _pump(tester, buildInfo: _fakeInfo, metrics: metrics);

      await tester.tap(find.byTooltip('Qué es ${metrics.first.label}'));
      await tester.pumpAndSettle();

      expect(find.text('Explicación de ${metrics.first.id}'), findsOneWidget);
      expect(find.text('Explicación de ${metrics.last.id}'), findsNothing);
    });

    testWidgets('sin buildInfo no hay icono de información', (tester) async {
      await _pump(tester);

      expect(find.byIcon(Icons.info_outline), findsNothing);
      expect(find.text('PER 12 meses'), findsOneWidget);
    });
  });

  group('MetricRow etiquetas de orientación', () {
    testWidgets(
      'el PER es esencial y está en Trade Republic (criterios 103-104)',
      (tester) async {
        await _pump(tester);

        expect(find.text('Esencial'), findsOneWidget);
        expect(find.text('Trade Republic'), findsOneWidget);
      },
    );

    testWidgets('una métrica que no está en ninguna lista no lleva etiquetas', (
      tester,
    ) async {
      final result = const StockAnalyzer().analyze(
        qualityCompany(),
        referenceDate: referenceDate,
      );
      final rsi = result.blocks
          .expand((b) => b.metrics)
          .firstWhere((m) => m.id == 'rsi');

      await _pump(tester, metrics: [rsi]);

      expect(find.text('Esencial'), findsNothing);
      expect(find.text('Trade Republic'), findsNothing);
    });
  });
}
