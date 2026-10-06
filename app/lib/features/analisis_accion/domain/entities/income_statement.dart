/// Cuenta de resultados de un periodo (anual o trimestral).
///
/// `null` = dato no disponible. Los gastos van en positivo.
class IncomeStatement {
  const IncomeStatement({
    required this.fiscalDateEnding,
    required this.reportedCurrency,
    required this.totalRevenue,
    required this.grossProfit,
    required this.operatingIncome,
    required this.ebit,
    required this.ebitda,
    required this.interestExpense,
    required this.incomeBeforeTax,
    required this.incomeTaxExpense,
    required this.netIncome,
  });

  final DateTime fiscalDateEnding;
  final String? reportedCurrency;
  final double? totalRevenue;
  final double? grossProfit;
  final double? operatingIncome;
  final double? ebit;
  final double? ebitda;

  /// Gastos financieros, en positivo.
  final double? interestExpense;
  final double? incomeBeforeTax;
  final double? incomeTaxExpense;
  final double? netIncome;
}
