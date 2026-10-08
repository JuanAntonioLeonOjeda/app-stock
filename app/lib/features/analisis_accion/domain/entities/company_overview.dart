/// Perfil de la empresa y ratios que el proveedor da ya calculados.
///
/// `null` = dato no disponible (nunca 0). Porcentajes como fracción
/// (0,025 = 2,5 %).
class CompanyOverview {
  const CompanyOverview({
    required this.symbol,
    required this.name,
    required this.sector,
    required this.industry,
    required this.currency,
    required this.latestQuarter,
    required this.marketCapitalization,
    required this.sharesOutstanding,
    required this.peRatio,
    required this.forwardPe,
    required this.pegRatio,
    required this.priceToBook,
    required this.priceToSales,
    required this.evToEbitda,
    required this.beta,
    required this.dividendYield,
    required this.analystTargetPrice,
    required this.movingAverage50,
    required this.movingAverage200,
    required this.week52High,
    required this.week52Low,
    this.priceToFreeCashFlow,
    this.returnOnEquity,
    this.returnOnInvestedCapital,
    this.netDebtToEbitda,
    this.debtToEquity,
    this.currentRatio,
    this.operatingMargin,
    this.grossMargin,
    this.rsi14,
    this.isin,
    this.exchange,
    this.isPrimaryListing,
  });

  final String symbol;
  final String name;
  final String? sector;
  final String? industry;
  final String? currency;
  final DateTime? latestQuarter;
  final double? marketCapitalization;
  final double? sharesOutstanding;
  final double? peRatio;
  final double? forwardPe;
  final double? pegRatio;
  final double? priceToBook;
  final double? priceToSales;
  final double? evToEbitda;
  final double? beta;

  /// Fracción: 0,03 = 3 %.
  final double? dividendYield;
  final double? analystTargetPrice;

  // Respaldo cuando el histórico tiene menos de 200 sesiones
  // (ver references/metricas.md, sección 1).
  final double? movingAverage50;
  final double? movingAverage200;
  final double? week52High;
  final double? week52Low;

  // Ratios que el proveedor da ya calculados. El motor los usa solo cuando no
  // puede calcularlos con las cuentas: sin unidad, así que no mezclan
  // divisas (precio y capitalización en una moneda, cuentas en otra).
  final double? priceToFreeCashFlow;

  /// Fracción: 0,17 = 17 %.
  final double? returnOnEquity;

  /// Fracción: 0,17 = 17 %.
  final double? returnOnInvestedCapital;
  final double? netDebtToEbitda;
  final double? debtToEquity;
  final double? currentRatio;

  /// Fracción: 0,2 = 20 %.
  final double? operatingMargin;

  /// Fracción: 0,4 = 40 %.
  final double? grossMargin;

  /// RSI de 14 sesiones (0-100), cuando no hay histórico para calcularlo.
  final double? rsi14;

  /// ISIN de la empresa: lo comparten todas sus cotizaciones ordinarias.
  final String? isin;

  /// Código de la bolsa de esta cotización (`TSE`, `BME`...).
  final String? exchange;

  /// Esta cotización es la principal de la empresa (su bolsa de origen);
  /// `null` si el proveedor no lo dice.
  final bool? isPrimaryListing;
}
