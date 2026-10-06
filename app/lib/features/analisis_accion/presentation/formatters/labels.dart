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

/// Id del tema educativo de un bloque. Es un contrato de strings con el
/// contenido de `contenido_educativo` (ninguna feature importa de la otra):
/// un test en `app/test/` comprueba que cada bloque tiene su explicación.
String blockTopicId(Block block) => switch (block) {
  Block.valuation => 'bloque_valoracion',
  Block.health => 'bloque_salud',
  Block.growth => 'bloque_crecimiento',
  Block.technical => 'bloque_tecnico',
  Block.context => 'bloque_contexto',
};

/// Id del tema educativo de la guía del diagnóstico.
const diagnosisGuideTopicId = 'guia_diagnostico';

/// "Obteniendo datos de la empresa".
String fetchProgressLabel(FetchStep step) => switch (step) {
  FetchStep.fetching => 'Obteniendo datos de la empresa',
};
