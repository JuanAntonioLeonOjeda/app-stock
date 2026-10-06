import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';

/// Un análisis guardado en el historial.
class HistoryEntry {
  const HistoryEntry({required this.result, required this.analyzedAt});

  /// A partir de esta antigüedad se avisa de "Datos de hace X": es la
  /// caducidad más corta de los datos de los que depende (el histórico
  /// diario, 6 h).
  static const staleAfter = Duration(hours: 6);

  final AnalysisResult result;
  final DateTime analyzedAt;

  bool isStaleAt(DateTime now) => now.difference(analyzedAt) > staleAfter;
}
