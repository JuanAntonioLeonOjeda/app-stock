// Nombres visibles de los valores de los enums del dominio.

import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/fetch_step.dart';

String verdictLabel(Verdict verdict) => switch (verdict) {
  Verdict.favorable => 'Favorable',
  Verdict.neutral => 'Neutral',
  Verdict.unfavorable => 'Desfavorable',
  Verdict.insufficientData => 'Datos insuficientes',
};

String confidenceLabel(Confidence confidence) => switch (confidence) {
  Confidence.high => 'Alta',
  Confidence.medium => 'Media',
  Confidence.low => 'Baja',
};

String profileLabel(CompanyProfile profile) => switch (profile) {
  CompanyProfile.financial => 'Financiera',
  CompanyProfile.growth => 'Crecimiento',
  CompanyProfile.dividend => 'Dividendo',
  CompanyProfile.general => 'General',
};

String blockLabel(Block block) => switch (block) {
  Block.valuation => 'Valoración',
  Block.health => 'Salud financiera',
  Block.growth => 'Crecimiento y rentabilidad',
  Block.technical => 'Técnico',
  Block.context => 'Contexto',
};

/// "Obteniendo balance, 3 de 6".
String fetchProgressLabel(FetchStep step) {
  final action = switch (step) {
    FetchStep.overview => 'Obteniendo perfil',
    FetchStep.dailyHistory => 'Obteniendo histórico de precios',
    FetchStep.incomeStatement => 'Obteniendo cuenta de resultados',
    FetchStep.balanceSheet => 'Obteniendo balance',
    FetchStep.cashFlow => 'Obteniendo flujos de caja',
    FetchStep.earnings => 'Obteniendo resultados trimestrales',
  };
  return '$action, ${step.index + 1} de ${FetchStep.values.length}';
}
