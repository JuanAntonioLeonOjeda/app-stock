import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/ajustes/application/use_cases/set_theme_preference_use_case.dart';
import 'package:stock_app/features/ajustes/domain/entities/theme_preference.dart';

import '../fake_ports.dart';

void main() {
  group('SetThemePreferenceUseCase', () {
    test('guarda la preferencia elegida', () async {
      final preferences = FakeThemePreference();

      await SetThemePreferenceUseCase(preferences)(ThemePreference.light);

      expect(preferences.stored, ThemePreference.light);
    });
  });
}
