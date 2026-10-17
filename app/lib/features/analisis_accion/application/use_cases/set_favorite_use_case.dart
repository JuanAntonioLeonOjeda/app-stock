import 'package:stock_app/features/analisis_accion/domain/entities/favorite.dart';
import 'package:stock_app/features/analisis_accion/domain/ports/favorites_port.dart';

/// Marca o desmarca una acción como favorita.
class SetFavoriteUseCase {
  const SetFavoriteUseCase(this._favorites);

  final FavoritesPort _favorites;

  Future<void> call(Favorite favorite, {required bool isFavorite}) => isFavorite
      ? _favorites.add(favorite)
      : _favorites.remove(favorite.symbol);
}
