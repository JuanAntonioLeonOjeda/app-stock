import 'package:stock_app/features/analisis_accion/domain/entities/stock_data.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/indicators/fundamental_ratios.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/indicators/metric_value.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/rules/flag_rules.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/rules/verdict_thresholds.dart';

/// Avisos listos para mostrar: veredicto limitado, calidad de los datos y
/// señales de alarma (references/metricas.md, sección 7).
List<String> detectFlags({
  required StockData data,
  required Map<String, MetricValue> values,
  required bool isVerdictCappedByHealth,
  required DateTime referenceDate,
}) {
  final currencyMismatch = _currencyMismatchText(data);
  return [
    if (isVerdictCappedByHealth) verdictCappedByHealthText,
    if (_isPriceStale(data, referenceDate)) stalePriceText,
    ?_historyText(data),
    if (_isLatestQuarterStale(data, referenceDate)) staleQuarterText,
    if (_isMarketCapInconsistent(data)) marketCapMismatchText,
    ?currencyMismatch,
    if (_areEarningsSoon(data, referenceDate)) earningsSoonText,
    if (_isProfitUpWhileCashDown(data)) profitUpCashDownText,
    if (_isQuarterlyMarginFalling(data)) fallingQuarterlyMarginText,
    if (_exceeds(values['dilucion'], dilutionAlarmMin)) dilutionAlarmText,
    if (_exceeds(values['deuda_ebitda'], netDebtToEbitdaAlarmMin))
      netDebtToEbitdaAlarmText,
    if (_hasNegativeEquity(data)) negativeEquityText,
    if (_isAbove(data.overview.dividendYield, dividendYieldAlarmMin))
      dividendYieldAlarmText,
  ];
}

bool _exceeds(MetricValue? metric, double threshold) =>
    _isAbove(metric?.value, threshold);

bool _isAbove(double? value, double threshold) =>
    value != null && value > threshold;

/// Una sola barra = el proveedor no da histórico diario, solo el último cierre.
String? _historyText(StockData data) {
  final sessions = data.dailyBars.length;
  if (sessions <= 1) return noPriceHistoryText;
  return sessions < minSessionsForOwnAverages ? shortHistoryText : null;
}

bool _isPriceStale(StockData data, DateTime referenceDate) {
  final lastClose = data.dailyBars.lastOrNull;
  return lastClose != null &&
      referenceDate.difference(lastClose.date) > maxPriceAge;
}

bool _isLatestQuarterStale(StockData data, DateTime referenceDate) {
  final latestQuarter =
      data.quarterlyIncome.firstOrNull?.fiscalDateEnding ??
      data.overview.latestQuarter;
  return latestQuarter != null &&
      referenceDate.difference(latestQuarter) > maxQuarterAge;
}

bool _isMarketCapInconsistent(StockData data) {
  final marketCap = data.overview.marketCapitalization;
  final shares = data.overview.sharesOutstanding;
  final price = data.dailyBars.lastOrNull?.close;
  if (marketCap == null || shares == null || price == null) return false;
  final deviation = growthRate(price * shares, marketCap);
  return deviation != null && deviation.abs() > marketCapMismatchMax;
}

String? _currencyMismatchText(StockData data) {
  final reportCurrency = data.annualIncome.firstOrNull?.reportedCurrency;
  final quoteCurrency = data.overview.currency;
  if (reportCurrency == null || quoteCurrency == null) return null;
  if (reportCurrency.toUpperCase() == quoteCurrency.toUpperCase()) return null;
  return currencyMismatchText(reportCurrency, quoteCurrency);
}

/// Próxima publicación estimada = última publicación + 91 días.
bool _areEarningsSoon(StockData data, DateTime referenceDate) {
  final lastReported = data.quarterlyEarnings.firstOrNull?.reportedDate;
  if (lastReported == null) return false;
  final estimatedNext = lastReported.add(estimatedEarningsInterval);
  return !estimatedNext.isBefore(referenceDate) &&
      !estimatedNext.isAfter(referenceDate.add(earningsSoonWindow));
}

/// Beneficio neto sube 2 años seguidos mientras el FCF baja 2 años seguidos.
bool _isProfitUpWhileCashDown(StockData data) {
  final netIncomes = data.annualIncome.take(3).map((s) => s.netIncome);
  final fcfs = data.annualCashFlow.take(3).map(freeCashFlow);
  return _hasRisenOverTime(netIncomes) && _hasFallenOverTime(fcfs);
}

/// Margen operativo trimestral cae 3 trimestres seguidos.
bool _isQuarterlyMarginFalling(StockData data) {
  final margins = data.quarterlyIncome
      .take(4)
      .map((s) => ratioOverPositive(s.operatingIncome, s.totalRevenue));
  return margins.length == 4 && _hasFallenOverTime(margins);
}

bool _hasNegativeEquity(StockData data) {
  final balance =
      data.quarterlyBalance.firstOrNull ?? data.annualBalance.firstOrNull;
  final equity = balance?.totalShareholderEquity;
  return equity != null && equity < 0;
}

/// Cada valor es mayor que el del periodo anterior. [newestFirst] va del
/// más reciente al más antiguo; hacen falta al menos 3 valores y ninguno null.
bool _hasRisenOverTime(Iterable<double?> newestFirst) =>
    _holdsForEachPeriod(newestFirst, (newer, older) => newer > older);

/// Cada valor es menor que el del periodo anterior.
bool _hasFallenOverTime(Iterable<double?> newestFirst) =>
    _holdsForEachPeriod(newestFirst, (newer, older) => newer < older);

bool _holdsForEachPeriod(
  Iterable<double?> newestFirst,
  bool Function(double newer, double older) holds,
) {
  final values = newestFirst.toList();
  if (values.length < 3 || values.contains(null)) return false;
  final present = values.whereType<double>().toList();
  for (var i = 0; i < present.length - 1; i++) {
    if (!holds(present[i], present[i + 1])) return false;
  }
  return true;
}
