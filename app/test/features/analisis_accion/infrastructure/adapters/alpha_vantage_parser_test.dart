import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/stock_data.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/rules/flag_rules.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/stock_analyzer.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/alpha_vantage_error_detector.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/alpha_vantage_parser.dart';

import '../../../../fixtures/alpha_vantage_fixtures.dart';

Json _fixture(String name) =>
    decodeAlphaVantageBody(readAlphaVantageFixture(name));

Json _balanceWith(Map<String, String> fields) => {
  'annualReports': [
    {'fiscalDateEnding': '2025-12-31', ...fields},
  ],
  'quarterlyReports': <Object?>[],
};

Json _cashFlowWith(Map<String, String> fields) => {
  'annualReports': [
    {'fiscalDateEnding': '2025-12-31', ...fields},
  ],
  'quarterlyReports': <Object?>[],
};

void main() {
  group('parseOverview', () {
    test('convierte el perfil real de IBM', () {
      final overview = parseOverview(_fixture('overview_ibm'));

      expect(overview.symbol, 'IBM');
      expect(overview.name, 'International Business Machines');
      expect(overview.sector, 'TECHNOLOGY');
      expect(overview.currency, 'USD');
      expect(overview.latestQuarter, DateTime(2026, 6, 30));
      expect(overview.marketCapitalization, 207260156000);
      expect(overview.sharesOutstanding, 942134000);
      expect(overview.peRatio, 19.61);
      expect(overview.forwardPe, 17.39);
      expect(overview.pegRatio, 2.188);
      expect(overview.evToEbitda, 15.66);
      expect(overview.dividendYield, 0.0305);
      expect(overview.movingAverage200, 256.8);
      expect(overview.week52High, 330.09);
    });

    test('convierte "None", "-" y vacío en null, nunca en 0', () {
      final overview = parseOverview({
        'Symbol': 'X',
        'Name': 'X Corp',
        'PERatio': 'None',
        'PEGRatio': '-',
        'Beta': '',
        'Sector': 'None',
      });

      expect(overview.peRatio, isNull);
      expect(overview.pegRatio, isNull);
      expect(overview.beta, isNull);
      expect(overview.sector, isNull);
    });

    test('sin símbolo es una respuesta no válida', () {
      expect(
        () => parseOverview({'Name': 'X Corp'}),
        throwsA(isA<InvalidResponseException>()),
      );
    });
  });

  group('parseDailySeries', () {
    test('convierte el histórico compacto real de IBM', () {
      final bars = parseDailySeries(_fixture('time_series_daily_compact_ibm'));
      final lastSession = bars.firstWhere(
        (b) => b.date == DateTime(2026, 9, 29),
      );

      expect(bars, hasLength(100));
      expect(lastSession.open, 220.865);
      expect(lastSession.high, 223.12);
      expect(lastSession.low, 219.91);
      expect(lastSession.close, 219.99);
      expect(lastSession.volume, 3766484);
    });

    test('sin serie es una respuesta no válida', () {
      expect(
        () => parseDailySeries({'Meta Data': <String, Object?>{}}),
        throwsA(isA<InvalidResponseException>()),
      );
    });
  });

  group('parseIncomeStatements', () {
    test('convierte las cuentas reales de IBM', () {
      final reports = parseIncomeStatements(_fixture('income_statement_ibm'));
      final latest = reports.annual.first;

      expect(reports.annual, hasLength(20));
      expect(reports.quarterly, hasLength(81));
      expect(latest.fiscalDateEnding, DateTime(2025, 12, 31));
      expect(latest.totalRevenue, 67536000000);
      expect(latest.operatingIncome, 12492000000);
      expect(latest.ebitda, 17284000000);
      expect(latest.interestExpense, 1935000000);
      expect(latest.netIncome, 10593000000);
    });

    test('conserva el signo de un impuesto negativo (devolución)', () {
      final reports = parseIncomeStatements(_fixture('income_statement_ibm'));

      expect(reports.annual.first.incomeTaxExpense, -242000000);
    });

    test('pone en positivo los gastos financieros', () {
      final reports = parseIncomeStatements({
        'annualReports': [
          {'fiscalDateEnding': '2025-12-31', 'interestExpense': '-150'},
        ],
        'quarterlyReports': <Object?>[],
      });

      expect(reports.annual.single.interestExpense, 150);
    });

    test('sin fecha de cierre es una respuesta no válida', () {
      expect(
        () => parseIncomeStatements({
          'annualReports': [
            {'totalRevenue': '100'},
          ],
          'quarterlyReports': <Object?>[],
        }),
        throwsA(isA<InvalidResponseException>()),
      );
    });
  });

  group('parseBalanceSheets', () {
    test('convierte el balance real de IBM', () {
      final latest = parseBalanceSheets(_fixture('balance_sheet_ibm'))
          .annual
          .first;

      expect(latest.totalDebt, 67154000000);
      expect(latest.cashAndShortTermInvestments, 13641000000);
      expect(latest.totalShareholderEquity, 32648000000);
      expect(latest.sharesOutstanding, 948700000);
    });

    test('sin deuda total suma la de corto y largo plazo', () {
      final balance = parseBalanceSheets(
        _balanceWith({
          'shortLongTermDebtTotal': 'None',
          'shortTermDebt': '100',
          'longTermDebt': '400',
        }),
      ).annual.single;

      expect(balance.totalDebt, 500);
    });

    test('sin ningún dato de deuda la deuda es null', () {
      final balance = parseBalanceSheets(
        _balanceWith({'shortLongTermDebtTotal': 'None'}),
      ).annual.single;

      expect(balance.totalDebt, isNull);
    });

    test('sin caja e inversiones usa la caja y equivalentes', () {
      final balance = parseBalanceSheets(
        _balanceWith({
          'cashAndShortTermInvestments': 'None',
          'cashAndCashEquivalentsAtCarryingValue': '75',
        }),
      ).annual.single;

      expect(balance.cashAndShortTermInvestments, 75);
    });
  });

  group('parseCashFlows', () {
    test('convierte los flujos reales de IBM', () {
      final latest = parseCashFlows(_fixture('cash_flow_ibm')).annual.first;

      expect(latest.operatingCashflow, 13193000000);
      expect(latest.capitalExpenditures, 1091000000);
      expect(latest.dividendPayout, 6255000000);
    });

    test('pone en positivo el CAPEX y los dividendos', () {
      final cashFlow = parseCashFlows(
        _cashFlowWith({'capitalExpenditures': '-500', 'dividendPayout': '-80'}),
      ).annual.single;

      expect(cashFlow.capitalExpenditures, 500);
      expect(cashFlow.dividendPayout, 80);
    });
  });

  group('parseEarnings', () {
    test('convierte los resultados trimestrales reales de IBM', () {
      final earnings = parseEarnings(_fixture('earnings_ibm'));
      final latest = earnings.first;

      expect(earnings, hasLength(122));
      expect(latest.fiscalDateEnding, DateTime(2026, 6, 30));
      expect(latest.reportedDate, DateTime(2026, 7, 22));
      expect(latest.reportedEps, 2.93);
      expect(latest.estimatedEps, 2.93);
    });
  });

  group('parseSymbolSearch', () {
    test('convierte la búsqueda real de "tesco"', () {
      final matches = parseSymbolSearch(_fixture('symbol_search_tesco'));
      final first = matches.first;

      expect(matches, hasLength(5));
      expect(first.symbol, 'TSCO.LON');
      expect(first.name, 'Tesco PLC');
      expect(first.region, 'United Kingdom');
      expect(first.currency, 'GBX');
      expect(first.matchScore, 0.7273);
    });

    test('una búsqueda sin coincidencias da una lista vacía', () {
      expect(parseSymbolSearch(_fixture('symbol_search_no_results')), isEmpty);
    });
  });

  group('con todos los datos reales de IBM', () {
    test('el motor analiza el resultado del parser sin errores', () {
      final income = parseIncomeStatements(_fixture('income_statement_ibm'));
      final balance = parseBalanceSheets(_fixture('balance_sheet_ibm'));
      final cashFlow = parseCashFlows(_fixture('cash_flow_ibm'));
      final data = StockData(
        overview: parseOverview(_fixture('overview_ibm')),
        dailyBars: parseDailySeries(_fixture('time_series_daily_compact_ibm')),
        annualIncome: income.annual,
        quarterlyIncome: income.quarterly,
        annualBalance: balance.annual,
        quarterlyBalance: balance.quarterly,
        annualCashFlow: cashFlow.annual,
        quarterlyCashFlow: cashFlow.quarterly,
        quarterlyEarnings: parseEarnings(_fixture('earnings_ibm')),
        fetchedAt: DateTime(2026, 9, 30),
      );

      final result = const StockAnalyzer().analyze(
        data,
        referenceDate: DateTime(2026, 9, 30),
      );

      expect(result.symbol, 'IBM');
      expect(result.price, 219.99);
      expect(result.verdict, isNot(Verdict.insufficientData));
      expect(result.blocks.every((b) => b.score != null), isTrue);
      // Plan gratuito: solo 100 sesiones de histórico.
      expect(result.flags, contains(shortHistoryText));
    });
  });
}
