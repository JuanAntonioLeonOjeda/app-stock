import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/scoring/profile_detector.dart';

CompanyProfile _detect({
  String? sector = 'TECHNOLOGY',
  String? industry = 'SOFTWARE',
  double? netIncomeTtm = 100,
  double? revenueCagr3 = 0.05,
  double? dividendYield = 0.01,
}) => detectProfile(
  sector: sector,
  industry: industry,
  netIncomeTtm: netIncomeTtm,
  revenueCagr3: revenueCagr3,
  dividendYield: dividendYield,
);

void main() {
  group('detectProfile', () {
    test('banca, seguros y servicios financieros son financiera', () {
      expect(_detect(sector: 'FINANCIAL SERVICES'), CompanyProfile.financial);
      expect(_detect(industry: 'BANKS - REGIONAL'), CompanyProfile.financial);
      expect(_detect(industry: 'INSURANCE - LIFE'), CompanyProfile.financial);
    });

    test('financiera tiene prioridad sobre crecimiento y dividendo', () {
      final profile = _detect(
        sector: 'FINANCE',
        netIncomeTtm: -5,
        dividendYield: 0.05,
      );

      expect(profile, CompanyProfile.financial);
    });

    test('beneficio de 12 meses ≤ 0 es crecimiento', () {
      expect(_detect(netIncomeTtm: 0), CompanyProfile.growth);
      expect(_detect(netIncomeTtm: -10), CompanyProfile.growth);
    });

    test('ingresos creciendo más de un 20 % anual es crecimiento', () {
      expect(_detect(revenueCagr3: 0.25), CompanyProfile.growth);
      expect(_detect(revenueCagr3: 0.2), CompanyProfile.general);
    });

    test('rentabilidad por dividendo ≥ 3 % es dividendo', () {
      expect(_detect(dividendYield: 0.03), CompanyProfile.dividend);
    });

    test('crecimiento tiene prioridad sobre dividendo', () {
      final profile = _detect(revenueCagr3: 0.3, dividendYield: 0.05);

      expect(profile, CompanyProfile.growth);
    });

    test('el resto es general, también sin datos', () {
      expect(_detect(), CompanyProfile.general);
      expect(
        _detect(
          sector: null,
          industry: null,
          netIncomeTtm: null,
          revenueCagr3: null,
          dividendYield: null,
        ),
        CompanyProfile.general,
      );
    });
  });
}
