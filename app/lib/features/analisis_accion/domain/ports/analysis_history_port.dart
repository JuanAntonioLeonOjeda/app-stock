import 'package:stock_app/features/analisis_accion/domain/entities/history_entry.dart';

/// Historial de los últimos análisis, persistente entre sesiones.
abstract interface class AnalysisHistoryPort {
  /// Entradas guardadas, de la más reciente a la más antigua.
  Future<List<HistoryEntry>> load();

  /// Guarda [entry] al principio. Si ya había una entrada del mismo símbolo,
  /// la sustituye; si se supera el máximo, descarta la más antigua.
  Future<void> save(HistoryEntry entry);
}
