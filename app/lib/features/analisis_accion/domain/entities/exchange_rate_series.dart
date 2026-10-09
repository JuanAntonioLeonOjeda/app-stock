/// El tipo de cambio de un día: unidades de la moneda por cada euro.
class RatePoint {
  const RatePoint(this.date, this.unitsPerEuro);

  /// El día al que corresponde, en UTC y sin hora.
  final DateTime date;
  final double unitsPerEuro;
}

/// Los tipos de cambio de una moneda frente al euro, día a día.
class ExchangeRateSeries {
  ExchangeRateSeries({required this.currency, required List<RatePoint> points})
    : points = List.unmodifiable(_ascending(points));

  static List<RatePoint> _ascending(List<RatePoint> points) {
    final sorted = [...points];
    sorted.sort((RatePoint a, RatePoint b) => a.date.compareTo(b.date));
    return sorted;
  }

  /// Código ISO de la moneda (`JPY`, `USD`...).
  final String currency;

  /// De más antiguo a más reciente.
  final List<RatePoint> points;

  bool get isEmpty => points.isEmpty;

  /// El tipo más reciente publicado.
  RatePoint? get latest => points.lastOrNull;

  /// El último tipo publicado hasta [day] inclusive (los fines de semana y
  /// festivos no hay tipo: vale el del día hábil anterior). `null` si [day] es
  /// anterior al primer tipo.
  RatePoint? pointOn(DateTime day) {
    final target = DateTime.utc(day.year, day.month, day.day);
    var low = 0;
    var high = points.length - 1;
    RatePoint? found;
    while (low <= high) {
      final middle = (low + high) ~/ 2;
      if (points[middle].date.isAfter(target)) {
        high = middle - 1;
      } else {
        found = points[middle];
        low = middle + 1;
      }
    }
    return found;
  }

  /// Unidades de la moneda por euro en [day]; `null` si no hay tipo todavía.
  double? rateOn(DateTime day) => pointOn(day)?.unitsPerEuro;
}
