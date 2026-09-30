import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';

void main() {
  group('AnalysisResult', () {
    test(
      'expone bloques, avisos y datos que faltan como listas inmutables',
      () {
        final result = AnalysisResult(
          symbol: 'TEST',
          name: 'Empresa de prueba',
          currency: 'USD',
          price: 10,
          lastCloseDate: DateTime(2026, 9, 29),
          lastFiscalPeriod: DateTime(2026, 6, 30),
          profile: CompanyProfile.general,
          horizon: Horizon.longTerm,
          verdict: Verdict.neutral,
          globalScore: 5,
          confidence: Confidence.medium,
          blocks: [],
          flags: ['aviso'],
          missingData: [],
          motorVersion: '1.0.0',
        );

        expect(() => result.flags.add('otro'), throwsUnsupportedError);
        expect(() => result.missingData.add('dato'), throwsUnsupportedError);
        expect(
          () => result.blocks.add(
            BlockResult(
              block: Block.health,
              score: null,
              weight: 0.2,
              coverage: 0,
              metrics: [],
            ),
          ),
          throwsUnsupportedError,
        );
      },
    );
  });

  group('BlockResult', () {
    test('expone sus métricas como lista inmutable', () {
      final block = BlockResult(
        block: Block.valuation,
        score: 7,
        weight: 0.3,
        coverage: 1,
        metrics: [],
      );

      expect(
        () => block.metrics.add(
          const MetricResult(
            id: 'per',
            label: 'PER',
            value: 15,
            format: MetricFormat.multiple,
            score: 8,
            weight: 1,
            note: null,
          ),
        ),
        throwsUnsupportedError,
      );
    });
  });
}
