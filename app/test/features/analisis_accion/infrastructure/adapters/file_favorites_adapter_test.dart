import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/favorite.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/file_favorites_adapter.dart';

const _nintendo = Favorite(symbol: 'TSE:7974', name: 'Nintendo');
const _iberdrola = Favorite(symbol: 'BME:IBE', name: 'Iberdrola');

void main() {
  late Directory directory;
  late FileFavoritesAdapter favorites;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('favorites');
    favorites = FileFavoritesAdapter(directory: directory);
  });

  tearDown(() => directory.deleteSync(recursive: true));

  group('FileFavoritesAdapter', () {
    test('sin archivo no hay favoritas', () async {
      expect(await favorites.load(), isEmpty);
    });

    test('guarda las favoritas con la última añadida primero', () async {
      await favorites.add(_nintendo);
      await favorites.add(_iberdrola);

      expect(await favorites.load(), [_iberdrola, _nintendo]);
    });

    test('las favoritas siguen ahí al abrir de nuevo la app', () async {
      await favorites.add(_nintendo);

      final reopened = FileFavoritesAdapter(directory: directory);

      final loaded = await reopened.load();
      expect(loaded.single.symbol, 'TSE:7974');
      expect(loaded.single.name, 'Nintendo');
    });

    test('añadir dos veces el mismo símbolo no lo duplica', () async {
      await favorites.add(_nintendo);
      await favorites.add(
        const Favorite(symbol: 'tse:7974', name: 'Nintendo Co'),
      );

      final loaded = await favorites.load();
      expect(loaded, hasLength(1));
      expect(loaded.single.name, 'Nintendo Co');
    });

    test('quitar una favorita deja las demás', () async {
      await favorites.add(_nintendo);
      await favorites.add(_iberdrola);

      await favorites.remove('TSE:7974');

      expect(await favorites.load(), [_iberdrola]);
    });

    test('quitar una que no está no hace nada', () async {
      await favorites.add(_nintendo);

      await favorites.remove('XXX:YYY');

      expect(await favorites.load(), [_nintendo]);
    });

    test('un archivo corrupto da una lista vacía', () async {
      File('${directory.path}/favorites.json').writeAsStringSync('{roto');

      expect(await favorites.load(), isEmpty);
    });

    test('un archivo de otra versión se descarta', () async {
      File('${directory.path}/favorites.json').writeAsStringSync(
        '{"version": 99, "favorites": [{"symbol": "A:B", "name": "X"}]}',
      );

      expect(await favorites.load(), isEmpty);
    });
  });
}
