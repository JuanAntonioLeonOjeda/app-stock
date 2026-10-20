// Fakes escritos a mano de los ports (sin framework de mocking, ver
// .claude/rules/testing-conventions.md).

import 'package:stock_app/features/ajustes/domain/entities/theme_preference.dart';
import 'package:stock_app/features/ajustes/domain/ports/theme_preference_port.dart';

/// Preferencia de tema en memoria.
class FakeThemePreference implements ThemePreferencePort {
  FakeThemePreference([this.stored = ThemePreference.system]);

  ThemePreference stored;

  @override
  Future<ThemePreference> load() async => stored;

  @override
  Future<void> save(ThemePreference preference) async => stored = preference;
}
