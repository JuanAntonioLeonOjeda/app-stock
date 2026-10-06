import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/income_statement.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/stock_data.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/indicators/metric_value.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/rules/flag_rules.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/scoring/flag_detector.dart';

import '../synthetic_companies.dart';

List<String> _flags(
  StockData data, {
  Map<String, MetricValue> values = const {},
  bool isCapped = false,
  DateTime? at,
}) => detectFlags(
  data: data,
  values: values,
  isVerdictCappedByHealth: isCapped,
  referenceDate: at ?? referenceDate,
);

/// [data] con otra cuenta de resultados trimestral.
StockData _withQuarterlyIncome(
  StockData data,
  List<IncomeStatement> quarterly,
) => StockData(
  overview: data.overview,
  dailyBars: data.dailyBars,
  annualIncome: data.annualIncome,
  quarterlyIncome: quarterly,
  annualBalance: data.annualBalance,
  quarterlyBalance: data.quarterlyBalance,
  annualCashFlow: data.annualCashFlow,
  quarterlyCashFlow: data.quarterlyCashFlow,
  quarterlyEarnings: data.quarterlyEarnings,
  fetchedAt: data.fetchedAt,
);

IncomeStatement _quarter(DateTime date, double operatingMargin) =>
    IncomeStatement(
      fiscalDateEnding: date,
      reportedCurrency: 'USD',
      totalRevenue: 100,
      grossProfit: 60,
      operatingIncome: 100 * operatingMargin,
      ebit: 100 * operatingMargin,
      ebitda: 100 * operatingMargin + 10,
      interestExpense: 1,
      incomeBeforeTax: 100 * operatingMargin - 1,
      incomeTaxExpense: 2,
      netIncome: 100 * operatingMargin - 3,
    );

void main() {
  group('detectFlags', () {
    test('una empresa sana y con datos al día no tiene avisos', () {
      expect(_flags(qualityCompany()), isEmpty);
    });

    test('avisa, en primer lugar, del veredicto limitado por la salud', () {
      final flags = _flags(qualityCompany(), isCapped: true);

      expect(flags.first, verdictCappedByHealthText);
    });

    test('avisa de precios de hace más de 7 días', () {
      final flags = _flags(
        qualityCompany(),
        at: referenceDate.add(const Duration(days: 10)),
      );

      expect(flags, contains(stalePriceText));
    });

    test('avisa de histórico corto', () {
      final data = buildCompany(dailyBars: priceHistory(sessions: 150));

      expect(_flags(data), contains(shortHistoryText));
    });

    test('con una sola barra avisa de que no hay histórico de precios', () {
      final data = buildCompany(dailyBars: priceHistory(sessions: 1));

      final flags = _flags(data);

      expect(flags, contains(noPriceHistoryText));
      expect(flags, isNot(contains(shortHistoryText)));
    });

    test('con histórico suficiente no avisa de histórico', () {
      final flags = _flags(buildCompany());

      expect(flags, isNot(contains(noPriceHistoryText)));
      expect(flags, isNot(contains(shortHistoryText)));
    });

    test('avisa si el último trimestre tiene más de 6 meses', () {
      final flags = _flags(
        qualityCompany(),
        at: referenceDate.add(const Duration(days: 120)),
      );

      expect(flags, contains(staleQuarterText));
    });

    test('avisa si la capitalización no cuadra con precio × acciones', () {
      final data = buildCompany(
        companyOverview: overview(marketCapitalization: 10000),
      );

      expect(_flags(data), contains(marketCapMismatchText));
    });

    test('avisa si los informes y la cotización tienen divisas distintas', () {
      final data = buildCompany(companyOverview: overview(currency: 'EUR'));

      expect(_flags(data), contains(currencyMismatchText('USD', 'EUR')));
    });

    test('avisa de resultados probables en los próximos 14 días', () {
      final soon = buildCompany(
        lastEarningsReportedDate: referenceDate.subtract(
          const Duration(days: 85),
        ),
      );

      expect(_flags(soon), contains(earningsSoonText));
      expect(_flags(qualityCompany()), isNot(contains(earningsSoonText)));
    });

    test('avisa si el beneficio sube mientras el FCF baja 2 años '
        'seguidos', () {
      final data = buildCompany(
        annualOperatingCashflow: const [200, 250, 300, 310, 320],
      );

      expect(_flags(data), contains(profitUpCashDownText));
    });

    test('avisa si el margen operativo trimestral cae 3 trimestres '
        'seguidos', () {
      final data = _withQuarterlyIncome(qualityCompany(), [
        _quarter(DateTime(2026, 6, 30), 0.10),
        _quarter(DateTime(2026, 3, 31), 0.12),
        _quarter(DateTime(2025, 12, 31), 0.14),
        _quarter(DateTime(2025, 9, 30), 0.16),
      ]);

      expect(_flags(data), contains(fallingQuarterlyMarginText));
    });

    test('avisa de dilución superior al 5 % anual', () {
      final flags = _flags(
        qualityCompany(),
        values: {'dilucion': const MetricValue(0.06)},
      );

      expect(flags, contains(dilutionAlarmText));
    });

    test('avisa de deuda neta superior a 4 veces el EBITDA', () {
      final flags = _flags(
        qualityCompany(),
        values: {'deuda_ebitda': const MetricValue(4.5)},
      );

      expect(flags, contains(netDebtToEbitdaAlarmText));
    });

    test('avisa de patrimonio neto negativo', () {
      expect(_flags(buildCompany(equity: -100)), contains(negativeEquityText));
    });

    test('avisa de rentabilidad por dividendo superior al 7 %', () {
      final data = buildCompany(companyOverview: overview(dividendYield: 0.08));

      expect(_flags(data), contains(dividendYieldAlarmText));
    });
  });
}
