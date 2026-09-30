import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/company_overview.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/daily_bar.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/earnings_report.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/income_statement.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/stock_data.dart';

const _overview = CompanyOverview(
  symbol: 'TEST',
  name: 'Empresa de prueba',
  sector: null,
  industry: null,
  currency: 'USD',
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
);

DailyBar _bar(DateTime date) =>
    DailyBar(date: date, open: 1, high: 1, low: 1, close: 1, volume: 1);

IncomeStatement _income(DateTime date) => IncomeStatement(
  fiscalDateEnding: date,
  reportedCurrency: 'USD',
  totalRevenue: null,
  grossProfit: null,
  operatingIncome: null,
  ebit: null,
  ebitda: null,
  interestExpense: null,
  incomeBeforeTax: null,
  incomeTaxExpense: null,
  netIncome: null,
);

EarningsReport _earnings(DateTime date) => EarningsReport(
  fiscalDateEnding: date,
  reportedDate: null,
  reportedEps: null,
  estimatedEps: null,
);

StockData _stockData({
  List<DailyBar> dailyBars = const [],
  List<IncomeStatement> annualIncome = const [],
  List<EarningsReport> quarterlyEarnings = const [],
}) => StockData(
  overview: _overview,
  dailyBars: dailyBars,
  annualIncome: annualIncome,
  quarterlyIncome: const [],
  annualBalance: const [],
  quarterlyBalance: const [],
  annualCashFlow: const [],
  quarterlyCashFlow: const [],
  quarterlyEarnings: quarterlyEarnings,
  fetchedAt: DateTime(2026, 9, 30),
);

void main() {
  final jan = DateTime(2026, 1, 1);
  final feb = DateTime(2026, 2, 1);
  final mar = DateTime(2026, 3, 1);

  group('StockData', () {
    test('ordena el histórico diario del más antiguo al más reciente', () {
      final data = _stockData(dailyBars: [_bar(mar), _bar(jan), _bar(feb)]);

      expect(data.dailyBars.map((b) => b.date), [jan, feb, mar]);
    });

    test('ordena los informes del más reciente al más antiguo', () {
      final data = _stockData(
        annualIncome: [_income(feb), _income(mar), _income(jan)],
        quarterlyEarnings: [_earnings(jan), _earnings(mar), _earnings(feb)],
      );

      expect(data.annualIncome.map((s) => s.fiscalDateEnding), [mar, feb, jan]);
      expect(data.quarterlyEarnings.map((r) => r.fiscalDateEnding), [
        mar,
        feb,
        jan,
      ]);
    });

    test('no modifica la lista que recibe', () {
      final bars = [_bar(mar), _bar(jan)];

      _stockData(dailyBars: bars);

      expect(bars.map((b) => b.date), [mar, jan]);
    });

    test('expone listas inmutables', () {
      final data = _stockData(dailyBars: [_bar(jan)]);

      expect(() => data.dailyBars.add(_bar(feb)), throwsUnsupportedError);
    });
  });
}
