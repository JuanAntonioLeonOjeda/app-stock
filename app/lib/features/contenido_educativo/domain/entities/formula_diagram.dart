/// De dónde sale un dato de una fórmula (criterio 76).
enum DataSource {
  market,
  incomeStatement,
  balanceSheet,
  cashFlow,
  priceHistory,
}

/// Un dato de una fórmula con su valor en el ejemplo inventado.
///
/// Si [min] y [max] existen, el simulador deja moverlo entre ambos.
class FormulaPiece {
  const FormulaPiece({
    required this.key,
    required this.name,
    required this.source,
    required this.exampleValue,
    this.unit = '',
    this.min,
    this.max,
    this.step,
  });

  /// Identifica la pieza dentro de su fórmula (`precio`, `beneficio`...).
  final String key;
  final String name;
  final DataSource source;
  final double exampleValue;

  /// Sufijo para mostrar el dato (`€`, `M€`, `años`); vacío si no lleva.
  final String unit;
  final double? min;
  final double? max;

  /// Salto del deslizador (1 para años enteros); `null` si es continuo.
  final double? step;

  bool get isAdjustable => min != null && max != null;
}

/// El resultado de una fórmula: qué es y cuánto vale en el ejemplo.
class FormulaResult {
  const FormulaResult({
    required this.name,
    required this.unit,
    required this.exampleValue,
  });

  final String name;

  /// Sufijo para mostrarlo (`x`, `años`, `%`...); vacío si no lleva (RSI).
  /// Con `%` el valor es una fracción (0,10 = 10 %), como en todo el proyecto.
  final String unit;
  final double exampleValue;
}

/// Un paso de una fórmula que no es un simple cociente.
class FormulaStep {
  const FormulaStep({required this.name, required this.description});

  final String name;
  final String description;
}

/// Fórmula de una métrica dibujada por piezas (criterio 76).
sealed class FormulaDiagram {
  const FormulaDiagram({required this.result});

  final FormulaResult result;

  /// Piezas con dato, en el orden en que se dibujan.
  List<FormulaPiece> get pieces;
}

/// Numerador ÷ denominador (PER, márgenes, deuda/EBITDA...).
class RatioFormula extends FormulaDiagram {
  const RatioFormula({
    required this.numerator,
    required this.denominator,
    required super.result,
  });

  final FormulaPiece numerator;
  final FormulaPiece denominator;

  @override
  List<FormulaPiece> get pieces => [numerator, denominator];
}

/// Crecimiento anual compuesto entre un valor inicial y uno final.
class GrowthFormula extends FormulaDiagram {
  const GrowthFormula({
    required this.initial,
    required this.finalValue,
    required this.years,
    required super.result,
  });

  final FormulaPiece initial;
  final FormulaPiece finalValue;
  final FormulaPiece years;

  @override
  List<FormulaPiece> get pieces => [initial, finalValue, years];
}

/// Cuánto se aleja un valor de otro de referencia: `actual / referencia − 1`
/// (precio frente a su media, distancia al máximo...).
class VariationFormula extends FormulaDiagram {
  const VariationFormula({
    required this.current,
    required this.reference,
    required super.result,
  });

  final FormulaPiece current;
  final FormulaPiece reference;

  @override
  List<FormulaPiece> get pieces => [current, reference];
}

/// Secuencia de pasos sin simulador (RSI, MACD, medias...).
class StepsFormula extends FormulaDiagram {
  StepsFormula({required List<FormulaStep> steps, required super.result})
    : steps = List.unmodifiable(steps);

  final List<FormulaStep> steps;

  @override
  List<FormulaPiece> get pieces => const [];
}
