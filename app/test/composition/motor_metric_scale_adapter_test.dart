import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/composition/motor_metric_scale_adapter.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/rules/metric_rule.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/rules/metric_rules.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/rules/verdict_thresholds.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/reading_scale.dart';

void main() {
  group('MotorMetricScaleAdapter', () {
    const adapter = MotorMetricScaleAdapter();

    test('la escala del PER coincide punto por punto con la del motor', () {
      final motorRule = metricRules.firstWhere((rule) => rule.id == 'per');
      final motorPoints = (motorRule.scoring as ScaleScoring).points;

      final scale = adapter.scaleFor('per')!;

      expect(scale.unit, ScaleUnit.multiple);
      expect(scale.points.map((p) => (p.value, p.score)), [
        for (final p in motorPoints) (p.value, p.score),
      ]);
    });

    test(
      'los cortes de color son los mismos que usa el semáforo del motor',
      () {
        final scale = adapter.scaleFor('per')!;

        expect(scale.favorableFrom, favorableMinScore);
        expect(scale.neutralFrom, neutralMinScore);
      },
    );

    test('una métrica en porcentaje se expresa como fracción', () {
      expect(adapter.scaleFor('margen_operativo')!.unit, ScaleUnit.fraction);
    });

    test('una métrica sin escala por tramos (MACD) devuelve null', () {
      expect(adapter.scaleFor('macd'), isNull);
    });

    test('un id desconocido devuelve null', () {
      expect(adapter.scaleFor('no_existe'), isNull);
    });

    test('toda métrica con escala del motor tiene al menos dos puntos', () {
      for (final rule in metricRules) {
        final scale = adapter.scaleFor(rule.id);
        if (scale != null) {
          expect(scale.points.length, greaterThanOrEqualTo(2), reason: rule.id);
        }
      }
    });
  });
}
