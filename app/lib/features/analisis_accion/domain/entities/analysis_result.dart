/// Veredicto global del análisis.
enum Verdict { favorable, neutral, unfavorable, insufficientData }

/// Confianza en el veredicto, según la cobertura y la antigüedad de los datos.
enum Confidence { high, medium, low }

/// Perfil de empresa detectado; cambia pesos de métricas, nunca fórmulas.
enum CompanyProfile { financial, growth, dividend, general }

/// Horizonte de inversión; cambia los pesos de los bloques.
enum Horizon { longTerm, shortTerm }

/// Los 5 bloques del análisis.
enum Block { valuation, health, growth, technical, context }

/// Cómo debe mostrarse el valor de una métrica. El formateo lo hace la capa
/// de presentación.
enum MetricFormat {
  /// Fracción que se muestra como porcentaje (0,025 → 2,5 %).
  percent,

  /// Múltiplo (PER, EV/EBITDA → "15,2x").
  multiple,

  /// Número decimal sin unidad (RSI, beta, ratios).
  decimal,

  /// Número entero de ocurrencias (trimestres que baten estimaciones).
  count,
}

/// Resultado de una métrica concreta.
class MetricResult {
  const MetricResult({
    required this.id,
    required this.label,
    required this.value,
    required this.format,
    required this.score,
    required this.weight,
    required this.note,
  });

  /// Id estable en español (`per`, `roic`...): enlaza con el contenido
  /// educativo.
  final String id;
  final String label;

  /// `null` si no hay dato.
  final double? value;
  final MetricFormat format;

  /// Nota 0-10, o `null` si no hay dato.
  final double? score;
  final double weight;

  /// Explicación cuando el valor es `null` por un motivo conocido.
  final String? note;
}

/// Resultado de un bloque.
class BlockResult {
  BlockResult({
    required this.block,
    required this.score,
    required this.weight,
    required this.coverage,
    required List<MetricResult> metrics,
  }) : metrics = List.unmodifiable(metrics);

  final Block block;

  /// Nota 0-10, o `null` si ninguna métrica del bloque tiene dato.
  final double? score;

  /// Peso del bloque en la nota global, como fracción.
  final double weight;

  /// Peso con dato / peso total del bloque, como fracción.
  final double coverage;
  final List<MetricResult> metrics;
}

/// Diagnóstico completo de una acción, tal como lo muestra la app.
class AnalysisResult {
  AnalysisResult({
    required this.symbol,
    required this.name,
    required this.currency,
    required this.price,
    required this.lastCloseDate,
    required this.lastFiscalPeriod,
    required this.profile,
    required this.horizon,
    required this.verdict,
    required this.globalScore,
    required this.confidence,
    required List<BlockResult> blocks,
    required List<String> flags,
    required List<String> missingData,
    required this.motorVersion,
  }) : blocks = List.unmodifiable(blocks),
       flags = List.unmodifiable(flags),
       missingData = List.unmodifiable(missingData);

  final String symbol;
  final String name;
  final String? currency;

  /// Último cierre, o `null` si no hay histórico.
  final double? price;
  final DateTime? lastCloseDate;
  final DateTime? lastFiscalPeriod;
  final CompanyProfile profile;
  final Horizon horizon;
  final Verdict verdict;

  /// Nota 0-10, o `null` si el veredicto es [Verdict.insufficientData].
  final double? globalScore;
  final Confidence confidence;
  final List<BlockResult> blocks;

  /// Avisos listos para mostrar.
  final List<String> flags;

  /// Descripción de los datos que faltan, lista para mostrar.
  final List<String> missingData;

  /// Versión del motor que produjo este resultado.
  final String motorVersion;
}
