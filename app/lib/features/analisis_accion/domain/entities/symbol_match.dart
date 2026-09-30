/// Una coincidencia de la búsqueda de símbolos.
class SymbolMatch {
  const SymbolMatch({
    required this.symbol,
    required this.name,
    required this.region,
    required this.currency,
    required this.matchScore,
  });

  final String symbol;
  final String name;
  final String region;
  final String currency;

  /// Relevancia de la coincidencia, como fracción (1 = exacta).
  final double matchScore;
}
