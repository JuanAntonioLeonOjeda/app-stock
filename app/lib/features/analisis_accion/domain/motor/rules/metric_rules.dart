// Reglas de todas las métricas. Es el ÚNICO sitio con escalas y pesos de
// métricas. Cualquier cambio aquí altera resultados: actualizar tests, subir
// motorVersion y actualizar references/metricas.md (secciones 2-6).

import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/indicators/metric_value.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/rules/metric_rule.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/scoring/piecewise_scale.dart';

const _financial = CompanyProfile.financial;
const _growth = CompanyProfile.growth;
const _dividend = CompanyProfile.dividend;

const _revenueGrowthScale = ScaleScoring([
  ScorePoint(-0.05, 1),
  ScorePoint(0, 3),
  ScorePoint(0.05, 5),
  ScorePoint(0.1, 7),
  ScorePoint(0.2, 9),
  ScorePoint(0.3, 10),
]);

/// MACD: ≥ 0 y subiendo → 9; ≥ 0 y bajando → 6; < 0 y subiendo → 4;
/// < 0 y bajando → 2.
double? _scoreMacdHistogram(MetricValue value) {
  final histogram = value.value;
  final previous = value.previous;
  if (histogram == null || previous == null) return null;
  final isRising = histogram > previous;
  if (histogram >= 0) return isRising ? 9 : 6;
  return isRising ? 4 : 2;
}

