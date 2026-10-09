import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/rules/verdict_thresholds.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/scoring/piecewise_scale.dart';

/// Veredicto, nota global y confianza de un análisis.
class VerdictOutcome {
  const VerdictOutcome({
    required this.verdict,
    required this.globalScore,
    required this.confidence,
    required this.isCappedByHealth,
  });

  final Verdict verdict;
  final double? globalScore;
  final Confidence confidence;

  /// El veredicto habría sido `favorable`, pero la salud débil lo limita a
  /// `neutral`.
  final bool isCappedByHealth;
}

/// Calcula el veredicto a partir de los bloques ya puntuados.
VerdictOutcome calculateVerdict({
  required List<BlockResult> blocks,
  required DateTime? lastCloseDate,
  required DateTime referenceDate,
}) {
  final scoredBlocks = blocks.where((b) => b.score != null).toList();
  if (scoredBlocks.length < minScoredBlocks) {
    return const VerdictOutcome(
      verdict: Verdict.insufficientData,
      globalScore: null,
      confidence: Confidence.low,
      isCappedByHealth: false,
    );
  }

  final globalScore = roundToTenth(_weightedMeanScore(scoredBlocks));
  final uncappedVerdict = _verdictFor(globalScore);
  final isCappedByHealth =
      uncappedVerdict == Verdict.favorable && _isHealthWeak(blocks);
  return VerdictOutcome(
    verdict: isCappedByHealth ? Verdict.neutral : uncappedVerdict,
    globalScore: globalScore,
    confidence: _confidence(blocks, lastCloseDate, referenceDate),
    isCappedByHealth: isCappedByHealth,
  );
}

/// Media ponderada de las notas, renormalizando los pesos de los bloques con
/// nota.
double _weightedMeanScore(List<BlockResult> scoredBlocks) {
  var weightedSum = 0.0;
  var totalWeight = 0.0;
  for (final block in scoredBlocks) {
    final score = block.score;
    if (score == null) continue;
    weightedSum += score * block.weight;
    totalWeight += block.weight;
  }
  return weightedSum / totalWeight;
}

Verdict _verdictFor(double globalScore) {
  if (globalScore >= favorableMinScore) return Verdict.favorable;
  if (globalScore >= neutralMinScore) return Verdict.neutral;
  return Verdict.unfavorable;
}

bool _isHealthWeak(List<BlockResult> blocks) {
  final healthScore = blocks
      .where((b) => b.block == Block.health)
      .firstOrNull
      ?.score;
  return healthScore != null && healthScore < healthCapScore;
}

Confidence _confidence(
  List<BlockResult> blocks,
  DateTime? lastCloseDate,
  DateTime referenceDate,
) {
  final isPriceStale =
      lastCloseDate == null ||
      referenceDate.difference(lastCloseDate) > maxPriceAge;
  if (isPriceStale) return Confidence.low;

  final coverage = _weightedCoverage(blocks);
  final areAllBlocksScored =
      blocks.length == Block.values.length &&
      blocks.every((b) => b.score != null);
  if (coverage >= highConfidenceMinCoverage && areAllBlocksScored) {
    return Confidence.high;
  }
  if (coverage >= mediumConfidenceMinCoverage) return Confidence.medium;
  return Confidence.low;
}

/// Cobertura media de los bloques, ponderada por su peso.
double _weightedCoverage(List<BlockResult> blocks) {
  final totalWeight = blocks.fold(0.0, (sum, b) => sum + b.weight);
  if (totalWeight == 0) return 0;
  return blocks.fold(0.0, (sum, b) => sum + b.weight * b.coverage) /
      totalWeight;
}
