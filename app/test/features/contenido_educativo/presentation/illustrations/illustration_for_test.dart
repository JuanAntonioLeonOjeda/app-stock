import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/core/theme/app_theme.dart';
import 'package:stock_app/features/contenido_educativo/presentation/illustrations/illustration_canvas.dart';
import 'package:stock_app/features/contenido_educativo/presentation/illustrations/illustration_for.dart';
import 'package:stock_app/features/contenido_educativo/presentation/illustrations/valuation_illustrations.dart';

Future<void> _pump(WidgetTester tester, Widget child, Brightness brightness) =>
    tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(brightness),
        home: Scaffold(body: Center(child: child)),
      ),
    );

void main() {
  group('illustrationFor', () {
    test('un id sin ilustración devuelve null', () {
      expect(illustrationFor('no_existe'), isNull);
    });

    test('hay una ilustración por cada métrica de valoración', () {
      expect(valuationIllustrations.keys, [
        'per',
        'peg',
        'ev_ebitda',
        'p_fcf',
        'p_ventas',
        'p_vc',
      ]);
      for (final id in valuationIllustrations.keys) {
        expect(illustrationFor(id), isNotNull, reason: id);
      }
    });

    for (final brightness in Brightness.values) {
      testWidgets('se dibujan sin errores en tema ${brightness.name}', (
        tester,
      ) async {
        for (final id in valuationIllustrations.keys) {
          await _pump(tester, illustrationFor(id)!, brightness);

          expect(tester.takeException(), isNull, reason: id);
        }
      });
    }

    testWidgets(
      'cada ilustración tiene una descripción para lectores de pantalla',
      (tester) async {
        final handle = tester.ensureSemantics();
        for (final id in valuationIllustrations.keys) {
          await _pump(tester, illustrationFor(id)!, Brightness.light);

          final label = tester
              .getSemantics(find.byType(IllustrationCanvas))
              .label;
          expect(label.trim(), isNotEmpty, reason: id);
        }
        handle.dispose();
      },
    );
  });
}
