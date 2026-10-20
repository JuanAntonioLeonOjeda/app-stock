import 'package:stock_app/features/ajustes/domain/entities/theme_preference.dart';
import 'package:stock_app/features/ajustes/domain/ports/theme_preference_port.dart';

/// Carga el tema que eligió el usuario (Sistema si nunca eligió).
class LoadThemePreferenceUseCase {
  const LoadThemePreferenceUseCase(this._preferences);

  final ThemePreferencePort _preferences;

  Future<ThemePreference> call() => _preferences.load();
}
