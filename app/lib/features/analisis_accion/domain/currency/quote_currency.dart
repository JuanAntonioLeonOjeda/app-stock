/// La moneda en que cotiza una acción, resuelta a una moneda con tipo de cambio.
///
/// Algunas bolsas cotizan en subunidades: Londres en peniques (`GBX`),
/// Johannesburgo en céntimos (`ZAC`) y Tel Aviv en agorot (`ILA`). No tienen
/// tipo de cambio propio: son la libra, el rand y el séquel entre 100.
class QuoteCurrency {
  const QuoteCurrency(this.isoCode, {this.subunitDivisor = 1});

  /// Moneda con tipo de cambio (`GBP` para los `GBX`).
  final String isoCode;

  /// Subunidades que tiene una unidad (100 para los peniques).
  final int subunitDivisor;

  bool get isEuro => isoCode == 'EUR';
}

const _subunits = {
  'GBX': QuoteCurrency('GBP', subunitDivisor: 100),
  'ZAC': QuoteCurrency('ZAR', subunitDivisor: 100),
  'ILA': QuoteCurrency('ILS', subunitDivisor: 100),
};

/// La moneda de cotización de [code] (el código que da el proveedor), o `null`
/// si no hay código.
QuoteCurrency? resolveQuoteCurrency(String? code) {
  final normalized = code?.trim().toUpperCase();
  if (normalized == null || normalized.isEmpty) return null;
  return _subunits[normalized] ?? QuoteCurrency(normalized);
}
