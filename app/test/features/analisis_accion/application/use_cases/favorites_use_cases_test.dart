import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/clear_history_use_case.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/load_favorites_use_case.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/set_favorite_use_case.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/favorite.dart';

import '../fake_ports.dart';

const _nintendo = Favorite(symbol: 'TSE:7974', name: 'Nintendo');

void main() {
  group('SetFavoriteUseCase', () {
    test('marcar añade la favorita', () async {
      final favorites = FakeFavorites();

      await SetFavoriteUseCase(favorites)(_nintendo, isFavorite: true);

      expect(favorites.items, [_nintendo]);
    });

    test('desmarcar la quita', () async {
      final favorites = FakeFavorites([_nintendo]);

      await SetFavoriteUseCase(favorites)(_nintendo, isFavorite: false);

      expect(favorites.items, isEmpty);
    });
  });

  group('LoadFavoritesUseCase', () {
    test('devuelve las favoritas guardadas', () async {
      final favorites = FakeFavorites([_nintendo]);

      expect(await LoadFavoritesUseCase(favorites)(), [_nintendo]);
    });
  });

  group('ClearHistoryUseCase', () {
    test('vacía el historial', () async {
      final history = FakeHistory();
      await history.clear();

      await ClearHistoryUseCase(history)();

      expect(history.entries, isEmpty);
    });
  });
}
