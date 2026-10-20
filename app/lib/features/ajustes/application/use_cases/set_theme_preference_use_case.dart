import 'package:stock_app/features/ajustes/domain/entities/theme_preference.dart';
import 'package:stock_app/features/ajustes/domain/ports/theme_preference_port.dart';

/// Guarda el tema que elige el usuario.
class SetThemePreferenceUseCase {
  const SetThemePreferenceUseCase(this._preferences);

  final ThemePreferencePort _preferences;

  Future<void> call(ThemePreference preference) =>
      _preferences.save(preference);
}
