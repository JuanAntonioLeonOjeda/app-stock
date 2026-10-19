import 'package:stock_app/features/contenido_educativo/domain/entities/reading_scale.dart';

/// Escala con la que el motor puntúa una métrica, para dibujarla en su ficha.
///
/// Existe porque esta feature no puede importar el motor: quien la implementa
/// lee la escala real, de modo que la ficha nunca copia un umbral.
abstract interface class MetricScalePort {
  /// La escala de [metricId], o `null` si la métrica no tiene escala por
  /// tramos (MACD) o no existe.
  ReadingScale? scaleFor(String metricId);
}
