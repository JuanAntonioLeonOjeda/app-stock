import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/indicators/metric_value.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/rules/metric_rule.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/scoring/piecewise_scale.dart';

const _scale = ScaleScoring([ScorePoint(0, 0), ScorePoint(3, 10)]);

double? _alwaysNull(MetricValue value) => null;

void main() {
  group('MetricRule.weightFor', () {
    const rule = MetricRule(
      id: 'test',
      block: Block.valuation,
      label: 'Test',
      format: MetricFormat.decimal,
      scoring: _scale,
      weight: 1.5,
      profileWeights: {CompanyProfile.growth: 0.3, CompanyProfile.financial: 0},
    );

    test('usa el peso por defecto si el perfil no tiene uno propio', () {
      expect(rule.weightFor(CompanyProfile.general), 1.5);
    });

    test('usa el peso propio del perfil', () {
      expect(rule.weightFor(CompanyProfile.growth), 0.3);
      expect(rule.weightFor(CompanyProfile.financial), 0);
    });

    test('pesa 0 para perfiles fuera de onlyFor', () {
      const onlyGrowth = MetricRule(
        id: 'test',
        block: Block.valuation,
        label: 'Test',
        format: MetricFormat.decimal,
        scoring: _scale,
        weight: 1.5,
        onlyFor: {CompanyProfile.growth},
      );

      expect(onlyGrowth.weightFor(CompanyProfile.general), 0);
      expect(onlyGrowth.weightFor(CompanyProfile.growth), 1.5);
    });
  });

  group('MetricRule.score', () {
    const rule = MetricRule(
      id: 'test',
      block: Block.valuation,
      label: 'Test',
      format: MetricFormat.decimal,
      scoring: _scale,
    );

    test('puntúa con la escala y redondea a un decimal', () {
      // 1 sobre la escala 0→0, 3→10 = 3,333...
      expect(rule.score(const MetricValue(1)), 3.3);
    });

    test('no puntúa si no hay valor', () {
      expect(rule.score(const MetricValue(null)), isNull);
      expect(rule.score(const MetricValue.notApplicable('No aplica')), isNull);
    });

    test('devuelve null si la función propia no puede puntuar', () {
      const custom = MetricRule(
        id: 'test',
        block: Block.technical,
        label: 'Test',
        format: MetricFormat.decimal,
        scoring: CustomScoring(_alwaysNull),
      );

      expect(custom.score(const MetricValue(1)), isNull);
    });
  });
}
