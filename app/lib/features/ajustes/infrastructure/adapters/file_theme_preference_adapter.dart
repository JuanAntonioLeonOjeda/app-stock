import 'dart:io';

import 'package:stock_app/core/storage/json_file.dart';
import 'package:stock_app/features/ajustes/domain/entities/theme_preference.dart';
import 'package:stock_app/features/ajustes/domain/ports/theme_preference_port.dart';

/// Versión del formato de `settings.json`. Otra versión se descarta.
const settingsJsonVersion = 1;

/// [ThemePreferencePort] persistente en `settings.json` dentro de [directory].
class FileThemePreferenceAdapter implements ThemePreferencePort {
  FileThemePreferenceAdapter({required Directory directory})
    : _file = JsonFile(File('${directory.path}/settings.json'));

  final JsonFile _file;

  /// Un archivo ausente, corrupto, de otra versión o con un valor desconocido
  /// da [ThemePreference.system].
  @override
  Future<ThemePreference> load() async {
    final json = await _file.read();
    if (json is! Map<String, Object?>) return ThemePreference.system;
    if (json['version'] != settingsJsonVersion) return ThemePreference.system;
    return ThemePreference.values.firstWhere(
      (preference) => preference.name == json['theme'],
      orElse: () => ThemePreference.system,
    );
  }

  /// Si no se puede escribir (p. ej. disco lleno) se ignora: el tema cambia en
  /// esta sesión, pero no se recuerda.
  @override
  Future<void> save(ThemePreference preference) async {
    try {
      await _file.write({
        'version': settingsJsonVersion,
        'theme': preference.name,
      });
    } on FileSystemException {
      // Preferencia sin guardar.
    }
  }
}
