import 'dart:io';

import 'package:stock_app/features/analisis_accion/domain/entities/favorite.dart';
import 'package:stock_app/features/analisis_accion/domain/ports/favorites_port.dart';
import 'package:stock_app/core/storage/json_file.dart';

/// Versión del formato del archivo de favoritos. Otra versión se descarta.
const favoritesJsonVersion = 1;

/// [FavoritesPort] persistente en `favorites.json` dentro de [directory].
class FileFavoritesAdapter implements FavoritesPort {
  FileFavoritesAdapter({required Directory directory})
    : _file = JsonFile(File('${directory.path}/favorites.json'));

  final JsonFile _file;

  /// Un archivo ausente, corrupto o de otra versión da una lista vacía.
  @override
  Future<List<Favorite>> load() async {
    final json = await _file.read();
    if (json is! Map<String, Object?>) return [];
    if (json['version'] != favoritesJsonVersion) return [];
    final items = json['favorites'];
    if (items is! List<Object?>) return [];
    return [for (final item in items) ?_fromJson(item)];
  }

  @override
  Future<void> add(Favorite favorite) async {
    final others = (await load()).where((f) => f != favorite);
    await _save([favorite, ...others]);
  }

  @override
  Future<void> remove(String symbol) async {
    final target = Favorite(symbol: symbol, name: '');
    await _save((await load()).where((f) => f != target).toList());
  }

  /// Si no se puede escribir (p. ej. disco lleno) se ignora: la marca se
  /// pierde, pero la app sigue funcionando.
  Future<void> _save(List<Favorite> favorites) async {
    try {
      await _file.write({
        'version': favoritesJsonVersion,
        'favorites': [
          for (final f in favorites) {'symbol': f.symbol, 'name': f.name},
        ],
      });
    } on FileSystemException {
      // Favoritos sin actualizar.
    }
  }

  static Favorite? _fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final symbol = json['symbol'];
    final name = json['name'];
    if (symbol is! String || name is! String || symbol.isEmpty) return null;
    return Favorite(symbol: symbol, name: name);
  }
}
