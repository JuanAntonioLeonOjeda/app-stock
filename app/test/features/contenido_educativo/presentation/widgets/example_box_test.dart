import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/example_box.dart';

void main() {
  group('ExampleBox', () {
    testWidgets('rotula siempre el ejemplo como inventado', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExampleBox(text: 'Precio 30 € y beneficio 2 €.'),
          ),
        ),
      );

      expect(find.text('Ejemplo inventado'), findsOneWidget);
      expect(find.text('Precio 30 € y beneficio 2 €.'), findsOneWidget);
    });
  });
}
