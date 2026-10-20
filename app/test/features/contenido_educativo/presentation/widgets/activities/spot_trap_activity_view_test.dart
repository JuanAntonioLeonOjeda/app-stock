import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/learning_activity.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/activities/spot_trap_activity_view.dart';

const _longValue = 'Rebajó sus previsiones antes de cada informe';
const _label = 'Sorpresas del beneficio';

final _activity = SpotTrapActivity(
  company: 'Norte',
  prompt: 'Pulsa el dato que engaña.',
  items: const [
    TrapItem(
      label: _label,
      value: _longValue,
      isTrap: true,
      explanation: 'Se pone el listón bajo.',
    ),
  ],
);

void main() {
  group('SpotTrapActivityView', () {
    testWidgets(
      'un valor largo en pantalla estrecha no parte la etiqueta en vertical',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SpotTrapActivityView(
                  activity: _activity,
                  tapped: const {},
                  onTap: (_) {},
                ),
              ),
            ),
          ),
        );

        // Una etiqueta partida letra a letra queda muy estrecha y muy alta.
        final label = tester.getSize(find.text(_label));
        expect(label.width, greaterThan(150));
        expect(label.height, lessThan(80));
      },
    );
  });
}
