import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/stock_analyzer.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/metric_guidance.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/essentials_card.dart';

import '../../domain/motor/synthetic_companies.dart';

AnalysisResult _result() => const StockAnalyzer().analyze(
  qualityCompany(),
  referenceDate: referenceDate,
);

Future<void> _pump(
  WidgetTester tester,
  AnalysisResult result, {
  List<String>? opened,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: EssentialsCard(
          result: result,
          showInfo: opened == null ? null : (_, id) => opened.add(id),
        ),
      ),
    ),
  ),
);

void main() {
  group('signalForScore', () {
    test('usa los cortes del veredicto', () {
      expect(signalForScore(7), Verdict.favorable);
      expect(signalForScore(6.9), Verdict.neutral);
      expect(signalForScore(5), Verdict.neutral);
      expect(signalForScore(4.9), Verdict.unfavorable);
    });

    test('sin nota es "sin datos"', () {
      expect(signalForScore(null), Verdict.insufficientData);
    });
  });

  group('metric_guidance', () {
    test('cada métrica esencial existe en el motor', () {
      final ids = {
        for (final block in _result().blocks)
          for (final metric in block.metrics) metric.id,
      };

      expect(essentialMetrics.map((m) => m.id), everyElement(isIn(ids)));
    });

    test('el PER está en Trade Republic y el RSI no', () {
      expect(isInTradeRepublic('per'), isTrue);
      expect(isInTradeRepublic('rsi'), isFalse);
    });
  });

  group('EssentialsCard', () {
    testWidgets(
      'muestra las preguntas con valor y semáforo (criterios 98-99)',
      (tester) async {
        await _pump(tester, _result());

        expect(find.text('Lo esencial'), findsOneWidget);
        expect(find.text('¿Aguanta sus deudas?'), findsOneWidget);
        expect(find.text('¿Está cara respecto a lo que gana?'), findsOneWidget);
        final labels = {'Favorable', 'Neutral', 'Desfavorable', 'Sin dato'};
        final shown = tester
            .widgetList<Text>(find.byType(Text))
            .where((t) => labels.contains(t.data));
        expect(shown, isNotEmpty);
      },
    );

    testWidgets('etiqueta el PER como Trade Republic (criterio 103)', (
      tester,
    ) async {
      await _pump(tester, _result());

      expect(find.text('Trade Republic'), findsOneWidget);
    });

    testWidgets(
      'pulsar una fila abre la explicación de la métrica (criterio 101)',
      (tester) async {
        final opened = <String>[];
        await _pump(tester, _result(), opened: opened);

        await tester.tap(find.text('¿Aguanta sus deudas?'));

        expect(opened, ['deuda_ebitda']);
      },
    );

    testWidgets('sin ninguna métrica esencial no hay tarjeta (criterio 102)', (
      tester,
    ) async {
      final empty = AnalysisResult(
        symbol: 'X',
        name: 'X',
        currency: 'EUR',
        price: 1,
        lastCloseDate: referenceDate,
        lastFiscalPeriod: null,
        profile: CompanyProfile.general,
        horizon: Horizon.longTerm,
        globalScore: null,
        verdict: Verdict.insufficientData,
        confidence: Confidence.low,
        blocks: const [],
        flags: const [],
        missingData: const [],
        motorVersion: '1',
      );
      await _pump(tester, empty);

      expect(find.text('Lo esencial'), findsNothing);
    });
  });
}
