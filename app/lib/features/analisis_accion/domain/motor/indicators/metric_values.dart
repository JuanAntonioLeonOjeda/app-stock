// Valor de cada métrica (por id) a partir de StockData. Solo calcula: la
// puntuación está en rules/. Fórmulas: references/metricas.md.

import 'package:stock_app/features/analisis_accion/domain/entities/balance_sheet.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/income_statement.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/stock_data.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/indicators/fundamental_ratios.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/indicators/metric_value.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/indicators/technical_indicators.dart';

const _negativeEarningsNote = 'No aplica: beneficios negativos.';
const _negativeEbitdaNote = 'No aplica: EBITDA negativo.';
const _negativeFcfNote = 'No aplica: flujo de caja libre negativo.';
const _negativeEquityNote = 'No aplica: patrimonio neto negativo.';
const _noInterestNote = 'No aplica: la empresa no tiene gastos financieros.';
const _negativeEarningsInPeriodNote =
    'No aplica: beneficio negativo al principio o al final del periodo.';
const _fourYearsNote = 'Requiere 4 años de cuentas anuales.';
const _slopeHistoryNote = 'Requiere al menos 220 sesiones de histórico.';
const _yearHistoryNote = 'Requiere un año (252 sesiones) de histórico.';

/// Valor de cada métrica de `metricRules`, por id.
Map<String, MetricValue> computeMetricValues(StockData data) {
  final inputs = _Inputs(data);
  return {
    ..._valuationValues(inputs),
    ..._healthValues(inputs),
    ..._growthValues(inputs),
    ..._technicalValues(inputs),
    ..._contextValues(inputs),
  };
}

/// Beneficio neto de los últimos 12 meses (también lo usa el detector de
/// perfil).
double? netIncomeTtm(StockData data) => _Inputs(data).netIncomeTtm;

/// Datos de partida comunes a varias métricas, calculados una sola vez.
class _Inputs {
  _Inputs(this.data)
    : closes = [for (final bar in data.dailyBars) bar.close],
      highs = [for (final bar in data.dailyBars) bar.high],
      balance =
          data.quarterlyBalance.firstOrNull ?? data.annualBalance.firstOrNull;

  final StockData data;
  final List<double> closes;
  final List<double> highs;

  /// Balance más reciente (trimestral si lo hay).
  final BalanceSheet? balance;

  double? get price => closes.lastOrNull;

  double? ttm(double? Function(IncomeStatement) field) => trailingTwelveMonths(
    quarterly: data.quarterlyIncome,
    annual: data.annualIncome,
    field: field,
  );

  double? get netIncomeTtm => ttm((s) => s.netIncome);
  double? get ebitTtm => ttm((s) => s.ebit);
  double? get ebitdaTtm => ttm((s) => s.ebitda);
  double? get revenueTtm => ttm((s) => s.totalRevenue);

  double? get fcfTtm => trailingTwelveMonths(
    quarterly: data.quarterlyCashFlow,
    annual: data.annualCashFlow,
    field: freeCashFlow,
  );

  double? get totalDebt => balance?.totalDebt;
  double? get cash => balance?.cashAndShortTermInvestments;
  double? get equity => balance?.totalShareholderEquity;

  /// Campo de la cuenta de resultados anual de hace [yearsAgo] años.
  double? annualIncome(int yearsAgo, double? Function(IncomeStatement) f) {
    final statement = data.annualIncome.elementAtOrNull(yearsAgo);
    return statement == null ? null : f(statement);
  }

  double? get revenueCagr3 => cagr(
    annualIncome(0, (s) => s.totalRevenue),
    annualIncome(3, (s) => s.totalRevenue),
    3,
  );

  bool get hasFourAnnualReports => data.annualIncome.length >= 4;
}

bool _isNotPositive(double? value) => value != null && value <= 0;

double? _positiveOrNull(double? value) =>
    value != null && value > 0 ? value : null;

Map<String, MetricValue> _valuationValues(_Inputs inputs) {
  final overview = inputs.data.overview;
  return {
    'per': _isNotPositive(inputs.netIncomeTtm)
        ? const MetricValue.notApplicable(_negativeEarningsNote)
        : MetricValue(_positiveOrNull(overview.peRatio)),
    'peg': MetricValue(_positiveOrNull(overview.pegRatio)),
    'ev_ebitda': _isNotPositive(inputs.ebitdaTtm)
        ? const MetricValue.notApplicable(_negativeEbitdaNote)
        : MetricValue(_positiveOrNull(overview.evToEbitda)),
    'p_fcf': _isNotPositive(inputs.fcfTtm)
        ? const MetricValue.notApplicable(_negativeFcfNote)
        : MetricValue(
            ratioOverPositive(overview.marketCapitalization, inputs.fcfTtm),
          ),
    'p_ventas': MetricValue(_positiveOrNull(overview.priceToSales)),
    'p_vc': MetricValue(_positiveOrNull(overview.priceToBook)),
  };
}

