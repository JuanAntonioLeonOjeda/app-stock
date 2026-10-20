import 'package:stock_app/features/ajustes/domain/entities/theme_preference.dart';

/// Preferencia de tema del usuario, persistente entre sesiones.
abstract interface class ThemePreferencePort {
  /// La preferencia guardada; [ThemePreference.system] si no hay ninguna o no
  /// se puede leer.
  Future<ThemePreference> load();

  /// Guarda [preference]. Un fallo al escribir no lanza: la preferencia solo
  /// se pierde para la próxima sesión.
  Future<void> save(ThemePreference preference);
}
