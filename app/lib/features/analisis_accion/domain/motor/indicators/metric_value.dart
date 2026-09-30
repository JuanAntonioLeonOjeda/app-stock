/// Valor calculado de una métrica, antes de puntuarlo.
class MetricValue {
  /// Valor calculado, o `null` si falta algún dato (con [note] si se sabe
  /// por qué). Cuenta como dato que falta.
  const MetricValue(this.value, {this.previous, this.note})
    : isNotApplicable = false;

  /// La métrica no tiene sentido para esta empresa (p. ej. PER con
  /// beneficios negativos). No cuenta como dato que falta ni resta cobertura.
  const MetricValue.notApplicable(String this.note)
    : value = null,
      previous = null,
      isNotApplicable = true;

  final double? value;

  /// Valor de la sesión o periodo anterior, para reglas que puntúan la
  /// tendencia (p. ej. el histograma del MACD).
  final double? previous;
  final String? note;
  final bool isNotApplicable;

  bool get isMissing => value == null && !isNotApplicable;
}
