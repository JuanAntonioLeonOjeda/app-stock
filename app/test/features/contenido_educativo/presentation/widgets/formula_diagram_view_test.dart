import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/formula_diagram.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/formula_diagram_view.dart';

Future<void> _pump(
  WidgetTester tester,
  FormulaDiagram diagram, {
  Map<String, double> values = const {},
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: FormulaDiagramView(diagram: diagram, values: values),
      ),
    ),
  ),
);

FormulaPiece _piece(
  String key,
  String name,
  double value, {
  DataSource source = DataSource.market,
  String unit = '',
}) => FormulaPiece(
  key: key,
  name: name,
  source: source,
  exampleValue: value,
  unit: unit,
);

void main() {
  group('FormulaDiagramView', () {
    final ratio = RatioFormula(
      numerator: _piece('precio', 'Precio', 30, unit: '€'),
      denominator: _piece(
        'beneficio',
        'Beneficio por acción',
        2,
        source: DataSource.incomeStatement,
        unit: '€',
      ),
      result: const FormulaResult(name: 'PER', unit: 'x', exampleValue: 15),
    );

    testWidgets('un cociente dibuja las dos piezas, su origen y el resultado', (
      tester,
    ) async {
      await _pump(tester, ratio);

      expect(find.text('Precio'), findsOneWidget);
      expect(find.text('30 €'), findsOneWidget);
      expect(find.text('Mercado'), findsOneWidget);
      expect(find.text('Beneficio por acción'), findsOneWidget);
      expect(find.text('Cuenta de resultados'), findsOneWidget);
      expect(find.text('÷'), findsOneWidget);
      expect(find.text('15x'), findsOneWidget);
    });

    testWidgets('los valores sustituidos recalculan el resultado', (
      tester,
    ) async {
      await _pump(tester, ratio, values: {'precio': 50});

      expect(find.text('50 €'), findsOneWidget);
      expect(find.text('25x'), findsOneWidget);
    });

    testWidgets('un denominador cero muestra un guion en vez del resultado', (
      tester,
    ) async {
      await _pump(tester, ratio, values: {'beneficio': 0});

      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('un crecimiento dibuja sus tres piezas y el resultado en %', (
      tester,
    ) async {
      final growth = GrowthFormula(
        initial: _piece('inicial', 'Ingresos hace 2 años', 100),
        finalValue: _piece('final', 'Ingresos hoy', 121),
        years: _piece('anios', 'Años', 2),
        result: const FormulaResult(
          name: 'Crecimiento anual',
          unit: '%',
          exampleValue: 0.1,
        ),
      );

      await _pump(tester, growth);

      expect(find.text('Ingresos hace 2 años'), findsOneWidget);
      expect(find.text('Ingresos hoy'), findsOneWidget);
      expect(find.text('Años'), findsOneWidget);
      expect(find.text('10 %'), findsOneWidget);
    });

    testWidgets('una fórmula por pasos numera los pasos y no calcula', (
      tester,
    ) async {
      final steps = StepsFormula(
        steps: const [
          FormulaStep(name: 'Subidas', description: 'Media de las subidas.'),
          FormulaStep(name: 'Bajadas', description: 'Media de las bajadas.'),
        ],
        result: const FormulaResult(name: 'RSI', unit: '', exampleValue: 55),
      );

      await _pump(tester, steps);

      expect(find.text('Subidas'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('55'), findsOneWidget);
    });
  });
}
