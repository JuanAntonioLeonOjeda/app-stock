import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/stock_data.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/indicators/metric_value.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/indicators/metric_values.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/motor_version.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/rules/block_weights.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/scoring/block_scorer.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/scoring/flag_detector.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/scoring/profile_detector.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/scoring/verdict_calculator.dart';

/// Punto de entrada del motor: `StockData` → `AnalysisResult`.
///
/// Determinista: sin reloj del sistema ni aleatoriedad. La fecha de
/// referencia (el "hoy" del análisis) se recibe como parámetro.
class StockAnalyzer {
  const StockAnalyzer();

  AnalysisResult analyze(
    StockData data, {
    required DateTime referenceDate,
    Horizon horizon = Horizon.longTerm,
  }) {
    final values = computeMetricValues(data);
    final profile = _detectProfile(data, values);
    final weights = blockWeightsFor(horizon);
    final blocks = [
      for (final block in Block.values)
        scoreBlock(
          block: block,
          blockWeight: weights[block] ?? 0,
          profile: profile,
          values: values,
        ),
    ];
    final lastBar = data.dailyBars.lastOrNull;
    final outcome = calculateVerdict(
      blocks: blocks,
      lastCloseDate: lastBar?.date,
      referenceDate: referenceDate,
    );

    return AnalysisResult(
      symbol: data.overview.symbol,
      name: data.overview.name,
      currency: data.overview.currency,
      price: lastBar?.close,
      lastCloseDate: lastBar?.date,
      lastFiscalPeriod: _lastFiscalPeriod(data),
      profile: profile,
      horizon: horizon,
      verdict: outcome.verdict,
      globalScore: outcome.globalScore,
      confidence: outcome.confidence,
      blocks: blocks,
      flags: detectFlags(
        data: data,
        values: values,
        isVerdictCappedByHealth: outcome.isCappedByHealth,
        referenceDate: referenceDate,
      ),
      missingData: _missingData(blocks, values),
      motorVersion: motorVersion,
      isin: data.overview.isin,
      exchange: data.overview.exchange,
      isPrimaryListing: data.overview.isPrimaryListing,
    );
  }

  CompanyProfile _detectProfile(
    StockData data,
    Map<String, MetricValue> values,
  ) => detectProfile(
    sector: data.overview.sector,
    industry: data.overview.industry,
    netIncomeTtm: netIncomeTtm(data),
    revenueCagr3: values['ingresos_cagr3']?.value,
    dividendYield: data.overview.dividendYield,
  );

  DateTime? _lastFiscalPeriod(StockData data) =>
      data.quarterlyIncome.firstOrNull?.fiscalDateEnding ??
      data.annualIncome.firstOrNull?.fiscalDateEnding ??
      data.overview.latestQuarter;

  /// Etiquetas de las métricas usadas que no tienen dato (las que "no
  /// aplican" no cuentan).
  List<String> _missingData(
    List<BlockResult> blocks,
    Map<String, MetricValue> values,
  ) => [
    for (final block in blocks)
      for (final metric in block.metrics)
        if (values[metric.id]?.isMissing ?? true) metric.label,
  ];
}
