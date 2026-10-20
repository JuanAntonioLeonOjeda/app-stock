import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/ajustes/application/use_cases/load_theme_preference_use_case.dart';
import 'package:stock_app/features/ajustes/application/use_cases/set_theme_preference_use_case.dart';
import 'package:stock_app/features/ajustes/domain/entities/theme_preference.dart';
import 'package:stock_app/features/ajustes/presentation/controllers/theme_controller.dart';
import 'package:stock_app/features/ajustes/presentation/theme_mode_mapper.dart';
import 'package:stock_app/features/ajustes/presentation/widgets/theme_mode_button.dart';

import '../../application/fake_ports.dart';

ThemeController _controller() {
  final preferences = FakeThemePreference();
  return ThemeController(
    loadPreference: LoadThemePreferenceUseCase(preferences),
    setPreference: SetThemePreferenceUseCase(preferences),
  );
}

Future<void> _pump(WidgetTester tester, ThemeController controller) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(actions: [ThemeModeButton(controller: controller)]),
        ),
      ),
    );

void main() {
  group('ThemeModeButton', () {
    testWidgets('el menú ofrece las tres opciones con la activa marcada', (
      tester,
    ) async {
      await _pump(tester, _controller());

      await tester.tap(find.byType(PopupMenuButton<ThemePreference>));
      await tester.pumpAndSettle();

      expect(find.text('Sistema'), findsOneWidget);
      expect(find.text('Claro'), findsOneWidget);
      expect(find.text('Oscuro'), findsOneWidget);
      expect(find.byIcon(Icons.done), findsOneWidget);
    });

    testWidgets('elegir Oscuro cambia la preferencia y el icono', (
      tester,
    ) async {
      final controller = _controller();
      await _pump(tester, controller);

      await tester.tap(find.byType(PopupMenuButton<ThemePreference>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Oscuro'));
      await tester.pumpAndSettle();

      expect(controller.preference, ThemePreference.dark);
      expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
    });

    testWidgets('el botón tiene etiqueta de accesibilidad con la opción', (
      tester,
    ) async {
      await _pump(tester, _controller());

      expect(find.byTooltip('Tema: Sistema'), findsOneWidget);
    });
  });

  group('themeModeFor', () {
    test('cada preferencia tiene su ThemeMode', () {
      expect(themeModeFor(ThemePreference.system), ThemeMode.system);
      expect(themeModeFor(ThemePreference.light), ThemeMode.light);
      expect(themeModeFor(ThemePreference.dark), ThemeMode.dark);
    });
  });
}
