import 'package:flutter/foundation.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/analyze_stock_use_case.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/open_news_use_case.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/fetch_step.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/history_entry.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';

/// Estado de la pantalla de resultado de una acción.
///
/// Se crea sin resultado (análisis nuevo, desde la búsqueda) o con uno
/// guardado (desde el historial, criterio 17: no se recalcula).
class AnalysisController extends ChangeNotifier {
  AnalysisController({
    required this._analyzeStock,
    required this._openNews,
    required this.symbol,
    HistoryEntry? initialEntry,
    DateTime Function()? now,
  }) : _entry = initialEntry,
       _now = now ?? DateTime.now;

  final AnalyzeStockUseCase _analyzeStock;
  final OpenNewsUseCase _openNews;
  final String symbol;
  final DateTime Function() _now;

  HistoryEntry? _entry;
  bool _isLoading = false;
  FetchStep? _currentStep;
  MarketDataException? _error;
  bool _lastWasForced = false;
  bool _isDisposed = false;

  /// Resultado mostrado; `null` hasta que termina el primer análisis.
  HistoryEntry? get entry => _entry;

  bool get isLoading => _isLoading;

  /// Paso en curso de la obtención de datos (criterio 32).
  FetchStep? get currentStep => _currentStep;

  /// Error del último intento. Si ya había un resultado, se conserva
  /// (criterio 21).
  MarketDataException? get error => _error;

  bool get canRefresh => !_isLoading;

  /// Tiempo desde que se hizo el análisis mostrado.
  Duration? get age {
    final entry = _entry;
    return entry == null ? null : _now().difference(entry.analyzedAt);
  }

  /// El resultado mostrado es antiguo: se avisa "Datos de hace X"
  /// (criterio 18).
  bool get isStale => _entry?.isStaleAt(_now()) ?? false;

  /// Analiza [symbol]. Con [forceRefresh], ignora los datos guardados
  /// (criterio 20). No hace nada si ya hay un análisis en curso.
  Future<void> analyze({bool forceRefresh = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    _currentStep = null;
    _error = null;
    _lastWasForced = forceRefresh;
    _notify();
    try {
      _entry = await _analyzeStock(
        symbol,
        forceRefresh: forceRefresh,
        onProgress: _onProgress,
      );
    } on MarketDataException catch (error) {
      _error = error;
    } finally {
      _isLoading = false;
      _currentStep = null;
      _notify();
    }
  }

  /// Abre las noticias recientes de la empresa (criterio 41). `false` si no hay
  /// resultado o el dispositivo no puede abrir el navegador (criterio 42).
  Future<bool> openNews() async {
    final entry = _entry;
    if (entry == null) return false;
    return _openNews(entry.result);
  }

  /// "Actualizar datos": vuelve a pedirlo todo ignorando la caché.
  Future<void> refresh() => analyze(forceRefresh: true);

  /// Repite el último intento fallido.
  Future<void> retry() => analyze(forceRefresh: _lastWasForced);

  void _onProgress(FetchStep step) {
    _currentStep = step;
    _notify();
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
