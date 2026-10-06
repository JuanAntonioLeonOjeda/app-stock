/// Pregunta de comprobación de una ficha. No puntúa: sirve para pensar.
class CheckQuestion {
  CheckQuestion({
    required this.text,
    required List<String> options,
    required this.correctIndex,
    required this.explanation,
  }) : options = List.unmodifiable(options);

  final String text;
  final List<String> options;

  /// Posición de la opción correcta en [options].
  final int correctIndex;

  /// Por qué la respuesta correcta lo es; se muestra siempre, acierte o no.
  final String explanation;
}
