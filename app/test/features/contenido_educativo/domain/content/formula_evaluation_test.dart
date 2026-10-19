import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/contenido_educativo/domain/content/formula_evaluation.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/formula_diagram.dart';

FormulaPiece _piece(String key, double value) => FormulaPiece(
  key: key,
  name: key,
  source: DataSource.market,
  exampleValue: value,
);

const _result = FormulaResult(name: 'R', unit: 'x', exampleValue: 0);

void main() {
  group('evaluateFormula', () {
    final ratio = RatioFormula(
      numerator: _piece('precio', 30),
      denominator: _piece('beneficio', 2),
      result: _result,
    );

    test(
      'un cociente con los valores del ejemplo da el resultado del ejemplo',
      () {
        expect(evaluateFormula(ratio), 15);
      },
    );

    test('un valor sustituido cambia el resultado', () {
      expect(evaluateFormula(ratio, {'precio': 50}), 25);
    });

    test('un denominador cero devuelve null', () {
      expect(evaluateFormula(ratio, {'beneficio': 0}), isNull);
    });

    final growth = GrowthFormula(
      initial: _piece('inicial', 100),
      finalValue: _piece('final', 121),
      years: _piece('anios', 2),
      result: _result,
    );

    test('el crecimiento compuesto de 100 a 121 en 2 años es el 10 %', () {
      expect(evaluateFormula(growth), closeTo(0.10, 1e-12));
    });

    test('un crecimiento con valor inicial negativo devuelve null', () {
      expect(evaluateFormula(growth, {'inicial': -5}), isNull);
    });

    test('un crecimiento con cero años devuelve null', () {
      expect(evaluateFormula(growth, {'anios': 0}), isNull);
    });

    test('una fórmula por pasos no se calcula', () {
      final steps = StepsFormula(
        steps: const [
          FormulaStep(name: 'a', description: 'b'),
          FormulaStep(name: 'c', description: 'd'),
        ],
        result: _result,
      );
      expect(evaluateFormula(steps), isNull);
    });
  });
}
