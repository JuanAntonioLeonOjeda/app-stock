/// Periodos que se pueden elegir en la gráfica de precio (criterio 46).
enum ChartRange {
  month1(30),
  months3(91),
  months6(182),
  year1(365),
  years5(1826),

  /// Todo el histórico disponible.
  all(null);

  const ChartRange(this.days);

  /// Días naturales hacia atrás desde la última sesión; `null` = todo.
  final int? days;
}
