import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/indicators/metric_values.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/rules/metric_rules.dart';

import '../synthetic_companies.dart';

void main() {
  group('computeMetricValues', () {
    test('calcula un valor para cada regla', () {
      final values = computeMetricValues(qualityCompany());

      expect(values.keys.toSet(), metricRules.map((r) => r.id).toSet());
    });

    test('P/FCF es la capitalización entre el FCF de 12 meses', () {
      // FCF TTM = 330 − 60 = 270; 3780 / 270 = 14.
      final values = computeMetricValues(qualityCompany());

      expect(values['p_fcf']?.value, closeTo(14, 1e-9));
    });

    test('dividendo/FCF usa el último año', () {
      final values = computeMetricValues(qualityCompany());

      expect(values['payout_fcf']?.value, closeTo(50 / 270, 1e-9));
    });

    test('el MACD lleva el histograma anterior para puntuar la tendencia', () {
      final macd = computeMetricValues(qualityCompany())['macd'];

      expect(macd?.value, isNotNull);
      expect(macd?.previous, isNotNull);
    });

    test('con beneficios negativos el PER y el crecimiento del beneficio no '
        'aplican', () {
      final values = computeMetricValues(
        buildCompany(annualOperatingIncome: const [5, 300, 260, 220]),
      );

      expect(values['per']?.isNotApplicable, isTrue);
      expect(values['beneficio_cagr3']?.isNotApplicable, isTrue);
    });

    test('con EBITDA negativo EV/EBITDA y deuda/EBITDA no aplican', () {
      final values = computeMetricValues(
        buildCompany(annualOperatingIncome: const [-100, 300, 260, 220]),
      );

      expect(values['ev_ebitda']?.isNotApplicable, isTrue);
      expect(values['deuda_ebitda']?.isNotApplicable, isTrue);
    });

    test('con patrimonio negativo deuda/patrimonio y ROE no aplican', () {
      final values = computeMetricValues(buildCompany(equity: -100));

      expect(values['deuda_patrimonio']?.isNotApplicable, isTrue);
      expect(values['roe']?.isNotApplicable, isTrue);
    });

    test('sin gastos financieros la cobertura de intereses no aplica', () {
      final values = computeMetricValues(buildCompany(interestExpense: 0));

      expect(values['cobertura_intereses']?.isNotApplicable, isTrue);
    });

    test('con menos de 4 años de cuentas el crecimiento a 3 años falta y '
        'explica por qué', () {
      final values = computeMetricValues(
        buildCompany(
          annualRevenue: const [1405, 1254],
          annualOperatingIncome: const [351, 300],
        ),
      );
      final revenueGrowth = values['ingresos_cagr3'];

      expect(revenueGrowth?.isMissing, isTrue);
      expect(revenueGrowth?.note, contains('4 años'));
    });

    test('sin datos todo falta y nada es 0', () {
      final values = computeMetricValues(emptyCompany());

      for (final entry in values.entries) {
        expect(entry.value.value, isNull, reason: entry.key);
      }
    });
  });

  group('netIncomeTtm', () {
    test('suma los 4 últimos trimestres', () {
      // Beneficio anual = (351 − 10)·0,79 = 269,39, repartido en 4.
      expect(netIncomeTtm(qualityCompany()), closeTo(269.39, 1e-9));
    });
  });
}
