/// Una coincidencia de la búsqueda de símbolos: una cotización concreta de una
/// empresa en una bolsa.
class SymbolMatch {
  const SymbolMatch({
    required this.symbol,
    required this.name,
    required this.region,
    required this.currency,
    required this.matchScore,
    this.isin,
    this.exchange = '',
    this.exchangeName = '',
    this.isPrimaryListing = false,
    this.isDepositaryReceipt = false,
  });

  final String symbol;
  final String name;
  final String region;
  final String currency;

  /// Relevancia de la coincidencia, como fracción (1 = exacta).
  final double matchScore;

  /// ISIN de la empresa: lo comparten todas las cotizaciones de las acciones
  /// ordinarias (los certificados ADR tienen otro). `null` si no se conoce.
  final String? isin;

  /// Código de la bolsa (`TSE`, `BME`...).
  final String exchange;

  /// Nombre de la bolsa ("Tokyo Stock Exchange"); vacío si no se conoce.
  final String exchangeName;

  /// Es la cotización principal de la empresa: la de su bolsa de origen.
  final bool isPrimaryListing;

  /// Es un certificado de depósito (ADR/DR) y no la acción ordinaria.
  final bool isDepositaryReceipt;
}
