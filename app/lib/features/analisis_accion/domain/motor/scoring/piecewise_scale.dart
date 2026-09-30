/// Punto de una escala por tramos: con este [value], la nota es [score].
class ScorePoint {
  const ScorePoint(this.value, this.score);

  final double value;
  final double score;
}

/// Nota de [value] según una escala por tramos: interpolación lineal entre
/// puntos y saturación en los extremos. [points] debe estar ordenada por
/// valor ascendente.
double scorePiecewise(double value, List<ScorePoint> points) {
  assert(points.isNotEmpty, 'La escala necesita al menos un punto');
  if (value <= points.first.value) return points.first.score;
  if (value >= points.last.value) return points.last.score;

  final upperIndex = points.indexWhere((p) => value <= p.value);
  final lower = points[upperIndex - 1];
  final upper = points[upperIndex];
  final fraction = (value - lower.value) / (upper.value - lower.value);
  return lower.score + fraction * (upper.score - lower.score);
}

/// Redondeo a 1 decimal de todas las notas del motor.
double roundToTenth(double score) => (score * 10).round() / 10;
