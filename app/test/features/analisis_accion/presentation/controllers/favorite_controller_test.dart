import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/load_favorites_use_case.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/set_favorite_use_case.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/favorite.dart';
import 'package:stock_app/features/analisis_accion/presentation/controllers/favorite_controller.dart';

import '../../application/fake_ports.dart';

FavoriteController _controller(FakeFavorites favorites) {
  final controller = FavoriteController(
    loadFavorites: LoadFavoritesUseCase(favorites),
    setFavorite: SetFavoriteUseCase(favorites),
    symbol: 'TSE:7974',
  );
  addTearDown(controller.dispose);
  return controller;
}

void main() {
  group('FavoriteController', () {
    test('al empezar no es favorita', () {
      expect(_controller(FakeFavorites()).isFavorite, isFalse);
    });

    test(
      'load detecta una favorita ya guardada, sin importar mayúsculas',
      () async {
        final controller = _controller(
          FakeFavorites([const Favorite(symbol: 'tse:7974', name: 'Nintendo')]),
        );

        await controller.load();

        expect(controller.isFavorite, isTrue);
      },
    );

    test('toggle la marca con el nombre dado y avisa', () async {
      final favorites = FakeFavorites();
      final controller = _controller(favorites);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.toggle('Nintendo');

      expect(controller.isFavorite, isTrue);
      expect(favorites.items.single.name, 'Nintendo');
      expect(notifications, greaterThan(0));
    });

    test('toggle otra vez la desmarca', () async {
      final favorites = FakeFavorites();
      final controller = _controller(favorites);
      await controller.toggle('Nintendo');

      await controller.toggle('Nintendo');

      expect(controller.isFavorite, isFalse);
      expect(favorites.items, isEmpty);
    });

    test('mientras hay un cambio en curso ignora otra pulsación', () async {
      final favorites = FakeFavorites();
      final controller = _controller(favorites);

      final first = controller.toggle('Nintendo');
      final second = controller.toggle('Nintendo');
      await Future.wait([first, second]);

      expect(controller.isFavorite, isTrue);
    });
  });
}
