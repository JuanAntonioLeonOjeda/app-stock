import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/formula_diagram.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/learning_activity.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/activities/simulator_activity_view.dart';

import '../../sample_content.dart';

/// Fracción de años con caja positiva: el numerador solo avanza de 1 en 1.
final _diagram = RatioFormula(
  numerator: const FormulaPiece(
    key: 'positivos',
    name: 'Años con FCF positivo',
    source: DataSource.cashFlow,
    exampleValue: 4,
    unit: 'años',
    min: 0,
    max: 5,
    step: 1,
  ),
  denominator: const FormulaPiece(
    key: 'analizados',
    name: 'Años analizados',
    source: DataSource.cashFlow,
    exampleValue: 5,
    unit: 'años',
  ),
  result: const FormulaResult(name: 'Fracción', unit: '%', exampleValue: 0.8),
);

Future<void> _pump(
  WidgetTester tester, {
  Map<String, double> values = const {},
  void Function(String, double)? onChanged,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: SimulatorActivityView(
          activity: const SimulatorActivity(prompt: 'Mueve los años.'),
          diagram: _diagram,
          scale: sampleScale(),
          values: values,
          onChanged: onChanged ?? (_, _) {},
          onReset: () {},
        ),
      ),
    ),
  ),
);

void main() {
  group('SimulatorActivityView', () {
    testWidgets('un slider con paso avanza solo por valores enteros', (
      tester,
    ) async {
      final changes = <double>[];
      await _pump(tester, onChanged: (_, value) => changes.add(value));

      await tester.drag(find.byType(Slider), const Offset(-120, 0));
      await tester.pump();

      expect(changes, isNotEmpty);
      expect(changes.every((value) => value == value.roundToDouble()), isTrue);
    });

    testWidgets('el slider tiene tantas posiciones como pasos', (tester) async {
      await _pump(tester);

      expect(tester.widget<Slider>(find.byType(Slider)).divisions, 5);
    });

    testWidgets('solo las piezas con min y max tienen slider', (tester) async {
      await _pump(tester);

      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('el resultado sigue los valores del usuario', (tester) async {
      await _pump(tester, values: {'positivos': 2});

      expect(find.text('40 %'), findsOneWidget);
    });
  });
}
