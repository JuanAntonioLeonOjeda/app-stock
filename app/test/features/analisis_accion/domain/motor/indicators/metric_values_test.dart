import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/company_overview.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/stock_data.dart';
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

  group('computeMetricValues con los ratios del proveedor', () {
    test('sin cuentas usa los ratios que da el proveedor', () {
      final values = computeMetricValues(_withProviderRatios());

      expect(values['roic']?.value, 0.17);
      expect(values['roe']?.value, 0.12);
      expect(values['margen_operativo']?.value, 0.2);
      expect(values['margen_bruto']?.value, 0.4);
      expect(values['liquidez']?.value, 2.5);
      expect(values['deuda_patrimonio']?.value, 0.5);
      expect(values['deuda_ebitda']?.value, 1.5);
      expect(values['p_fcf']?.value, 20);
      expect(values['rsi']?.value, 45);
    });

    test('sin cuentas ni ratios del proveedor siguen siendo sin dato', () {
      final values = computeMetricValues(emptyCompany());

      for (final id in ['roic', 'roe', 'margen_operativo', 'rsi', 'p_fcf']) {
        expect(values[id]?.value, isNull, reason: id);
      }
    });

    test('lo calculado con las cuentas prevalece sobre el ratio ajeno', () {
      final data = buildCompany(
        companyOverview: _overviewWithRatios(returnOnEquity: 0.99, rsi14: 99),
      );

      final values = computeMetricValues(data);

      expect(values['roe']?.value, isNot(0.99));
      expect(values['rsi']?.value, isNot(99));
    });

    test('un ratio de deuda/patrimonio no positivo no se usa', () {
      final data = _withProviderRatios(debtToEquity: -0.3);

      expect(computeMetricValues(data)['deuda_patrimonio']?.value, isNull);
    });
  });
}

CompanyOverview _overviewWithRatios({
  double? debtToEquity = 0.5,
  double? returnOnEquity = 0.12,
  double? rsi14 = 45,
}) => CompanyOverview(
  symbol: 'PROV',
  name: 'Proveedor S.A.',
  sector: null,
  industry: null,
  currency: 'USD',
  latestQuarter: null,
  marketCapitalization: null,
  sharesOutstanding: null,
  peRatio: null,
  forwardPe: null,
  pegRatio: null,
  priceToBook: null,
  priceToSales: null,
  evToEbitda: null,
  beta: null,
  dividendYield: null,
  analystTargetPrice: null,
  movingAverage50: null,
  movingAverage200: null,
  week52High: null,
  week52Low: null,
  priceToFreeCashFlow: 20,
  returnOnEquity: returnOnEquity,
  returnOnInvestedCapital: 0.17,
  netDebtToEbitda: 1.5,
  debtToEquity: debtToEquity,
  currentRatio: 2.5,
  operatingMargin: 0.2,
  grossMargin: 0.4,
  rsi14: rsi14,
);

/// Una empresa con solo los ratios del proveedor: sin cuentas ni histórico.
StockData _withProviderRatios({double? debtToEquity = 0.5}) => StockData(
  overview: _overviewWithRatios(debtToEquity: debtToEquity),
  dailyBars: const [],
  annualIncome: const [],
  quarterlyIncome: const [],
  annualBalance: const [],
  quarterlyBalance: const [],
  annualCashFlow: const [],
  quarterlyCashFlow: const [],
  quarterlyEarnings: const [],
  fetchedAt: DateTime.utc(2026, 10, 6),
);
