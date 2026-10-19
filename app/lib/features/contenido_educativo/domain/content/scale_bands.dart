import 'package:stock_app/features/contenido_educativo/domain/entities/reading_scale.dart';

/// Nota a partir de la cual un valor se lee como favorable.
const positiveScoreFrom = 7.0;

/// Nota a partir de la cual un valor se lee como intermedio.
const neutralScoreFrom = 4.0;

/// Nota de [value] según [scale]: la misma interpolación lineal entre puntos,
/// saturada en los extremos, que usa el motor.
double scoreAt(ReadingScale scale, double value) {
  final points = scale.points;
  if (value <= points.first.value) return points.first.score;
  if (value >= points.last.value) return points.last.score;
  final upperIndex = points.indexWhere((p) => value <= p.value);
  final lower = points[upperIndex - 1];
  final upper = points[upperIndex];
  final fraction = (value - lower.value) / (upper.value - lower.value);
  return lower.score + fraction * (upper.score - lower.score);
}

Tone toneOfScore(double score) {
  if (score >= positiveScoreFrom) return Tone.positive;
  if (score >= neutralScoreFrom) return Tone.neutral;
  return Tone.negative;
}

/// Tono del tramo en el que cae [value].
Tone toneAt(ReadingScale scale, double value) =>
    toneOfScore(scoreAt(scale, value));

/// Tramos coloreados entre el primer y el último punto de [scale], en orden
/// de valor. Las fronteras se calculan donde la nota cruza
/// [positiveScoreFrom] y [neutralScoreFrom], así que dependen solo de la
/// escala del motor y no de umbrales copiados.
List<ScaleBand> bandsFor(ReadingScale scale) {
  final cuts = _cutPoints(scale);
  final bands = <ScaleBand>[];
  for (var i = 0; i < cuts.length - 1; i++) {
    final from = cuts[i];
    final to = cuts[i + 1];
    final tone = toneAt(scale, (from + to) / 2);
    if (bands.isNotEmpty && bands.last.tone == tone) {
      bands[bands.length - 1] = ScaleBand(
        from: bands.last.from,
        to: to,
        tone: tone,
      );
    } else {
      bands.add(ScaleBand(from: from, to: to, tone: tone));
    }
  }
  return bands;
}

/// Valores donde puede cambiar el tono: los puntos de la escala y los cruces
/// con las notas frontera dentro de cada segmento.
List<double> _cutPoints(ReadingScale scale) {
  final points = scale.points;
  final cuts = <double>{for (final p in points) p.value};
  for (var i = 0; i < points.length - 1; i++) {
    for (final threshold in [positiveScoreFrom, neutralScoreFrom]) {
      final crossing = _crossing(points[i], points[i + 1], threshold);
      if (crossing != null) cuts.add(crossing);
    }
  }
  return cuts.toList()..sort();
}

double? _crossing(ScalePoint a, ScalePoint b, double threshold) {
  final low = a.score < b.score ? a.score : b.score;
  final high = a.score < b.score ? b.score : a.score;
  if (threshold <= low || threshold >= high) return null;
  final fraction = (threshold - a.score) / (b.score - a.score);
  return a.value + fraction * (b.value - a.value);
}
