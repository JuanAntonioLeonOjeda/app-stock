import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/rules/profile_criteria.dart';

/// Perfil de la empresa, en este orden: financiera → crecimiento →
/// dividendo → general. Cambia pesos de métricas, nunca fórmulas.
CompanyProfile detectProfile({
  required String? sector,
  required String? industry,
  required double? netIncomeTtm,
  required double? revenueCagr3,
  required double? dividendYield,
}) {
  if (_isFinancial(sector, industry)) return CompanyProfile.financial;
  if (_isGrowth(netIncomeTtm, revenueCagr3)) return CompanyProfile.growth;
  if (dividendYield != null && dividendYield >= dividendProfileMinYield) {
    return CompanyProfile.dividend;
  }
  return CompanyProfile.general;
}

bool _isFinancial(String? sector, String? industry) {
  final text = '${sector ?? ''} ${industry ?? ''}'.toLowerCase();
  return financialKeywords.any(text.contains);
}

bool _isGrowth(double? netIncomeTtm, double? revenueCagr3) {
  final isLossMaking = netIncomeTtm != null && netIncomeTtm <= 0;
  final isFastGrowing =
      revenueCagr3 != null && revenueCagr3 > growthProfileMinRevenueCagr;
  return isLossMaking || isFastGrowing;
}
