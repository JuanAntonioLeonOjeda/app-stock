import 'package:stock_app/features/analisis_accion/domain/entities/history_entry.dart';
import 'package:stock_app/features/analisis_accion/domain/ports/analysis_history_port.dart';

/// Carga el historial de análisis (spec, criterios 15-19).
class LoadHistoryUseCase {
  const LoadHistoryUseCase(this._history);

  final AnalysisHistoryPort _history;

  /// Entradas guardadas, la más reciente primero (por fecha de análisis).
  Future<List<HistoryEntry>> call() async =>
      [...await _history.load()]
        ..sort((a, b) => b.analyzedAt.compareTo(a.analyzedAt));
}
