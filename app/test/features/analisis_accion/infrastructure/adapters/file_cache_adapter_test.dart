import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/file_cache_adapter.dart';

void main() {
  late Directory directory;
  late DateTime now;
  late FileCacheAdapter cache;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('file_cache');
    now = DateTime(2026, 9, 30, 10);
    cache = FileCacheAdapter(directory: directory, now: () => now);
  });
  tearDown(() => directory.deleteSync(recursive: true));

  group('FileCacheAdapter', () {
    test('lee lo que escribe antes de que caduque', () async {
      await cache.write('av:OVERVIEW:IBM', '{"Symbol": "IBM"}', _sixHours);
      now = now.add(const Duration(hours: 5));

      expect(await cache.read('av:OVERVIEW:IBM'), '{"Symbol": "IBM"}');
    });

    test('una entrada caducada se lee como null y se borra', () async {
      await cache.write('av:OVERVIEW:IBM', 'valor', _sixHours);
      now = now.add(const Duration(hours: 7));

      expect(await cache.read('av:OVERVIEW:IBM'), isNull);
      expect(directory.listSync(), isEmpty);
    });

    test('una clave que no existe se lee como null', () async {
      expect(await cache.read('av:OVERVIEW:NADA'), isNull);
    });

    test('escribir de nuevo sustituye el valor y la caducidad', () async {
      await cache.write('clave', 'viejo', const Duration(hours: 1));
      await cache.write('clave', 'nuevo', _sixHours);
      now = now.add(const Duration(hours: 2));

      expect(await cache.read('clave'), 'nuevo');
    });

    test('persiste entre instancias (reinicio de la app)', () async {
      await cache.write('av:EARNINGS:IBM', 'valor', _sixHours);

      final reopened = FileCacheAdapter(directory: directory, now: () => now);

      expect(await reopened.read('av:EARNINGS:IBM'), 'valor');
    });

    test('claves con ":" y "." no chocan entre sí', () async {
      await cache.write('av:OVERVIEW:TSCO.LON', 'londres', _sixHours);
      await cache.write('av:OVERVIEW:TSCO', 'eeuu', _sixHours);

      expect(await cache.read('av:OVERVIEW:TSCO.LON'), 'londres');
      expect(await cache.read('av:OVERVIEW:TSCO'), 'eeuu');
    });

    test('si no puede escribir, no falla y la clave queda sin caché', () async {
      // Nombre de archivo de más de 255 caracteres.
      final longKey = 'av:SYMBOL_SEARCH:${'x' * 300}';

      await expectLater(cache.write(longKey, 'valor', _sixHours), completes);
      expect(await cache.read(longKey), isNull);
    });

    test('un archivo corrupto se lee como null', () async {
      await cache.write('clave', 'valor', _sixHours);
      final file = directory.listSync().whereType<File>().single;
      file.writeAsStringSync('no es json');

      expect(await cache.read('clave'), isNull);
    });
  });
}

const _sixHours = Duration(hours: 6);
