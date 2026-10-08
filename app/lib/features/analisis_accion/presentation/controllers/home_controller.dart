import 'package:flutter/foundation.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/load_history_use_case.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/search_symbol_use_case.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/company_listings.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/history_entry.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';

/// Estado de la pantalla de inicio: búsqueda e historial.
class HomeController extends ChangeNotifier {
  HomeController({required this._searchSymbol, required this._loadHistory});

  final SearchSymbolUseCase _searchSymbol;
  final LoadHistoryUseCase _loadHistory;

  bool _isSearching = false;
  List<CompanyListings>? _companies;
  bool _showReceipts = false;
  MarketDataException? _searchError;
  List<HistoryEntry> _history = const [];
  bool _isDisposed = false;

  bool get isSearching => _isSearching;

  /// Empresas de la última búsqueda que se ven ahora; `null` si aún no se ha
  /// buscado. Los certificados ADR solo salen si se piden (criterio 75) o si no
  /// hay nada más.
  List<CompanyListings>? get companies {
    final all = _companies;
    if (all == null) return null;
    return _isShowingReceipts
        ? all
        : [
            for (final c in all)
              if (!c.isDepositaryReceipt) c,
          ];
  }

  /// Cuántos certificados ADR hay entre los resultados (se muestren o no).
  int get receiptCount =>
      (_companies ?? const []).where((c) => c.isDepositaryReceipt).length;

  /// Hay acciones y también certificados: tiene sentido ofrecer "Mostrar ADR".
  bool get canToggleReceipts =>
      receiptCount > 0 &&
      (_companies ?? const []).any((c) => !c.isDepositaryReceipt);

  /// Los certificados ADR se ven: porque se pidió o porque son todo lo que hay.
  bool get _isShowingReceipts =>
      _showReceipts ||
      !(_companies ?? const []).any((c) => !c.isDepositaryReceipt);

  bool get showReceipts => _isShowingReceipts;

  MarketDataException? get searchError => _searchError;

  /// Se ha buscado y no hay ninguna coincidencia (criterio 4).
  bool get hasNoResults {
    final companies = _companies;
    return companies != null && companies.isEmpty;
  }

  List<HistoryEntry> get history => _history;

  bool get canSearch => !_isSearching;

  /// Muestra u oculta los certificados ADR de los resultados (criterio 75).
  void setShowReceipts({required bool isVisible}) {
    _showReceipts = isVisible;
    _notify();
  }

  Future<void> refreshHistory() async {
    _history = List.unmodifiable(await _loadHistory());
    _notify();
  }

  /// Busca [query]. No hace nada con un texto vacío o si ya hay una búsqueda
  /// en curso.
  Future<void> search(String query) async {
    if (!canSearch || query.trim().isEmpty) return;
    _isSearching = true;
    _searchError = null;
    _notify();
    try {
      _companies = List.unmodifiable(await _searchSymbol(query));
      _showReceipts = false;
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
