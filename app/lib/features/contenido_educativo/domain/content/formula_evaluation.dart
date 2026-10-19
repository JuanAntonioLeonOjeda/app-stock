import 'dart:math' as math;

import 'package:stock_app/features/contenido_educativo/domain/entities/formula_diagram.dart';

/// Resultado de [diagram] con los valores de [overrides] (por `key` de pieza)
/// en lugar de los del ejemplo.
///
/// Devuelve `null` cuando la cuenta no tiene sentido: denominador o referencia
/// cero, o un crecimiento con valores o años no positivos, y siempre en
/// [StepsFormula], que no se calcula. Para el crecimiento y la variación, el
/// resultado es una fracción (0,10 = 10 %).
double? evaluateFormula(
  FormulaDiagram diagram, [
  Map<String, double> overrides = const {},
]) {
  double valueOf(FormulaPiece piece) =>
      overrides[piece.key] ?? piece.exampleValue;
  switch (diagram) {
    case RatioFormula(:final numerator, :final denominator):
      final divisor = valueOf(denominator);
      return divisor == 0 ? null : valueOf(numerator) / divisor;
    case GrowthFormula(:final initial, :final finalValue, :final years):
      final start = valueOf(initial);
      final end = valueOf(finalValue);
      final span = valueOf(years);
      if (start <= 0 || end <= 0 || span <= 0) return null;
      return math.pow(end / start, 1 / span).toDouble() - 1;
    case VariationFormula(:final current, :final reference):
      final base = valueOf(reference);
      return base == 0 ? null : valueOf(current) / base - 1;
    case StepsFormula():
      return null;
  }
}
