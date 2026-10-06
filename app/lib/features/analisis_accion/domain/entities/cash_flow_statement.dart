/// Estado de flujos de caja de un periodo (anual o trimestral).
///
/// `null` = dato no disponible. CAPEX y dividendos pagados van en positivo,
/// sea cual sea el signo con que los devuelva el proveedor.
class CashFlowStatement {
  const CashFlowStatement({
    required this.fiscalDateEnding,
    required this.reportedCurrency,
    required this.operatingCashflow,
    required this.capitalExpenditures,
    required this.dividendPayout,
  });

  final DateTime fiscalDateEnding;
  final String? reportedCurrency;
  final double? operatingCashflow;

  /// CAPEX, en positivo.
  final double? capitalExpenditures;

  /// Dividendos pagados, en positivo.
  final double? dividendPayout;
}
