import 'package:flutter/foundation.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/load_favorites_use_case.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/set_favorite_use_case.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/favorite.dart';

/// Si la acción que se está viendo es favorita, y cómo marcarla o
/// desmarcarla. Uno por pantalla de resultado.
class FavoriteController extends ChangeNotifier {
  FavoriteController({
    required this._loadFavorites,
    required this._setFavorite,
    required this.symbol,
  });

  final LoadFavoritesUseCase _loadFavorites;
  final SetFavoriteUseCase _setFavorite;
  final String symbol;

  bool _isFavorite = false;
  bool _isBusy = false;
  bool _isDisposed = false;

  bool get isFavorite => _isFavorite;

  /// Hay un cambio en curso: se ignoran más pulsaciones.
  bool get isBusy => _isBusy;

  /// Mira si [symbol] ya está en los favoritos.
  Future<void> load() async {
    final target = Favorite(symbol: symbol, name: '');
    _isFavorite = (await _loadFavorites()).contains(target);
    _notify();
  }

  /// Invierte la marca. [name] es el nombre con el que se guarda.
  Future<void> toggle(String name) async {
    if (_isBusy) return;
    _isBusy = true;
    _notify();
    try {
      final next = !_isFavorite;
      await _setFavorite(
        Favorite(symbol: symbol, name: name),
        isFavorite: next,
      );
      _isFavorite = next;
    } finally {
      _isBusy = false;
      _notify();
    }
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
