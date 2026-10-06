import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/indicators/metric_value.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/rules/metric_rule.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/scoring/block_scorer.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/scoring/piecewise_scale.dart';

// Escala identidad: la nota es el propio valor (0-10).
const _identity = ScaleScoring([ScorePoint(0, 0), ScorePoint(10, 10)]);

MetricRule _rule(String id, {double weight = 1, Set<CompanyProfile>? only}) =>
    MetricRule(
      id: id,
      block: Block.valuation,
      label: id.toUpperCase(),
      format: MetricFormat.decimal,
      scoring: _identity,
      weight: weight,
      onlyFor: only,
    );

BlockResult _score(Map<String, MetricValue> values, List<MetricRule> rules) =>
    scoreBlock(
      block: Block.valuation,
      blockWeight: 0.3,
      profile: CompanyProfile.general,
      values: values,
      rules: rules,
    );

void main() {
  group('scoreBlock', () {
    test('la nota es la media ponderada de las métricas con nota', () {
      final result = _score(
        {'a': const MetricValue(8), 'b': const MetricValue(5)},
        [_rule('a', weight: 2), _rule('b')],
      );

      // (8·2 + 5·1) / 3 = 7
      expect(result.score, 7);
      expect(result.coverage, 1);
      expect(result.weight, 0.3);
    });

    test('un dato que falta resta cobertura pero no nota', () {
      final result = _score(
        {'a': const MetricValue(8), 'b': const MetricValue(null)},
        [_rule('a'), _rule('b')],
      );

      expect(result.score, 8);
      expect(result.coverage, 0.5);
    });

    test('una métrica que no aplica no resta cobertura', () {
      final result = _score(
        {
          'a': const MetricValue(8),
          'b': const MetricValue.notApplicable('No aplica'),
        },
        [_rule('a'), _rule('b')],
      );

      expect(result.coverage, 1);
      expect(result.metrics.last.note, 'No aplica');
    });

    test('las métricas con peso 0 para el perfil no aparecen', () {
      final result = _score(
        {'a': const MetricValue(8), 'b': const MetricValue(2)},
        [
          _rule('a'),
          _rule('b', only: {CompanyProfile.financial}),
        ],
      );

      expect(result.metrics.map((m) => m.id), ['a']);
      expect(result.score, 8);
    });

    test('sin ninguna nota el bloque no tiene nota ni cobertura', () {
      final result = _score({}, [_rule('a')]);

      expect(result.score, isNull);
      expect(result.coverage, 0);
    });

    test('cada métrica lleva su valor, nota, peso y formato', () {
      final result = _score({'a': const MetricValue(6.66)}, [_rule('a')]);
      final metric = result.metrics.single;

      expect(metric.value, 6.66);
      expect(metric.score, 6.7);
      expect(metric.weight, 1);
      expect(metric.format, MetricFormat.decimal);
      expect(metric.label, 'A');
    });
  });
}
