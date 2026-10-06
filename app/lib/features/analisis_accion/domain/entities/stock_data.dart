import 'package:stock_app/features/analisis_accion/domain/entities/balance_sheet.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/cash_flow_statement.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/company_overview.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/daily_bar.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/earnings_report.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/income_statement.dart';

/// Todos los datos de una acción, normalizados e independientes del
/// proveedor. Es la única entrada del motor.
///
/// Garantiza el orden que el motor da por hecho, lo reciba como lo reciba:
/// histórico diario ascendente (más antiguo primero) e informes del más
/// reciente al más antiguo. Todas las listas son inmutables.
class StockData {
  StockData({
    required this.overview,
    required List<DailyBar> dailyBars,
    required List<IncomeStatement> annualIncome,
    required List<IncomeStatement> quarterlyIncome,
    required List<BalanceSheet> annualBalance,
    required List<BalanceSheet> quarterlyBalance,
    required List<CashFlowStatement> annualCashFlow,
    required List<CashFlowStatement> quarterlyCashFlow,
    required List<EarningsReport> quarterlyEarnings,
    required this.fetchedAt,
  }) : dailyBars = _sortedByDate(dailyBars, (b) => b.date, newestFirst: false),
       annualIncome = _newestFirst(annualIncome, (s) => s.fiscalDateEnding),
       quarterlyIncome = _newestFirst(
         quarterlyIncome,
         (s) => s.fiscalDateEnding,
       ),
       annualBalance = _newestFirst(annualBalance, (s) => s.fiscalDateEnding),
       quarterlyBalance = _newestFirst(
         quarterlyBalance,
         (s) => s.fiscalDateEnding,
       ),
       annualCashFlow = _newestFirst(annualCashFlow, (s) => s.fiscalDateEnding),
       quarterlyCashFlow = _newestFirst(
         quarterlyCashFlow,
         (s) => s.fiscalDateEnding,
       ),
       quarterlyEarnings = _newestFirst(
         quarterlyEarnings,
         (r) => r.fiscalDateEnding,
       );

  final CompanyOverview overview;
  final List<DailyBar> dailyBars;
  final List<IncomeStatement> annualIncome;
  final List<IncomeStatement> quarterlyIncome;
  final List<BalanceSheet> annualBalance;
  final List<BalanceSheet> quarterlyBalance;
  final List<CashFlowStatement> annualCashFlow;
  final List<CashFlowStatement> quarterlyCashFlow;
  final List<EarningsReport> quarterlyEarnings;

  /// Momento en que se obtuvieron los datos del proveedor.
  final DateTime fetchedAt;

  static List<T> _newestFirst<T>(List<T> items, DateTime Function(T) dateOf) =>
      _sortedByDate(items, dateOf, newestFirst: true);

  static List<T> _sortedByDate<T>(
    List<T> items,
    DateTime Function(T) dateOf, {
    required bool newestFirst,
  }) {
    final sorted = [...items]
      ..sort((a, b) {
        final ascending = dateOf(a).compareTo(dateOf(b));
        return newestFirst ? -ascending : ascending;
      });
    return List.unmodifiable(sorted);
  }
}
