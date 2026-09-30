import 'package:flutter/foundation.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/load_history_use_case.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/search_symbol_use_case.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/history_entry.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/symbol_match.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';

/// Estado de la pantalla de inicio: búsqueda e historial.
class HomeController extends ChangeNotifier {
  HomeController({
    required this._searchSymbol,
    required this._loadHistory,
    required this.isApiKeyConfigured,
  });

  final SearchSymbolUseCase _searchSymbol;
  final LoadHistoryUseCase _loadHistory;

  /// Sin clave no se busca ni se analiza (criterio 27); el historial sigue
  /// accesible.
  final bool isApiKeyConfigured;

  bool _isSearching = false;
  List<SymbolMatch>? _matches;
  MarketDataException? _searchError;
  List<HistoryEntry> _history = const [];
  bool _isDisposed = false;

  bool get isSearching => _isSearching;

  /// Resultados de la última búsqueda; `null` si aún no se ha buscado.
  List<SymbolMatch>? get matches => _matches;

  MarketDataException? get searchError => _searchError;

  /// Se ha buscado y no hay ninguna coincidencia (criterio 4).
  bool get hasNoResults {
    final matches = _matches;
    return matches != null && matches.isEmpty;
  }

  List<HistoryEntry> get history => _history;

  bool get canSearch => isApiKeyConfigured && !_isSearching;

  Future<void> refreshHistory() async {
    _history = List.unmodifiable(await _loadHistory());
    _notify();
  }

  /// Busca [query]. No hace nada con un texto vacío, sin clave o si ya hay
  /// una búsqueda en curso.
  Future<void> search(String query) async {
    if (!canSearch || query.trim().isEmpty) return;
    _isSearching = true;
    _searchError = null;
    _notify();
    try {
      _matches = List.unmodifiable(await _searchSymbol(query));
    } on MarketDataException catch (error) {
      _searchError = error;
    } finally {
      _isSearching = false;
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
