import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/ajustes/application/use_cases/load_theme_preference_use_case.dart';
import 'package:stock_app/features/ajustes/domain/entities/theme_preference.dart';

import '../fake_ports.dart';

void main() {
  group('LoadThemePreferenceUseCase', () {
    test('devuelve la preferencia guardada', () async {
      final useCase = LoadThemePreferenceUseCase(
        FakeThemePreference(ThemePreference.dark),
      );

      expect(await useCase(), ThemePreference.dark);
    });
  });
}
