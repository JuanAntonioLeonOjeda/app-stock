// Nombres visibles de los valores de los enums del dominio.

import 'package:stock_app/features/analisis_accion/domain/chart/chart_range.dart';
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

/// Qué cotización de la empresa es la analizada (criterio 80).
const primaryListingText = 'Cotización principal';
const otherListingText = 'Otra cotización';

/// Texto del selector de periodo de la gráfica (criterio 46).
String chartRangeLabel(ChartRange range) => switch (range) {
  ChartRange.day => '1D',
  ChartRange.week => '1S',
  ChartRange.month1 => '1M',
  ChartRange.months3 => '3M',
  ChartRange.months6 => '6M',
  ChartRange.year1 => '1A',
  ChartRange.years5 => '5A',
  ChartRange.all => 'Todo',
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

/// Ids de los temas educativos de la gráfica de precio (criterios 68-69 de
/// `contenido_educativo`). Igual que los de bloque, son un contrato de strings
/// con esa feature, comprobado por un test en `app/test/`.
const priceChartTopicId = 'grafico_precio';
const shortAverageTopicId = 'media_50';
const longAverageTopicId = 'media_200';

/// Id del tema educativo de la guía del diagnóstico.
const diagnosisGuideTopicId = 'guia_diagnostico';

/// "Obteniendo datos de la empresa".
String fetchProgressLabel(FetchStep step) => switch (step) {
  FetchStep.fetching => 'Obteniendo datos de la empresa',
};

/// Palabra del semáforo de una métrica.
String signalLabel(Verdict signal) => switch (signal) {
  Verdict.favorable => 'Favorable',
  Verdict.neutral => 'Neutral',
  Verdict.unfavorable => 'Desfavorable',
  Verdict.insufficientData => 'Sin dato',
};
