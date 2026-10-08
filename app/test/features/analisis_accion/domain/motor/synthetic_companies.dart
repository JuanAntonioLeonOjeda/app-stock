// Empresas sintéticas para los tests del motor (sin red). Los valores por
// defecto de buildCompany describen una empresa "de calidad"; ver
// fragileCompany para la contraria. Importes en millones.

import 'dart:math' as math;

import 'package:stock_app/features/analisis_accion/domain/entities/balance_sheet.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/cash_flow_statement.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/company_overview.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/daily_bar.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/earnings_report.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/income_statement.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/stock_data.dart';

/// "Hoy" en todos los tests del motor.
final referenceDate = DateTime(2026, 9, 30);

const _taxRate = 0.21;

final _quarterEnds = [
  DateTime(2026, 6, 30),
  DateTime(2026, 3, 31),
  DateTime(2025, 12, 31),
  DateTime(2025, 9, 30),
];

DateTime _yearEnd(int yearsAgo) => DateTime(2025 - yearsAgo, 12, 31);

/// Histórico diario determinista: tendencia `dailyDrift` más una oscilación
/// senoidal de amplitud `wiggle` (para que haya días de bajada).
List<DailyBar> priceHistory({
  int sessions = 300,
  double startPrice = 100,
  double dailyDrift = 0.0008,
  double wiggle = 0.01,
  DateTime? lastDate,
}) {
  final last = lastDate ?? referenceDate.subtract(const Duration(days: 1));
  return [
    for (var i = 0; i < sessions; i++)
      _bar(
        last.subtract(Duration(days: sessions - 1 - i)),
        startPrice *
            math.pow(1 + dailyDrift, i).toDouble() *
            (1 + wiggle * math.sin(i * 0.9)),
      ),
  ];
}

DailyBar _bar(DateTime date, double close) => DailyBar(
  date: date,
  open: close,
  high: close * 1.005,
  low: close * 0.995,
  close: close,
  volume: 1000000,
);

CompanyOverview overview({
  String symbol = 'CALI',
  String name = 'Calidad S.A.',
  String? sector = 'TECHNOLOGY',
  String? industry = 'SOFTWARE',
  String? currency = 'USD',
  double? marketCapitalization = 3780,
  double? sharesOutstanding = 29.1,
  double? peRatio = 14,
  double? pegRatio = 0.9,
  double? priceToBook = 2.5,
  double? priceToSales = 2.7,
  double? evToEbitda = 9,
  double? beta = 0.9,
  double? dividendYield = 0.013,
  double? analystTargetPrice = 150,
  double? movingAverage200,
  double? week52High,
  String? isin,
  String? exchange,
  bool? isPrimaryListing,
}) => CompanyOverview(
  symbol: symbol,
  name: name,
  sector: sector,
  industry: industry,
  currency: currency,
  latestQuarter: _quarterEnds.first,
  marketCapitalization: marketCapitalization,
  sharesOutstanding: sharesOutstanding,
  peRatio: peRatio,
  forwardPe: null,
  pegRatio: pegRatio,
  priceToBook: priceToBook,
  priceToSales: priceToSales,
  evToEbitda: evToEbitda,
  beta: beta,
  dividendYield: dividendYield,
  analystTargetPrice: analystTargetPrice,
  movingAverage50: null,
  movingAverage200: movingAverage200,
  week52High: week52High,
  week52Low: null,
  isin: isin,
  exchange: exchange,
  isPrimaryListing: isPrimaryListing,
);

/// Construye una empresa completa. Listas anuales del año más reciente al
/// más antiguo. La cuenta de resultados se deriva: EBIT = resultado
/// operativo, EBITDA = EBIT + [depreciation], BAI = EBIT − intereses,
/// impuestos = 21 % del BAI positivo. Los 4 trimestres reparten a partes
/// iguales el último año.
StockData buildCompany({
  CompanyOverview? companyOverview,
  List<DailyBar>? dailyBars,
  List<double> annualRevenue = const [1405, 1254, 1120, 1000],
  List<double> annualOperatingIncome = const [351, 300, 260, 220],
  double depreciation = 50,
  double interestExpense = 10,
  List<double> annualOperatingCashflow = const [330, 290, 250, 220, 200],
  List<double> annualCapex = const [60, 55, 50, 45, 40],
  double dividendPayout = 50,
  List<double> annualShares = const [29.1, 29.4, 29.7, 30],
  double totalDebt = 200,
  double cash = 300,
  double equity = 1500,
  double currentAssets = 900,
  double currentLiabilities = 450,
  List<(double, double)> earnings = const [
    (1.1, 1),
    (1.2, 1.1),
    (1.05, 1),
    (1.3, 1.2),
  ],
  DateTime? lastEarningsReportedDate,
}) {
  final annualIncome = [
    for (var i = 0; i < annualRevenue.length; i++)
      _income(
        _yearEnd(i),
        revenue: annualRevenue[i],
        operatingIncome: annualOperatingIncome[i],
        depreciation: depreciation,
        interest: interestExpense,
      ),
  ];
  final annualCashFlow = [
    for (var i = 0; i < annualOperatingCashflow.length; i++)
      _cashFlow(
        _yearEnd(i),
        operating: annualOperatingCashflow[i],
        capex: annualCapex[i],
        dividends: dividendPayout,
      ),
  ];
  final latestBalance = BalanceSheet(
    fiscalDateEnding: _quarterEnds.first,
    reportedCurrency: 'USD',
    totalCurrentAssets: currentAssets,
    totalCurrentLiabilities: currentLiabilities,
    totalShareholderEquity: equity,
    totalDebt: totalDebt,
    cashAndShortTermInvestments: cash,
    sharesOutstanding: annualShares.first,
  );
  return StockData(
    overview: companyOverview ?? overview(),
    dailyBars: dailyBars ?? priceHistory(),
    annualIncome: annualIncome,
    quarterlyIncome: [
      for (final quarterEnd in _quarterEnds)
        _income(
          quarterEnd,
          revenue: annualRevenue.first / 4,
          operatingIncome: annualOperatingIncome.first / 4,
          depreciation: depreciation / 4,
          interest: interestExpense / 4,
        ),
    ],
    annualBalance: [
      for (var i = 0; i < annualShares.length; i++)
        BalanceSheet(
          fiscalDateEnding: _yearEnd(i),
          reportedCurrency: 'USD',
          totalCurrentAssets: currentAssets,
          totalCurrentLiabilities: currentLiabilities,
          totalShareholderEquity: equity,
          totalDebt: totalDebt,
          cashAndShortTermInvestments: cash,
          sharesOutstanding: annualShares[i],
        ),
    ],
    quarterlyBalance: [latestBalance],
    annualCashFlow: annualCashFlow,
    quarterlyCashFlow: [
      for (final quarterEnd in _quarterEnds)
        _cashFlow(
          quarterEnd,
          operating: annualOperatingCashflow.first / 4,
          capex: annualCapex.first / 4,
          dividends: dividendPayout / 4,
        ),
    ],
    quarterlyEarnings: [
      for (var i = 0; i < earnings.length; i++)
        EarningsReport(
          fiscalDateEnding: _quarterEnds[i],
          reportedDate: i == 0
              ? lastEarningsReportedDate ?? DateTime(2026, 8, 1)
              : _quarterEnds[i].add(const Duration(days: 30)),
          reportedEps: earnings[i].$1,
          estimatedEps: earnings[i].$2,
        ),
    ],
    fetchedAt: referenceDate,
  );
}