const metricRules = <MetricRule>[
  // Valoración
  MetricRule(
    id: 'per',
    block: Block.valuation,
    label: 'PER 12 meses',
    format: MetricFormat.multiple,
    scoring: ScaleScoring([
      ScorePoint(8, 9),
      ScorePoint(15, 8),
      ScorePoint(25, 5),
      ScorePoint(35, 3),
      ScorePoint(50, 1),
    ]),
    profileWeights: {_growth: 0.3},
  ),
  MetricRule(
    id: 'peg',
    block: Block.valuation,
    label: 'PEG',
    format: MetricFormat.decimal,
    scoring: ScaleScoring([
      ScorePoint(0.5, 9),
      ScorePoint(1, 8),
      ScorePoint(2, 5),
      ScorePoint(3, 2),
    ]),
  ),
  MetricRule(
    id: 'ev_ebitda',
    block: Block.valuation,
    label: 'EV/EBITDA',
    format: MetricFormat.multiple,
    scoring: ScaleScoring([
      ScorePoint(6, 9),
      ScorePoint(10, 7),
      ScorePoint(14, 5),
      ScorePoint(20, 3),
      ScorePoint(30, 1),
    ]),
    profileWeights: {_financial: 0},
  ),
  MetricRule(
    id: 'p_fcf',
    block: Block.valuation,
    label: 'Precio/FCF',
    format: MetricFormat.multiple,
    scoring: ScaleScoring([
      ScorePoint(10, 9),
      ScorePoint(15, 8),
      ScorePoint(25, 5),
      ScorePoint(40, 2),
    ]),
    profileWeights: {_financial: 0},
  ),
  MetricRule(
    id: 'p_ventas',
    block: Block.valuation,
    label: 'Precio/Ventas',
    format: MetricFormat.multiple,
    scoring: ScaleScoring([
      ScorePoint(2, 9),
      ScorePoint(5, 7),
      ScorePoint(10, 4),
      ScorePoint(20, 1),
    ]),
    weight: 1.5,
    onlyFor: {_growth},
  ),
  MetricRule(
    id: 'p_vc',
    block: Block.valuation,
    label: 'Precio/Valor contable',
    format: MetricFormat.multiple,
    scoring: ScaleScoring([
      ScorePoint(0.8, 8),
      ScorePoint(1.5, 6),
      ScorePoint(3, 3),
    ]),
    weight: 1.5,
    onlyFor: {_financial},
  ),

  // Salud financiera
  MetricRule(
    id: 'deuda_ebitda',
    block: Block.health,
    label: 'Deuda neta/EBITDA',
    format: MetricFormat.multiple,
    scoring: ScaleScoring([
      ScorePoint(-1, 10),
      ScorePoint(0, 9),
      ScorePoint(1, 8),
      ScorePoint(2, 7),
      ScorePoint(3, 4),
      ScorePoint(4, 2),
      ScorePoint(6, 0),
    ]),
    weight: 1.5,
    profileWeights: {_financial: 0},
  ),
  MetricRule(
    id: 'deuda_patrimonio',
    block: Block.health,
    label: 'Deuda/Patrimonio',
    format: MetricFormat.decimal,
    scoring: ScaleScoring([
      ScorePoint(0.3, 9),
      ScorePoint(1, 7),
      ScorePoint(2, 4),
      ScorePoint(3, 2),
    ]),
    profileWeights: {_financial: 0},
  ),
  MetricRule(
    id: 'liquidez',
    block: Block.health,
    label: 'Ratio de liquidez',
    format: MetricFormat.decimal,
    scoring: ScaleScoring([
      ScorePoint(0.7, 2),
      ScorePoint(1, 4),
      ScorePoint(1.5, 7),
      ScorePoint(2, 9),
    ]),
    profileWeights: {_financial: 0},
  ),
  MetricRule(
    id: 'cobertura_intereses',
    block: Block.health,
    label: 'Cobertura de intereses',
    format: MetricFormat.multiple,
    scoring: ScaleScoring([
      ScorePoint(1, 0),
      ScorePoint(2, 2),
      ScorePoint(5, 6),
      ScorePoint(10, 9),
      ScorePoint(20, 10),
    ]),
  ),
  MetricRule(
    id: 'fcf_positivo',
    block: Block.health,
    label: 'Años con FCF positivo',
    format: MetricFormat.percent,
    scoring: ScaleScoring([
      ScorePoint(0, 1),
      ScorePoint(0.6, 4),
      ScorePoint(0.8, 7),
      ScorePoint(1, 10),
    ]),
  ),
  MetricRule(
    id: 'payout_fcf',
    block: Block.health,
    label: 'Dividendo/FCF',
    format: MetricFormat.percent,
    scoring: ScaleScoring([
      ScorePoint(0.3, 9),
      ScorePoint(0.6, 7),
      ScorePoint(0.9, 3),
      ScorePoint(1.2, 0),
    ]),
    weight: 1.5,
    onlyFor: {_dividend},
  ),

  // Crecimiento y rentabilidad
  MetricRule(
    id: 'ingresos_cagr3',
    block: Block.growth,
    label: 'Crecimiento de ingresos (3 años)',
    format: MetricFormat.percent,
    scoring: _revenueGrowthScale,
    weight: 1.5,
  ),
  MetricRule(
    id: 'ingresos_yoy',
    block: Block.growth,
    label: 'Crecimiento de ingresos (último año)',
    format: MetricFormat.percent,
    scoring: _revenueGrowthScale,
  ),
  MetricRule(
    id: 'beneficio_cagr3',
    block: Block.growth,
    label: 'Crecimiento del beneficio (3 años)',
    format: MetricFormat.percent,
    scoring: ScaleScoring([
      ScorePoint(-0.05, 1),
      ScorePoint(0, 3),
      ScorePoint(0.05, 5),
      ScorePoint(0.1, 7),
      ScorePoint(0.2, 9),
    ]),
    profileWeights: {_growth: 0.3},
  ),
  MetricRule(
    id: 'margen_operativo',
    block: Block.growth,
    label: 'Margen operativo',
    format: MetricFormat.percent,
    scoring: ScaleScoring([
      ScorePoint(0, 1),
      ScorePoint(0.05, 3),
      ScorePoint(0.1, 5),
      ScorePoint(0.2, 8),
      ScorePoint(0.3, 10),
    ]),
    profileWeights: {_financial: 0},
  ),
  MetricRule(
    id: 'margen_tendencia',
    block: Block.growth,
    label: 'Cambio del margen operativo (3 años)',
    format: MetricFormat.percent,
    scoring: ScaleScoring([
      ScorePoint(-0.05, 2),
      ScorePoint(0, 5),
      ScorePoint(0.03, 8),
      ScorePoint(0.06, 9),
    ]),
    profileWeights: {_financial: 0},
  ),
  MetricRule(
    id: 'margen_bruto',
    block: Block.growth,
    label: 'Margen bruto',
    format: MetricFormat.percent,
    scoring: ScaleScoring([
      ScorePoint(0.2, 2),
      ScorePoint(0.4, 5),
      ScorePoint(0.6, 8),
      ScorePoint(0.75, 10),
    ]),
    weight: 1.5,
    onlyFor: {_growth},
  ),
  MetricRule(
    id: 'roic',
    block: Block.growth,
    label: 'ROIC',
    format: MetricFormat.percent,
    scoring: ScaleScoring([
      ScorePoint(0, 1),
      ScorePoint(0.05, 3),
      ScorePoint(0.1, 6),
      ScorePoint(0.15, 8),
      ScorePoint(0.25, 10),
    ]),
    weight: 1.5,
    profileWeights: {_financial: 0},
  ),
  MetricRule(
    id: 'roe',
    block: Block.growth,
    label: 'ROE',
    format: MetricFormat.percent,
    scoring: ScaleScoring([
      ScorePoint(0.05, 2),
      ScorePoint(0.1, 5),
      ScorePoint(0.15, 8),
      ScorePoint(0.2, 10),
    ]),
    weight: 2,
    onlyFor: {_financial},
  ),
  MetricRule(
    id: 'dilucion',
    block: Block.growth,
    label: 'Variación de acciones en circulación',
    format: MetricFormat.percent,
    scoring: ScaleScoring([
      ScorePoint(-0.03, 9),
      ScorePoint(0, 7),
      ScorePoint(0.03, 4),
      ScorePoint(0.06, 1),
    ]),
    weight: 0.5,
  ),

  // Técnico
  MetricRule(
    id: 'precio_sma200',
    block: Block.technical,
    label: 'Precio frente a la media de 200 sesiones',
    format: MetricFormat.percent,
    scoring: ScaleScoring([
      ScorePoint(-0.2, 1),
      ScorePoint(-0.05, 3),
      ScorePoint(0, 5),
      ScorePoint(0.05, 8),
      ScorePoint(0.15, 9),
      ScorePoint(0.25, 6),
      ScorePoint(0.4, 3),
    ]),
    weight: 1.5,
  ),
  MetricRule(
    id: 'pendiente_sma200',
    block: Block.technical,
    label: 'Pendiente de la media de 200 sesiones',
    format: MetricFormat.percent,
    scoring: ScaleScoring([
      ScorePoint(-0.05, 1),
      ScorePoint(0, 4),
      ScorePoint(0.02, 7),
      ScorePoint(0.05, 9),
    ]),
  ),
  MetricRule(
    id: 'rsi',
    block: Block.technical,
    label: 'RSI (14)',
    format: MetricFormat.decimal,
    scoring: ScaleScoring([
      ScorePoint(20, 4),
      ScorePoint(30, 6),
      ScorePoint(45, 9),
      ScorePoint(60, 9),
      ScorePoint(70, 6),
      ScorePoint(80, 3),
    ]),
  ),
  MetricRule(
    id: 'macd',
    block: Block.technical,
    label: 'Histograma MACD',
    format: MetricFormat.decimal,
    scoring: CustomScoring(_scoreMacdHistogram),
  ),
  MetricRule(
    id: 'dist_maximo',
    block: Block.technical,
    label: 'Distancia al máximo de 52 semanas',
    format: MetricFormat.percent,
    scoring: ScaleScoring([
      ScorePoint(-0.5, 2),
      ScorePoint(-0.3, 4),
      ScorePoint(-0.1, 7),
      ScorePoint(0, 8),
    ]),
    weight: 0.5,
  ),

  // Contexto
  MetricRule(
    id: 'sorpresas_bpa',
    block: Block.context,
    label: 'Trimestres que baten las estimaciones (de 4)',
    format: MetricFormat.count,
    scoring: ScaleScoring([
      ScorePoint(0, 2),
      ScorePoint(1, 4),
      ScorePoint(2, 6),
      ScorePoint(3, 8),
      ScorePoint(4, 10),
    ]),
  ),
  MetricRule(
    id: 'potencial_analistas',
    block: Block.context,
    label: 'Potencial según el precio objetivo de analistas',
    format: MetricFormat.percent,
    scoring: ScaleScoring([
      ScorePoint(-0.1, 2),
      ScorePoint(0, 4),
      ScorePoint(0.1, 6),
      ScorePoint(0.25, 8),
    ]),
    weight: 0.5,
  ),
  MetricRule(
    id: 'beta',
    block: Block.context,
    label: 'Beta',
    format: MetricFormat.decimal,
    scoring: ScaleScoring([
      ScorePoint(0.8, 8),
      ScorePoint(1.2, 6),
      ScorePoint(1.8, 3),
      ScorePoint(2.5, 1),
    ]),
    weight: 0.5,
  ),
  MetricRule(
    id: 'caida_maxima',
    block: Block.context,
    label: 'Caída máxima en un año',
    format: MetricFormat.percent,
    scoring: ScaleScoring([
      ScorePoint(-0.6, 1),
      ScorePoint(-0.4, 3),
      ScorePoint(-0.25, 6),
      ScorePoint(-0.1, 9),
    ]),
    weight: 0.5,
  ),
];
