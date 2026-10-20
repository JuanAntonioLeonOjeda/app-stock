import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/ajustes/domain/entities/theme_preference.dart';
import 'package:stock_app/features/ajustes/infrastructure/adapters/file_theme_preference_adapter.dart';

void main() {
  late Directory directory;
  late FileThemePreferenceAdapter adapter;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('settings');
    adapter = FileThemePreferenceAdapter(directory: directory);
  });

  tearDown(() => directory.deleteSync(recursive: true));

  void writeSettings(String content) =>
      File('${directory.path}/settings.json').writeAsStringSync(content);

  group('FileThemePreferenceAdapter', () {
    test('sin archivo usa el tema del sistema', () async {
      expect(await adapter.load(), ThemePreference.system);
    });

    test('recuerda la preferencia entre sesiones', () async {
      await adapter.save(ThemePreference.dark);

      final reopened = FileThemePreferenceAdapter(directory: directory);

      expect(await reopened.load(), ThemePreference.dark);
    });

    test('un archivo corrupto usa el tema del sistema', () async {
      writeSettings('{no es json');

      expect(await adapter.load(), ThemePreference.system);
    });

    test('un archivo de otra versión usa el tema del sistema', () async {
      writeSettings('{"version": 99, "theme": "dark"}');

      expect(await adapter.load(), ThemePreference.system);
    });

    test('un valor desconocido usa el tema del sistema', () async {
      writeSettings('{"version": 1, "theme": "sepia"}');

      expect(await adapter.load(), ThemePreference.system);
    });

    test('si no se puede escribir, no falla', () async {
      final unwritable = FileThemePreferenceAdapter(
        directory: Directory('${directory.path}/settings.json/dentro'),
      );
      File('${directory.path}/settings.json').writeAsStringSync('{}');

      await expectLater(unwritable.save(ThemePreference.dark), completes);
    });
  });
}
