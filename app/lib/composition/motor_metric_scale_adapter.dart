import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/rules/metric_rule.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/rules/metric_rules.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/reading_scale.dart';
import 'package:stock_app/features/contenido_educativo/domain/ports/metric_scale_port.dart';

/// Da a `contenido_educativo` las escalas reales del motor.
///
/// Vive en `composition/` porque es el único código, junto con `app.dart`, que
/// puede conocer las dos features: así la ficha dibuja la escala vigente y no
/// una copia de los umbrales que se desincronizaría al cambiar el motor.
class MotorMetricScaleAdapter implements MetricScalePort {
  const MotorMetricScaleAdapter();

  @override
  ReadingScale? scaleFor(String metricId) {
    final rule = _ruleFor(metricId);
    if (rule == null) return null;
    return switch (rule.scoring) {
      ScaleScoring(:final points) => ReadingScale(
        points: [for (final p in points) ScalePoint(p.value, p.score)],
        unit: _unitOf(rule.format),
      ),
      CustomScoring() => null,
    };
  }

  MetricRule? _ruleFor(String metricId) {
    for (final rule in metricRules) {
      if (rule.id == metricId) return rule;
    }
    return null;
  }

  ScaleUnit _unitOf(MetricFormat format) => switch (format) {
    MetricFormat.multiple => ScaleUnit.multiple,
    MetricFormat.percent => ScaleUnit.fraction,
    _ => ScaleUnit.decimal,
  };
}
