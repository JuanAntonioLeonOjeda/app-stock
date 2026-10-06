// Ratios fundamentales. Fórmulas: references/metricas.md, secciones 2-4.
// Todos devuelven null si falta un dato o si el ratio no tiene sentido
// (p. ej. denominador ≤ 0): nunca 0 como sustituto.

import 'dart:math' show pow;

import 'package:stock_app/features/analisis_accion/domain/entities/cash_flow_statement.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/earnings_report.dart';

/// Tipo impositivo que se usa en el ROIC si el efectivo no es razonable.
const roicFallbackTaxRate = 0.21;

/// Tipo impositivo efectivo máximo que se considera razonable en el ROIC.
const roicMaxTaxRate = 0.5;

/// Suma de los últimos 4 trimestres de [field]; si no hay 4 trimestres con
/// dato, el valor del último año fiscal. Ambas listas, del más reciente al
/// más antiguo.
double? trailingTwelveMonths<T>({
  required List<T> quarterly,
  required List<T> annual,
  required double? Function(T) field,
}) {
  final lastFour = quarterly.take(4).map(field).whereType<double>().toList();
  if (lastFour.length == 4) return lastFour.reduce((a, b) => a + b);
  return annual.isEmpty ? null : field(annual.first);
}

/// Flujo de caja libre = flujo operativo − CAPEX.
double? freeCashFlow(CashFlowStatement statement) {
  final operating = statement.operatingCashflow;
  final capex = statement.capitalExpenditures;
  if (operating == null || capex == null) return null;
  return operating - capex;
}

/// `numerator / denominator`, solo si el denominador es > 0.
double? ratioOverPositive(double? numerator, double? denominator) {
  if (numerator == null || denominator == null || denominator <= 0) {
    return null;
  }
  return numerator / denominator;
}

/// Deuda neta / EBITDA, solo si el EBITDA es > 0.
double? netDebtToEbitda({
  required double? totalDebt,
  required double? cash,
  required double? ebitda,
}) {
  if (totalDebt == null || cash == null) return null;
  return ratioOverPositive(totalDebt - cash, ebitda);
}

/// Variación de [recent] frente a [previous] (fracción), si [previous] > 0.
double? growthRate(double? recent, double? previous) {
  final ratio = ratioOverPositive(recent, previous);
  return ratio == null ? null : ratio - 1;
}

/// Crecimiento anual compuesto: `(recent / oldest)^(1/years) − 1`. Solo con
/// ambos valores > 0.
double? cagr(double? recent, double? oldest, int years) {
  if (recent == null || oldest == null || recent <= 0 || oldest <= 0) {
    return null;
  }
  return pow(recent / oldest, 1 / years).toDouble() - 1;
}

/// Tipo impositivo efectivo: impuestos / beneficio antes de impuestos. Si no
/// se puede calcular o no es razonable (< 0 o > [roicMaxTaxRate]), devuelve
/// [roicFallbackTaxRate].
double effectiveTaxRate({
  required double? incomeTaxExpense,
  required double? incomeBeforeTax,
}) {
  final rate = ratioOverPositive(incomeTaxExpense, incomeBeforeTax);
  if (rate == null || rate < 0 || rate > roicMaxTaxRate) {
    return roicFallbackTaxRate;
  }
  return rate;
}

/// ROIC = EBIT·(1 − tipo impositivo) / (deuda + patrimonio − caja). Solo con
/// capital invertido > 0.
double? returnOnInvestedCapital({
  required double? ebit,
  required double taxRate,
  required double? totalDebt,
  required double? equity,
  required double? cash,
}) {
  if (ebit == null || totalDebt == null || equity == null || cash == null) {
    return null;
  }
  return ratioOverPositive(ebit * (1 - taxRate), totalDebt + equity - cash);
}

/// Fracción de los últimos 5 años (con al menos 3 con dato) en que el flujo
/// de caja libre fue positivo. [annual] del más reciente al más antiguo.
double? positiveFreeCashFlowFraction(List<CashFlowStatement> annual) {
  final fcfs = annual.take(5).map(freeCashFlow).whereType<double>().toList();
  if (fcfs.length < 3) return null;
  return fcfs.where((fcf) => fcf > 0).length / fcfs.length;
}

/// Cuántos de los 4 últimos trimestres tuvieron un BPA real superior al
/// estimado. null si alguno de los 4 no tiene los dos datos.
double? earningsBeatCount(List<EarningsReport> quarterly) {
  if (quarterly.length < 4) return null;
  var beats = 0;
  for (final report in quarterly.take(4)) {
    final reported = report.reportedEps;
    final estimated = report.estimatedEps;
    if (reported == null || estimated == null) return null;
    if (reported > estimated) beats++;
  }
  return beats.toDouble();
}
