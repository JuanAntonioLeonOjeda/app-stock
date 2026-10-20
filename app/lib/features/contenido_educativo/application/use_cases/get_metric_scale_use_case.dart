import 'package:stock_app/features/contenido_educativo/domain/entities/reading_scale.dart';
import 'package:stock_app/features/contenido_educativo/domain/ports/metric_scale_port.dart';

/// Obtiene la escala de lectura de una métrica para dibujar su barra de
/// tramos (criterios 77-78).
class GetMetricScaleUseCase {
  const GetMetricScaleUseCase(this._scales);

  final MetricScalePort _scales;

  /// `null` si la métrica no tiene escala por tramos.
  ReadingScale? call(String metricId) => _scales.scaleFor(metricId);
}
