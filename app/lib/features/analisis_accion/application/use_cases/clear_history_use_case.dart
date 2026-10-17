import 'package:stock_app/features/analisis_accion/domain/ports/analysis_history_port.dart';

/// Vacía la lista de últimas consultas.
class ClearHistoryUseCase {
  const ClearHistoryUseCase(this._history);

  final AnalysisHistoryPort _history;

  Future<void> call() => _history.clear();
}
