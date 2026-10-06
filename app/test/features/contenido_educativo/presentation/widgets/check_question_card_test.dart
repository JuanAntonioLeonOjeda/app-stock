import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/check_question.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/check_question_card.dart';

final _question = CheckQuestion(
  text: '¿Qué mide?',
  options: const ['Una cosa', 'Otra cosa', 'Una tercera'],
  correctIndex: 1,
  explanation: 'Porque mide otra cosa.',
);

/// Tarjeta con estado propio de prueba: reenvía lo elegido como haría el
/// controller de la hoja.
class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  int? _selected;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: CheckQuestionCard(
        question: _question,
        selectedIndex: _selected,
        onSelect: (index) => setState(() => _selected = index),
      ),
    ),
  );
}

void main() {
  group('CheckQuestionCard', () {
    testWidgets('sin responder muestra la pregunta y las opciones', (
      tester,
    ) async {
      await tester.pumpWidget(const _Host());

      expect(find.text('¿Qué mide?'), findsOneWidget);
      expect(find.text('Una cosa'), findsOneWidget);
      expect(find.text('Otra cosa'), findsOneWidget);
      expect(find.text('Una tercera'), findsOneWidget);
      expect(find.text('Porque mide otra cosa.'), findsNothing);
    });

    testWidgets('acertar muestra "Correcto" y la explicación', (tester) async {
      await tester.pumpWidget(const _Host());

      await tester.tap(find.text('Otra cosa'));
      await tester.pump();

      expect(find.text('¡Correcto!'), findsOneWidget);
      expect(find.text('Porque mide otra cosa.'), findsOneWidget);
    });

    testWidgets('fallar también muestra la explicación, sin tono de burla', (
      tester,
    ) async {
      await tester.pumpWidget(const _Host());

      await tester.tap(find.text('Una cosa'));
      await tester.pump();

      expect(find.text('No exactamente.'), findsOneWidget);
      expect(find.text('Porque mide otra cosa.'), findsOneWidget);
    });

    testWidgets('se puede cambiar de opción tras fallar', (tester) async {
      await tester.pumpWidget(const _Host());
      await tester.tap(find.text('Una cosa'));
      await tester.pump();

      await tester.tap(find.text('Otra cosa'));
      await tester.pump();

      expect(find.text('¡Correcto!'), findsOneWidget);
      expect(find.text('No exactamente.'), findsNothing);
    });
  });
}
