import 'package:stock_app/features/analisis_accion/domain/entities/favorite.dart';

/// Acciones favoritas del usuario, persistentes entre sesiones.
abstract interface class FavoritesPort {
  /// Favoritos guardados, el último añadido primero.
  Future<List<Favorite>> load();

  /// Añade [favorite] al principio. Si el símbolo ya estaba, no lo duplica:
  /// lo sustituye (por si cambió el nombre).
  Future<void> add(Favorite favorite);

  /// Quita el favorito con ese [symbol]; no hace nada si no estaba.
  Future<void> remove(String symbol);
}