Map<String, MetricValue> _healthValues(_Inputs inputs) {
  final balance = inputs.balance;
  final interestTtm = inputs.ttm((s) => s.interestExpense);
  final latestCashFlow = inputs.data.annualCashFlow.firstOrNull;
  final latestFcf = latestCashFlow == null
      ? null
      : freeCashFlow(latestCashFlow);
  return {
    'deuda_ebitda': _isNotPositive(inputs.ebitdaTtm)
        ? const MetricValue.notApplicable(_negativeEbitdaNote)
        : MetricValue(
            netDebtToEbitda(
              totalDebt: inputs.totalDebt,
              cash: inputs.cash,
              ebitda: inputs.ebitdaTtm,
            ),
          ),
    'deuda_patrimonio': _isNotPositive(inputs.equity)
        ? const MetricValue.notApplicable(_negativeEquityNote)
        : MetricValue(ratioOverPositive(inputs.totalDebt, inputs.equity)),
    'liquidez': MetricValue(
      ratioOverPositive(
        balance?.totalCurrentAssets,
        balance?.totalCurrentLiabilities,
      ),
    ),
    'cobertura_intereses': interestTtm == 0
        ? const MetricValue.notApplicable(_noInterestNote)
        : MetricValue(ratioOverPositive(inputs.ebitTtm, interestTtm)),
    'fcf_positivo': MetricValue(
      positiveFreeCashFlowFraction(inputs.data.annualCashFlow),
    ),
    'payout_fcf': _isNotPositive(latestFcf)
        ? const MetricValue.notApplicable(_negativeFcfNote)
        : MetricValue(
            ratioOverPositive(latestCashFlow?.dividendPayout, latestFcf),
          ),
  };
}

Map<String, MetricValue> _growthValues(_Inputs inputs) {
  final fourYearsNote = inputs.hasFourAnnualReports ? null : _fourYearsNote;
  final netIncomeNow = inputs.annualIncome(0, (s) => s.netIncome);
  final netIncome3YearsAgo = inputs.annualIncome(3, (s) => s.netIncome);
  final operatingIncomeTtm = inputs.ttm((s) => s.operatingIncome);
  final marginNow = ratioOverPositive(
    inputs.annualIncome(0, (s) => s.operatingIncome),
    inputs.annualIncome(0, (s) => s.totalRevenue),
  );
  final margin3YearsAgo = ratioOverPositive(
    inputs.annualIncome(3, (s) => s.operatingIncome),
    inputs.annualIncome(3, (s) => s.totalRevenue),
  );
  final annualBalance = inputs.data.annualBalance;
  return {
    'ingresos_cagr3': MetricValue(inputs.revenueCagr3, note: fourYearsNote),
    'ingresos_yoy': MetricValue(
      growthRate(
        inputs.annualIncome(0, (s) => s.totalRevenue),
        inputs.annualIncome(1, (s) => s.totalRevenue),
      ),
    ),
    'beneficio_cagr3':
        _isNotPositive(netIncomeNow) || _isNotPositive(netIncome3YearsAgo)
        ? const MetricValue.notApplicable(_negativeEarningsInPeriodNote)
        : MetricValue(
            cagr(netIncomeNow, netIncome3YearsAgo, 3),
            note: fourYearsNote,
          ),
    'margen_operativo': MetricValue(
      ratioOverPositive(operatingIncomeTtm, inputs.revenueTtm),
    ),
    'margen_tendencia': MetricValue(
      marginNow == null || margin3YearsAgo == null
          ? null
          : marginNow - margin3YearsAgo,
      note: fourYearsNote,
    ),
    'margen_bruto': MetricValue(
      ratioOverPositive(inputs.ttm((s) => s.grossProfit), inputs.revenueTtm),
    ),
    'roic': MetricValue(
      returnOnInvestedCapital(
        ebit: inputs.ebitTtm,
        taxRate: effectiveTaxRate(
          incomeTaxExpense: inputs.ttm((s) => s.incomeTaxExpense),
          incomeBeforeTax: inputs.ttm((s) => s.incomeBeforeTax),
        ),
        totalDebt: inputs.totalDebt,
        equity: inputs.equity,
        cash: inputs.cash,
      ),
    ),
    'roe': _isNotPositive(inputs.equity)
        ? const MetricValue.notApplicable(_negativeEquityNote)
        : MetricValue(ratioOverPositive(inputs.netIncomeTtm, inputs.equity)),
    'dilucion': MetricValue(
      cagr(
        annualBalance.elementAtOrNull(0)?.sharesOutstanding,
        annualBalance.elementAtOrNull(3)?.sharesOutstanding,
        3,
      ),
      note: annualBalance.length >= 4 ? null : _fourYearsNote,
    ),
  };
}

Map<String, MetricValue> _technicalValues(_Inputs inputs) {
  final overview = inputs.data.overview;
  final closes = inputs.closes;
  final price = inputs.price;
  // Con menos de 200/252 sesiones, respaldo del perfil del proveedor.
  final sma200 = sma(closes, 200) ?? overview.movingAverage200;
  final high52Weeks = maxOfLast(inputs.highs) ?? overview.week52High;
  final slope = smaSlope(closes);
  final macdValues = macd(closes);
  return {
    'precio_sma200': MetricValue(growthRate(price, sma200)),
    'pendiente_sma200': MetricValue(
      slope,
      note: slope == null && closes.length < 220 ? _slopeHistoryNote : null,
    ),
    'rsi': MetricValue(rsi(closes)),
    'macd': MetricValue(
      macdValues?.histogram,
      previous: macdValues?.previousHistogram,
    ),
    'dist_maximo': MetricValue(growthRate(price, high52Weeks)),
  };
}

Map<String, MetricValue> _contextValues(_Inputs inputs) {
  final overview = inputs.data.overview;
  final drawdown = maxDrawdown(inputs.closes);
  return {
    'sorpresas_bpa': MetricValue(
      earningsBeatCount(inputs.data.quarterlyEarnings),
    ),
    'potencial_analistas': MetricValue(
      growthRate(overview.analystTargetPrice, inputs.price),
    ),
    'beta': MetricValue(overview.beta),
    'caida_maxima': MetricValue(
      drawdown,
      note: drawdown == null && inputs.closes.length < 252
          ? _yearHistoryNote
          : null,
    ),
  };
}
