/// Cómo se muestran los valores de una escala.
enum ScaleUnit {
  /// Múltiplo: 15 → "15x".
  multiple,

  /// Fracción mostrada como porcentaje: 0,025 → "2,5 %".
  fraction,

  /// Número sin unidad.
  decimal,
}

/// Punto de una escala: con este [value], la nota del motor es [score].
class ScalePoint {
  const ScalePoint(this.value, this.score);

  final double value;
  final double score;
}

/// Escala por tramos con la que el motor puntúa una métrica, copiada tal cual
/// para dibujarla (criterios 77-78). [points] va ordenada por valor ascendente.
class ReadingScale {
  ReadingScale({required List<ScalePoint> points, required this.unit})
    : assert(points.length >= 2, 'La escala necesita al menos dos puntos'),
      points = List.unmodifiable(points);

  final List<ScalePoint> points;
  final ScaleUnit unit;
}

/// Si un tramo de la escala se lee como favorable, intermedio o desfavorable.
enum Tone { positive, neutral, negative }

/// Tramo coloreado de una escala, de [from] a [to] (ambos incluidos).
class ScaleBand {
  const ScaleBand({required this.from, required this.to, required this.tone});

  final double from;
  final double to;
  final Tone tone;
}

/// Fila de la leyenda de una métrica sin escala (criterio 79).
class LegendRow {
  const LegendRow({
    required this.condition,
    required this.meaning,
    required this.tone,
  });

  final String condition;
  final String meaning;
  final Tone tone;
}
