import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/core/storage/json_file.dart';

void main() {
  late Directory directory;

  setUp(() => directory = Directory.systemTemp.createTempSync('json_file'));
  tearDown(() => directory.deleteSync(recursive: true));

  group('JsonFile', () {
    test('lee lo que escribe', () async {
      final file = JsonFile(File('${directory.path}/a.json'));

      await file.write({'clave': 'valor', 'n': 1.5});

      expect(await file.read(), {'clave': 'valor', 'n': 1.5});
    });

    test('crea la carpeta si no existe', () async {
      final file = JsonFile(File('${directory.path}/sub/dir/a.json'));

      await file.write([1, 2]);

      expect(await file.read(), [1, 2]);
    });

    test('no deja el archivo temporal tras escribir', () async {
      final file = JsonFile(File('${directory.path}/a.json'));

      await file.write({'x': 1});

      expect(File('${directory.path}/a.json.tmp').existsSync(), isFalse);
    });

    test('un archivo que no existe se lee como null', () async {
      final file = JsonFile(File('${directory.path}/no_existe.json'));

      expect(await file.read(), isNull);
    });

    test('un archivo corrupto se lee como null', () async {
      final raw = File('${directory.path}/roto.json')
        ..writeAsStringSync('{"a": ');

      expect(await JsonFile(raw).read(), isNull);
    });

    test('borrar un archivo que no existe no falla', () async {
      final file = JsonFile(File('${directory.path}/no_existe.json'));

      await expectLater(file.delete(), completes);
    });
  });
}
