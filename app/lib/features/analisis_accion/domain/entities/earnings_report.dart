/// Resultados de un trimestre: BPA real frente al estimado por analistas.
class EarningsReport {
  const EarningsReport({
    required this.fiscalDateEnding,
    required this.reportedDate,
    required this.reportedEps,
    required this.estimatedEps,
  });

  final DateTime fiscalDateEnding;

  /// Fecha de publicación de los resultados.
  final DateTime? reportedDate;
  final double? reportedEps;
  final double? estimatedEps;
}
