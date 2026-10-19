import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/learning_activity.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/activities/compare_activity_view.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/activities/order_activity_view.dart';

final _compare = CompareActivity(
  sector: 'Muebles',
  companyA: 'Norte',
  companyB: 'Sur',
  rows: const [CompareRow(label: 'Deuda', a: '1x', b: '3x')],
  question: '¿Cuál debe menos?',
  correctIsA: true,
  explanation: 'Norte debe menos.',
);

final _order = OrderActivity(
  prompt: 'Ordena.',
  items: const [
    OrderItem(name: 'A', value: 1, shown: '1x'),
    OrderItem(name: 'B', value: 2, shown: '2x'),
  ],
  explanation: 'Se ordena por valor.',
);

void main() {
  group('CompareActivityView', () {
    Future<void> pump(WidgetTester tester, {bool? answerIsA}) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CompareActivityView(
                  activity: _compare,
                  answerIsA: answerIsA,
                  onAnswer: (_) {},
                ),
              ),
            ),
          ),
        );

    testWidgets('sin responder, ninguna opción lleva el check', (tester) async {
      await pump(tester);

      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets(
      'la opción elegida se distingue con un check, no solo con el color',
      (tester) async {
        await pump(tester, answerIsA: false);

        expect(find.byIcon(Icons.check), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(FilledButton),
            matching: find.text('Sur'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('la opción elegida se anuncia como seleccionada', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, answerIsA: true);

      expect(
        tester.getSemantics(
          find.ancestor(
            of: find.widgetWithText(FilledButton, 'Norte'),
            matching: find.byType(MergeSemantics),
          ),
        ),
        isSemantics(isSelected: true, isButton: true),
      );
      handle.dispose();
    });
  });

  group('OrderActivityView', () {
    testWidgets('el asa de arrastre mide al menos 48 dp', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OrderActivityView(
                activity: _order,
                order: const [1, 0],
                isChecked: false,
                isCorrect: false,
                onReorder: (_, _) {},
                onCheck: () {},
                onRetry: () {},
              ),
            ),
          ),
        ),
      );

      final handle = find.ancestor(
        of: find.byIcon(Icons.drag_handle).first,
        matching: find.byType(SizedBox),
      );
      final size = tester.getSize(handle.first);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });
  });
}
