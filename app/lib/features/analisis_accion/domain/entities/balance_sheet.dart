/// Balance de un periodo (anual o trimestral).
///
/// `null` = dato no disponible. Deuda y caja llegan ya resueltas por el
/// adapter del proveedor (con sus campos de respaldo), así que el motor no
/// necesita conocer los nombres de campo de la API.
class BalanceSheet {
  const BalanceSheet({
    required this.fiscalDateEnding,
    required this.reportedCurrency,
    required this.totalCurrentAssets,
    required this.totalCurrentLiabilities,
    required this.totalShareholderEquity,
    required this.totalDebt,
    required this.cashAndShortTermInvestments,
    required this.sharesOutstanding,
  });

  final DateTime fiscalDateEnding;
  final String? reportedCurrency;
  final double? totalCurrentAssets;
  final double? totalCurrentLiabilities;

  /// Puede ser negativo (patrimonio neto negativo es una señal de alarma).
  final double? totalShareholderEquity;
  final double? totalDebt;
  final double? cashAndShortTermInvestments;
  final double? sharesOutstanding;
}
