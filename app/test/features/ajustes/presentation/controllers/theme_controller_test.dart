import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/ajustes/application/use_cases/load_theme_preference_use_case.dart';
import 'package:stock_app/features/ajustes/application/use_cases/set_theme_preference_use_case.dart';
import 'package:stock_app/features/ajustes/domain/entities/theme_preference.dart';
import 'package:stock_app/features/ajustes/domain/ports/theme_preference_port.dart';
import 'package:stock_app/features/ajustes/presentation/controllers/theme_controller.dart';

import '../../application/fake_ports.dart';

class _FailingSave extends FakeThemePreference {
  @override
  Future<void> save(ThemePreference preference) =>
      throw StateError('sin disco');
}

ThemeController _controller(ThemePreferencePort preferences) => ThemeController(
  loadPreference: LoadThemePreferenceUseCase(preferences),
  setPreference: SetThemePreferenceUseCase(preferences),
);

void main() {
  group('ThemeController', () {
    test('empieza siguiendo el sistema', () {
      expect(
        _controller(FakeThemePreference()).preference,
        ThemePreference.system,
      );
    });

    test('load aplica la preferencia guardada y avisa', () async {
      final controller = _controller(FakeThemePreference(ThemePreference.dark));
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.load();

      expect(controller.preference, ThemePreference.dark);
      expect(notifications, 1);
    });

    test('select cambia el tema y lo guarda', () async {
      final preferences = FakeThemePreference();
      final controller = _controller(preferences);

      await controller.select(ThemePreference.light);

      expect(controller.preference, ThemePreference.light);
      expect(preferences.stored, ThemePreference.light);
    });

    test('load no pisa una elección hecha mientras se leía', () async {
      final controller = _controller(FakeThemePreference(ThemePreference.dark));

      final loading = controller.load();
      await controller.select(ThemePreference.light);
      await loading;

      expect(controller.preference, ThemePreference.light);
    });

    test('elegir lo que ya estaba no avisa', () async {
      final controller = _controller(FakeThemePreference());
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.select(ThemePreference.system);

      expect(notifications, 0);
    });

    test('el tema cambia al instante, antes de terminar de guardar', () {
      final controller = _controller(_FailingSave());

      final saving = controller.select(ThemePreference.dark);

      expect(controller.preference, ThemePreference.dark);
      expect(saving, throwsStateError);
    });
  });
}
