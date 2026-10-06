import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/indicators/metric_value.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/scoring/piecewise_scale.dart';

/// Cómo se convierte el valor de una métrica en una nota 0-10.
sealed class MetricScoring {
  const MetricScoring();
}

/// Escala por tramos (ver `scorePiecewise`).
final class ScaleScoring extends MetricScoring {
  const ScaleScoring(this.points);

  final List<ScorePoint> points;
}

/// Función propia, para métricas que no encajan en una escala (p. ej. MACD,
/// que depende del signo y de la tendencia).
final class CustomScoring extends MetricScoring {
  const CustomScoring(this.score);

  final double? Function(MetricValue value) score;
}

/// Regla declarativa de una métrica: toda su "opinión" (escala, peso,
/// perfiles) está aquí, separada del cálculo.
class MetricRule {
  const MetricRule({
    required this.id,
    required this.block,
    required this.label,
    required this.format,
    required this.scoring,
    this.weight = 1,
    this.profileWeights = const {},
    this.onlyFor,
  });

  /// Id estable en español: enlaza con el contenido educativo.
  final String id;
  final Block block;
  final String label;
  final MetricFormat format;
  final MetricScoring scoring;

  /// Peso por defecto dentro del bloque.
  final double weight;

  /// Peso que sustituye a [weight] para ciertos perfiles (0 = desactivada).
  final Map<CompanyProfile, double> profileWeights;

  /// Si no es null, la métrica solo se usa con estos perfiles.
  final Set<CompanyProfile>? onlyFor;

  /// Peso de la métrica para [profile]; 0 si no se usa.
  double weightFor(CompanyProfile profile) {
    final profiles = onlyFor;
    if (profiles != null && !profiles.contains(profile)) return 0;
    return profileWeights[profile] ?? weight;
  }

  /// Nota 0-10 redondeada a 1 decimal, o `null` si no hay valor.
  double? score(MetricValue value) {
    final rawValue = value.value;
    if (rawValue == null) return null;
    final rawScore = switch (scoring) {
      ScaleScoring(:final points) => scorePiecewise(rawValue, points),
      CustomScoring(:final score) => score(value),
    };
    return rawScore == null ? null : roundToTenth(rawScore);
  }
}