IncomeStatement _income(
  DateTime date, {
  required double revenue,
  required double operatingIncome,
  required double depreciation,
  required double interest,
}) {
  final incomeBeforeTax = operatingIncome - interest;
  final tax = incomeBeforeTax > 0 ? incomeBeforeTax * _taxRate : 0.0;
  return IncomeStatement(
    fiscalDateEnding: date,
    reportedCurrency: 'USD',
    totalRevenue: revenue,
    grossProfit: revenue * 0.6,
    operatingIncome: operatingIncome,
    ebit: operatingIncome,
    ebitda: operatingIncome + depreciation,
    interestExpense: interest,
    incomeBeforeTax: incomeBeforeTax,
    incomeTaxExpense: tax,
    netIncome: incomeBeforeTax - tax,
  );
}

CashFlowStatement _cashFlow(
  DateTime date, {
  required double operating,
  required double capex,
  required double dividends,
}) => CashFlowStatement(
  fiscalDateEnding: date,
  reportedCurrency: 'USD',
  operatingCashflow: operating,
  capitalExpenditures: capex,
  dividendPayout: dividends,
);

/// Empresa de calidad en tendencia alcista: debe salir `favorable`.
StockData qualityCompany() => buildCompany();

/// Empresa frágil: deuda alta, dilución, ventas cayendo, márgenes bajos y
/// tendencia bajista. Debe salir `desfavorable`.
StockData fragileCompany() => buildCompany(
  companyOverview: overview(
    symbol: 'FRAG',
    name: 'Frágil S.A.',
    industry: 'RETAIL',
    sector: 'CONSUMER CYCLICAL',
    marketCapitalization: 2300,
    sharesOutstanding: 36,
    peRatio: 45,
    pegRatio: 3.5,
    priceToBook: 5,
    priceToSales: 2,
    evToEbitda: 25,
    beta: 1.9,
    dividendYield: 0,
    analystTargetPrice: 55,
  ),
  dailyBars: priceHistory(dailyDrift: -0.0015),
  annualRevenue: const [1100, 1200, 1300, 1400],
  annualOperatingIncome: const [44, 60, 78, 98],
  depreciation: 60,
  interestExpense: 35,
  annualOperatingCashflow: const [80, 90, 100, 110, 120],
  annualCapex: const [100, 95, 60, 70, 50],
  dividendPayout: 0,
  annualShares: const [36, 33, 30, 28],
  totalDebt: 900,
  cash: 50,
  equity: 250,
  currentAssets: 300,
  currentLiabilities: 400,
  earnings: const [(0.1, 0.2), (0.2, 0.3), (0.3, 0.35), (0.4, 0.5)],
);

/// Empresa sin ningún dato.
StockData emptyCompany() => StockData(
  overview: const CompanyOverview(
    symbol: 'VACIA',
    name: 'Vacía S.A.',
    sector: null,
    industry: null,
    currency: null,
    latestQuarter: null,
    marketCapitalization: null,
    sharesOutstanding: null,
    peRatio: null,
    forwardPe: null,
    pegRatio: null,
    priceToBook: null,
    priceToSales: null,
    evToEbitda: null,
    beta: null,
    dividendYield: null,
    analystTargetPrice: null,
    movingAverage50: null,
    movingAverage200: null,
    week52High: null,
    week52Low: null,
  ),
  dailyBars: const [],
  annualIncome: const [],
  quarterlyIncome: const [],
  annualBalance: const [],
  quarterlyBalance: const [],
  annualCashFlow: const [],
  quarterlyCashFlow: const [],
  quarterlyEarnings: const [],
  fetchedAt: referenceDate,
);
