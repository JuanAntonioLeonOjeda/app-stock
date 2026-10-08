/// Periodos que se pueden elegir en la gráfica de precio (criterios 46 y 58).
enum ChartRange {
  /// La última sesión de negociación, con velas de 5 minutos.
  day(1, isIntraday: true),

  /// Las últimas 5 sesiones, con velas de 30 minutos.
  week(7, isIntraday: true),
  month1(30),
  months3(91),
  months6(182),
  year1(365),
  years5(1826),

  /// Todo el histórico disponible.
  all(null);

  const ChartRange(this.days, {this.isIntraday = false});

  /// Días naturales hacia atrás desde la última sesión; `null` = todo.
  final int? days;

  /// Se dibuja con velas de minutos en lugar de cierres diarios.
  final bool isIntraday;
}
