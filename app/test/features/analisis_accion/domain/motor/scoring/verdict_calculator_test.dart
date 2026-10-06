import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/scoring/verdict_calculator.dart';

final _today = DateTime(2026, 9, 30);
final _yesterday = DateTime(2026, 9, 29);

const _longTermWeights = {
  Block.valuation: 0.3,
  Block.health: 0.2,
  Block.growth: 0.3,
  Block.technical: 0.1,
  Block.context: 0.1,
};

/// Los 5 bloques con las notas dadas (null = sin nota) y cobertura.
List<BlockResult> _blocks(Map<Block, double?> scores, {double coverage = 1}) =>
    [
      for (final block in Block.values)
        BlockResult(
          block: block,
          score: scores[block],
          weight: _longTermWeights[block]!,
          coverage: scores[block] == null ? 0 : coverage,
          metrics: [],
        ),
    ];

Map<Block, double?> _allScores(double score) => {
  for (final block in Block.values) block: score,
};

VerdictOutcome _calculate(
  List<BlockResult> blocks, {
  DateTime? lastCloseDate,
}) => calculateVerdict(
  blocks: blocks,
  lastCloseDate: lastCloseDate ?? _yesterday,
  referenceDate: _today,
);

void main() {
  group('calculateVerdict: veredicto', () {
    test('nota ≥ 7 es favorable', () {
      final outcome = _calculate(_blocks(_allScores(7)));

      expect(outcome.verdict, Verdict.favorable);
      expect(outcome.globalScore, 7);
    });

    test('nota entre 5 y 7 es neutral', () {
      expect(_calculate(_blocks(_allScores(5))).verdict, Verdict.neutral);
      expect(_calculate(_blocks(_allScores(6.9))).verdict, Verdict.neutral);
    });

    test('nota < 5 es desfavorable', () {
      expect(_calculate(_blocks(_allScores(4.9))).verdict, Verdict.unfavorable);
    });

    test('la nota global es la media ponderada de los bloques', () {
      // 0,3·8 + 0,2·6 + 0,3·7 + 0,1·5 + 0,1·9 = 7,1
      final outcome = _calculate(
        _blocks({
          Block.valuation: 8,
          Block.health: 6,
          Block.growth: 7,
          Block.technical: 5,
          Block.context: 9,
        }),
      );

      expect(outcome.globalScore, 7.1);
    });

    test('renormaliza los pesos si falta algún bloque', () {
      // Sin técnico ni contexto: (0,3·8 + 0,2·6 + 0,3·7) / 0,8 = 7,125
      final outcome = _calculate(
        _blocks({Block.valuation: 8, Block.health: 6, Block.growth: 7}),
      );

      expect(outcome.globalScore, 7.1);
    });

    test('con menos de 3 bloques con nota es datos insuficientes', () {
      final outcome = _calculate(
        _blocks({Block.valuation: 9, Block.growth: 9}),
      );

      expect(outcome.verdict, Verdict.insufficientData);
      expect(outcome.globalScore, isNull);
      expect(outcome.confidence, Confidence.low);
    });

    test('con salud < 4 un favorable queda en neutral', () {
      // 0,3·9 + 0,2·3 + 0,3·9 + 0,1·9 + 0,1·9 = 7,8
      final outcome = _calculate(_blocks({..._allScores(9), Block.health: 3}));

      expect(outcome.globalScore, 7.8);
      expect(outcome.verdict, Verdict.neutral);
      expect(outcome.isCappedByHealth, isTrue);
    });

    test('la salud débil no cambia un veredicto que ya no es favorable', () {
      final outcome = _calculate(_blocks({..._allScores(5), Block.health: 3}));

      expect(outcome.isCappedByHealth, isFalse);
    });
  });

  group('calculateVerdict: confianza', () {
    test('alta con cobertura ≥ 80 % y los 5 bloques con nota', () {
      final outcome = _calculate(_blocks(_allScores(7), coverage: 0.8));

      expect(outcome.confidence, Confidence.high);
    });

    test('media si falta un bloque aunque la cobertura sea alta', () {
      final outcome = _calculate(
        _blocks({..._allScores(7), Block.context: null}),
      );

      // Cobertura ponderada = 0,9 (el bloque sin nota pesa 0,1).
      expect(outcome.confidence, Confidence.medium);
    });

    test('media con cobertura entre 60 % y 80 %', () {
      final outcome = _calculate(_blocks(_allScores(7), coverage: 0.7));

      expect(outcome.confidence, Confidence.medium);
    });

    test('baja con cobertura < 60 %', () {
      final outcome = _calculate(_blocks(_allScores(7), coverage: 0.5));

      expect(outcome.confidence, Confidence.low);
    });

    test('siempre baja si el último cierre tiene más de 7 días', () {
      final outcome = _calculate(
        _blocks(_allScores(7)),
        lastCloseDate: DateTime(2026, 9, 20),
      );

      expect(outcome.confidence, Confidence.low);
    });
  });
}
