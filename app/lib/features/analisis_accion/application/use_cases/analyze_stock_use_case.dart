import 'package:stock_app/features/analisis_accion/domain/entities/fetch_step.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/history_entry.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/stock_analyzer.dart';
import 'package:stock_app/features/analisis_accion/domain/ports/analysis_history_port.dart';
import 'package:stock_app/features/analisis_accion/domain/ports/market_data_port.dart';

/// Analiza una acción: obtiene sus datos, los pasa por el motor y guarda el
/// resultado en el historial (spec, criterios 5-8 y 20).
class AnalyzeStockUseCase {
  AnalyzeStockUseCase({
    required this._marketData,
    required this._history,
    this._analyzer = const StockAnalyzer(),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final MarketDataPort _marketData;
  final AnalysisHistoryPort _history;
  final StockAnalyzer _analyzer;
  final DateTime Function() _now;

  /// Entrada de historial con el análisis de [symbol], ya guardada.
  ///
  /// Con [forceRefresh] se ignoran los datos guardados (criterio 20).
  /// [onProgress] recibe cada paso de la obtención de datos. Si la obtención
  /// falla, lanza su `MarketDataException` y no guarda nada.
  Future<HistoryEntry> call(
    String symbol, {
    bool forceRefresh = false,
    void Function(FetchStep step)? onProgress,
  }) async {
    final data = await _marketData.fetchStockData(
      symbol,
      forceRefresh: forceRefresh,
      onProgress: onProgress,
    );
    // El motor no lee el reloj: el "hoy" del análisis se decide aquí.
    final analyzedAt = _now();
    final entry = HistoryEntry(
      result: _analyzer.analyze(data, referenceDate: analyzedAt),
      analyzedAt: analyzedAt,
    );
    await _history.save(entry);
    return entry;
  }
}
