import 'dart:io';

import 'package:stock_app/features/analisis_accion/domain/entities/history_entry.dart';
import 'package:stock_app/features/analisis_accion/domain/ports/analysis_history_port.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/analysis_result_json.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/json_file.dart';

/// Versión del formato del archivo de historial. Un archivo con otra versión
/// se descarta (se empieza con el historial vacío).
const historyJsonVersion = 1;

/// Número máximo de análisis que guarda el historial (spec, criterio 15).
const maxHistoryEntries = 10;

/// [AnalysisHistoryPort] persistente en `analysis_history.json` dentro de
/// [directory].
class FileAnalysisHistoryAdapter implements AnalysisHistoryPort {
  FileAnalysisHistoryAdapter({required Directory directory})
    : _file = JsonFile(File('${directory.path}/analysis_history.json'));

  final JsonFile _file;

  /// Un archivo ausente, corrupto o de otra versión da un historial vacío:
  /// perder el historial es preferible a que la app no arranque.
  @override
  Future<List<HistoryEntry>> load() async {
    final json = await _file.read();
    if (json is! Map<String, Object?>) return [];
    if (json['version'] != historyJsonVersion) return [];
    final entries = json['entries'];
    if (entries is! List<Object?>) return [];
    try {
      return [for (final entry in entries) historyEntryFromJson(entry)];
    } on FormatException {
      return [];
    }
  }

  /// Si no se puede escribir (p. ej. disco lleno), se ignora: el usuario
  /// sigue viendo su análisis aunque no quede en el historial.
  @override
  Future<void> save(HistoryEntry entry) async {
    final symbol = entry.result.symbol.toUpperCase();
    final others = (await load()).where(
      (e) => e.result.symbol.toUpperCase() != symbol,
    );
    final entries = [entry, ...others].take(maxHistoryEntries);
    try {
      await _file.write({
        'version': historyJsonVersion,
        'entries': [for (final e in entries) historyEntryToJson(e)],
      });
    } on FileSystemException {
      // Historial sin actualizar; el análisis no se ve afectado.
    }
  }

  @override
  Future<void> clear() => _file.delete();
}
