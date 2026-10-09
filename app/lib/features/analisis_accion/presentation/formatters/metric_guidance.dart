// Qué métricas mirar primero y cuáles se ven también en Trade Republic. Es el
// ÚNICO sitio que se edita para cambiar esa selección (criterios 98-105).

import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/rules/verdict_thresholds.dart';

const essentialTagText = 'Esencial';
const tradeRepublicTagText = 'Trade Republic';

/// Una métrica esencial y la pregunta de principiante que responde.
class EssentialMetric {
  const EssentialMetric({required this.id, required this.question});

  final String id;
  final String question;
}

/// Una por área (rentabilidad, crecimiento, caja, deuda, valoración y
/// precio), tal como las repiten las guías para principiantes. En el orden en
/// que conviene hacerse las preguntas.
const essentialMetrics = [
  EssentialMetric(
    id: 'margen_operativo',
    question: '¿Gana dinero con su negocio?',
  ),
  EssentialMetric(id: 'ingresos_cagr3', question: '¿Está creciendo?'),
  EssentialMetric(id: 'fcf_positivo', question: '¿Genera caja de verdad?'),
  EssentialMetric(id: 'deuda_ebitda', question: '¿Aguanta sus deudas?'),
  EssentialMetric(id: 'per', question: '¿Está cara respecto a lo que gana?'),
  EssentialMetric(
    id: 'precio_sma200',
    question: '¿Cómo va el precio a largo plazo?',
  ),
];

/// Métricas del motor que Trade Republic también muestra. Confirmado en su
/// ayuda oficial: capitalización, PER y rentabilidad por dividendo; de ellas,
/// solo el PER es una métrica del motor. Se amplía cuando se compruebe qué
/// enseña la app.
const tradeRepublicMetricIds = {'per'};

bool isEssential(String metricId) =>
    essentialMetrics.any((metric) => metric.id == metricId);

bool isInTradeRepublic(String metricId) =>
    tradeRepublicMetricIds.contains(metricId);

/// El semáforo de una métrica, con los mismos cortes que el veredicto.
/// `insufficientData` si no hay nota.
Verdict signalForScore(double? score) {
  if (score == null) return Verdict.insufficientData;
  if (score >= favorableMinScore) return Verdict.favorable;
  if (score >= neutralMinScore) return Verdict.neutral;
  return Verdict.unfavorable;
}
