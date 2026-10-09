// Serialización JSON de AnalysisResult e HistoryEntry. Vive en
// infrastructure/ (code-style.md): las entidades del dominio no saben de
// JSON. Los enums se guardan por nombre, así que renombrar un valor rompe los
// historiales guardados: en ese caso, subir historyJsonVersion.

import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/history_entry.dart';

typedef _Json = Map<String, Object?>;

Map<String, Object?> historyEntryToJson(HistoryEntry entry) => {
  'analyzedAt': entry.analyzedAt.toIso8601String(),
  'result': analysisResultToJson(entry.result),
};

/// Lanza [FormatException] si el JSON no tiene el formato esperado.
HistoryEntry historyEntryFromJson(Object? json) {
  final map = _object(json);
  return HistoryEntry(
    analyzedAt: _requiredDate(map['analyzedAt']),
    result: analysisResultFromJson(map['result']),
  );
}

Map<String, Object?> analysisResultToJson(AnalysisResult result) => {
  'symbol': result.symbol,
  'name': result.name,
  'currency': result.currency,
  'price': result.price,
  'lastCloseDate': result.lastCloseDate?.toIso8601String(),
  'lastFiscalPeriod': result.lastFiscalPeriod?.toIso8601String(),
  'profile': result.profile.name,
  'horizon': result.horizon.name,
  'verdict': result.verdict.name,
  'globalScore': result.globalScore,
  'confidence': result.confidence.name,
  'blocks': [for (final block in result.blocks) _blockToJson(block)],
  'flags': result.flags,
  'missingData': result.missingData,
  'motorVersion': result.motorVersion,
  'isin': result.isin,
  'exchange': result.exchange,
  'isPrimaryListing': result.isPrimaryListing,
};

/// Lanza [FormatException] si el JSON no tiene el formato esperado.
AnalysisResult analysisResultFromJson(Object? json) {
  final map = _object(json);
  return AnalysisResult(
    symbol: _requiredString(map['symbol']),
    name: _requiredString(map['name']),
    currency: _string(map['currency']),
    price: _double(map['price']),
    lastCloseDate: _date(map['lastCloseDate']),
    lastFiscalPeriod: _date(map['lastFiscalPeriod']),
    profile: _enum(CompanyProfile.values, map['profile']),
    horizon: _enum(Horizon.values, map['horizon']),
    verdict: _enum(Verdict.values, map['verdict']),
    globalScore: _double(map['globalScore']),
    confidence: _enum(Confidence.values, map['confidence']),
    blocks: [for (final block in _list(map['blocks'])) _blockFromJson(block)],
    flags: [for (final flag in _list(map['flags'])) _requiredString(flag)],
    missingData: [
      for (final label in _list(map['missingData'])) _requiredString(label),
    ],
    motorVersion: _requiredString(map['motorVersion']),
    // Ausentes en los análisis guardados antes de la Revisión 5.
    isin: _string(map['isin']),
    exchange: _string(map['exchange']),
    isPrimaryListing: _bool(map['isPrimaryListing']),
  );
}

_Json _blockToJson(BlockResult block) => {
  'block': block.block.name,
  'score': block.score,
  'weight': block.weight,
  'coverage': block.coverage,
  'metrics': [for (final metric in block.metrics) _metricToJson(metric)],
};

BlockResult _blockFromJson(Object? json) {
  final map = _object(json);
  return BlockResult(
    block: _enum(Block.values, map['block']),
    score: _double(map['score']),
    weight: _requiredDouble(map['weight']),
    coverage: _requiredDouble(map['coverage']),
    metrics: [
      for (final metric in _list(map['metrics'])) _metricFromJson(metric),
    ],
  );
}

_Json _metricToJson(MetricResult metric) => {
  'id': metric.id,
  'label': metric.label,
  'value': metric.value,
  'format': metric.format.name,
  'score': metric.score,
  'weight': metric.weight,
  'note': metric.note,
};

MetricResult _metricFromJson(Object? json) {
  final map = _object(json);
  return MetricResult(
    id: _requiredString(map['id']),
    label: _requiredString(map['label']),
    value: _double(map['value']),
    format: _enum(MetricFormat.values, map['format']),
    score: _double(map['score']),
    weight: _requiredDouble(map['weight']),
    note: _string(map['note']),
  );
}

// --- Lectura con tipos ----------------------------------------------------

_Json _object(Object? json) => json is _Json
    ? json
    : throw FormatException('Se esperaba un objeto: $json');

List<Object?> _list(Object? json) => json is List<Object?>
    ? json
    : throw FormatException('Se esperaba una lista: $json');

String? _string(Object? json) => json is String ? json : null;

/// Un booleano, o `null` si falta o no lo es.
bool? _bool(Object? json) => json is bool ? json : null;

String _requiredString(Object? json) =>
    _string(json) ?? (throw FormatException('Se esperaba texto: $json'));

double? _double(Object? json) => json is num ? json.toDouble() : null;

double _requiredDouble(Object? json) =>
    _double(json) ?? (throw FormatException('Se esperaba un número: $json'));

DateTime? _date(Object? json) =>
    json is String ? DateTime.tryParse(json) : null;

DateTime _requiredDate(Object? json) =>
    _date(json) ?? (throw FormatException('Se esperaba una fecha: $json'));

T _enum<T extends Enum>(List<T> values, Object? json) =>
    values.where((value) => value.name == json).firstOrNull ??
    (throw FormatException('Valor desconocido: $json'));
