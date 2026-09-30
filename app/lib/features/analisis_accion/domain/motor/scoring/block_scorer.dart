import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/indicators/metric_value.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/rules/metric_rule.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/rules/metric_rules.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/scoring/piecewise_scale.dart';

/// Puntúa las métricas de [block] activas para [profile] (peso > 0).
///
/// - Nota del bloque = media ponderada de las métricas con nota.
/// - Cobertura = peso con nota / peso de las métricas aplicables. Las que
///   "no aplican" (p. ej. PER con pérdidas) no restan cobertura: no son
///   datos que falten.
BlockResult scoreBlock({
  required Block block,
  required double blockWeight,
  required CompanyProfile profile,
  required Map<String, MetricValue> values,
  List<MetricRule> rules = metricRules,
}) {
  final metrics = <MetricResult>[];
  var weightedScoreSum = 0.0;
  var scoredWeight = 0.0;
  var applicableWeight = 0.0;

  for (final rule in rules.where((r) => r.block == block)) {
    final weight = rule.weightFor(profile);
    if (weight == 0) continue;
    final value = values[rule.id] ?? const MetricValue(null);
    final score = rule.score(value);
    metrics.add(_metricResult(rule, value, score, weight));
    if (!value.isNotApplicable) applicableWeight += weight;
    if (score != null) {
      weightedScoreSum += score * weight;
      scoredWeight += weight;
    }
  }

  return BlockResult(
    block: block,
    score: scoredWeight == 0
        ? null
        : roundToTenth(weightedScoreSum / scoredWeight),
    weight: blockWeight,
    coverage: applicableWeight == 0 ? 0 : scoredWeight / applicableWeight,
    metrics: metrics,
  );
}

MetricResult _metricResult(
  MetricRule rule,
  MetricValue value,
  double? score,
  double weight,
) => MetricResult(
  id: rule.id,
  label: rule.label,
  value: value.value,
  format: rule.format,
  score: score,
  weight: weight,
  note: value.note,
);
