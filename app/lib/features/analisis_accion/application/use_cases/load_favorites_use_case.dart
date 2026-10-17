import 'package:stock_app/features/analisis_accion/domain/entities/favorite.dart';
import 'package:stock_app/features/analisis_accion/domain/ports/favorites_port.dart';

/// Carga las acciones favoritas, la última añadida primero.
class LoadFavoritesUseCase {
  const LoadFavoritesUseCase(this._favorites);

  final FavoritesPort _favorites;

  Future<List<Favorite>> call() => _favorites.load();
}
