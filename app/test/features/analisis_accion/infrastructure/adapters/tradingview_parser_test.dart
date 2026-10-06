import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/stock_data.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/tradingview_fields.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/tradingview_parser.dart';

import '../../../../fixtures/tradingview_fixtures.dart';

final _fetchedAt = DateTime.utc(2026, 10, 6, 12);

StockData _parse(String fixture) => parseTradingViewScan(
  readTradingViewFixture(fixture),
  fetchedAt: _fetchedAt,
);

/// La fixture con un campo sustituido, para probar respuestas raras.
String _withField(String fixture, String field, Object? value) {
  final json =
      jsonDecode(readTradingViewFixture(fixture)) as Map<String, Object?>;
  final row = (json['data']! as List<Object?>).first! as Map<String, Object?>;
  final values = row['d']! as List<Object?>;
  values[tradingViewFields.indexOf(field)] = value;
  return jsonEncode(json);
}

void main() {
  group('tradingViewFields', () {
    test('cada campo pedido existe en la respuesta real de AAPL', () {
      final json = jsonDecode(
        readTradingViewFixture('scan_nasdaq_aapl'),
      ) as Map<String, Object?>;
      final row =
          (json['data']! as List<Object?>).first! as Map<String, Object?>;
      final values = row['d']! as List<Object?>;

      expect(values, hasLength(tradingViewFields.length));
      // Un campo desconocido llega como null sin error: AAPL tiene dato en
      // todos los que el parser necesita.
      const requiredFields = [
        'description',
        'currency',
        'close',
        'time',
        'price_earnings_ttm',
        'RSI',
        'SMA200',
        'return_on_equity',
        'fiscal_period_end_fy',
        'fiscal_period_end_current',
        'total_revenue_fy_h',
        'net_income_fy_h',
        'total_revenue_fq_h',
        'net_income_fq_h',
      ];
      for (final field in requiredFields) {
        expect(
          values[tradingViewFields.indexOf(field)],
          isNotNull,
          reason: field,
        );
      }
    });
  });

  group('parseTradingViewSearch', () {
    test('devuelve BOLSA:TICKER con la cotización de origen primero', () {
      final matches = parseTradingViewSearch(
        readTradingViewFixture('search_nintendo'),
      );

      expect(matches.first.symbol, 'TSE:7974');
      expect(matches.first.name, 'Nintendo Co., Ltd.');
      expect(matches.first.currency, 'JPY');
      expect(matches.first.region, 'JP');
    });

    test('quita el resaltado <em> del nombre', () {
      final matches = parseTradingViewSearch(
        readTradingViewFixture('search_nintendo'),
      );

      expect(matches.every((m) => !m.name.contains('<em>')), isTrue);
    });

    test('ordena por relevancia y pone los ADR tras las acciones', () {
      final matches = parseTradingViewSearch(
        readTradingViewFixture('search_nintendo'),
      );
      final scores = [for (final m in matches) m.matchScore];

      expect(scores, [...scores]..sort((a, b) => b.compareTo(a)));
      // En la respuesta del proveedor el ADR de OTC es el 2.º resultado.
      expect([
        for (final m in matches.take(5)) m.symbol,
      ], isNot(contains('OTC:NTDOY')));
    });

    test('sin resultados devuelve una lista vacía', () {
      expect(
        parseTradingViewSearch(readTradingViewFixture('search_no_results')),
        isEmpty,
      );
    });

    test('una respuesta que no es JSON es inválida', () {
      expect(
        () => parseTradingViewSearch('<html>bloqueado</html>'),
        throwsA(isA<InvalidResponseException>()),
      );
    });
  });

  group('parseTradingViewScan', () {
    test('Nintendo: precio, moneda y fecha del último cierre', () {
      final data = _parse('scan_tse_7974');

      expect(data.overview.symbol, 'TSE:7974');
      expect(data.overview.name, 'Nintendo Co., Ltd.');
      expect(data.overview.currency, 'JPY');
      expect(data.dailyBars, hasLength(1));
      expect(data.dailyBars.single.close, 7815);
      expect(data.dailyBars.single.date, DateTime.utc(2026, 10, 6));
      expect(data.fetchedAt, _fetchedAt);
    });

    test('los porcentajes del proveedor pasan a fracción', () {
      final overview = _parse('scan_tse_7974').overview;

      expect(overview.returnOnEquity, closeTo(0.169, 0.001));
      expect(overview.operatingMargin, closeTo(0.197, 0.001));
      expect(overview.dividendYield, closeTo(0.0209, 0.0001));
    });

    test('los ratios sin unidad se conservan tal cual', () {
      final overview = _parse('scan_tse_7974').overview;

      expect(overview.peRatio, closeTo(19.07, 0.01));
      expect(overview.priceToBook, closeTo(3.09, 0.01));
      expect(overview.rsi14, closeTo(39.35, 0.01));
    });

    test('un dato que el proveedor no da queda null, nunca 0', () {
      final overview = _parse('scan_tse_7974').overview;

      expect(overview.priceToFreeCashFlow, isNull);
      expect(overview.analystTargetPrice, isNull);
      expect(overview.forwardPe, isNull);
    });

    test('la capitalización (en USD) no se usa para no mezclar monedas', () {
      expect(_parse('scan_tse_7974').overview.marketCapitalization, isNull);
    });

    test('deuda neta/EBITDA sale de dos escalares en la misma moneda', () {
      // Nintendo tiene caja neta: deuda neta negativa.
      expect(_parse('scan_tse_7974').overview.netDebtToEbitda, lessThan(0));
    });

    test('las series anuales llevan fechas de cierre hacia atrás', () {
      final data = _parse('scan_tse_7974');

      expect(
        data.annualIncome.first.fiscalDateEnding,
        DateTime.utc(2026, 3, 31),
      );
      expect(data.annualIncome[1].fiscalDateEnding, DateTime.utc(2025, 3, 31));
      expect(data.annualIncome, hasLength(20));
    });

    test('las trimestrales restan 3 meses y respetan el fin de mes', () {
      final data = _parse('scan_tse_9983');
      final dates = [
        for (final s in data.quarterlyIncome.take(4)) s.fiscalDateEnding,
      ];

      // Fast Retailing cierra trimestre el 31 de mayo.
      expect(dates, [
        DateTime.utc(2026, 5, 31),
        DateTime.utc(2026, 2, 28),
        DateTime.utc(2025, 11, 30),
        DateTime.utc(2025, 8, 31),
      ]);
    });

    test('las series quedan del más reciente al más antiguo', () {
      final income = _parse('scan_tse_7974').annualIncome;

      expect(income.first.totalRevenue, 2313051000000);
      expect(income.first.netIncome, 424056000000);
    });

    test(
      'en una cotización local las series declaran la moneda del precio',
      () {
        expect(
          _parse('scan_bme_ibe').annualIncome.first.reportedCurrency,
          'EUR',
        );
      },
    );

    test('en un ADR la moneda de reporte queda sin indicar', () {
      final data = _parse('scan_otc_ntdoy');

      expect(data.overview.currency, 'USD');
      expect(data.annualIncome.first.reportedCurrency, isNull);
    });

    test('el flujo de caja libre se guarda como flujo operativo sin CAPEX', () {
      final cashFlow = _parse('scan_tse_7974').annualCashFlow.first;

      expect(cashFlow.operatingCashflow, 262620000000);
      expect(cashFlow.capitalExpenditures, 0);
    });

    test('lo que el proveedor no da por periodo queda null', () {
      final income = _parse('scan_tse_7974').annualIncome.first;

      expect(income.operatingIncome, isNull);
      expect(income.interestExpense, isNull);
      expect(_parse('scan_tse_7974').quarterlyEarnings, isEmpty);
    });

    test('un símbolo sin filas es NotFound', () {
      expect(
        () => parseTradingViewScan(
          readTradingViewFixture('scan_unknown_symbol'),
          fetchedAt: _fetchedAt,
        ),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('sin precio es NotFound', () {
      expect(
        () => parseTradingViewScan(
          _withField('scan_tse_7974', 'close', null),
          fetchedAt: _fetchedAt,
        ),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('un campo numérico que llega como texto es inválido', () {
      expect(
        () => parseTradingViewScan(
          _withField('scan_tse_7974', 'price_earnings_ttm', 'N/A'),
          fetchedAt: _fetchedAt,
        ),
        throwsA(isA<InvalidResponseException>()),
      );
    });

    test('una fila con distinto número de campos es inválida', () {
      expect(
        () => parseTradingViewScan(
          '{"data":[{"s":"TSE:7974","d":[1,2]}]}',
          fetchedAt: _fetchedAt,
        ),
        throwsA(isA<InvalidResponseException>()),
      );
    });

    test('un cuerpo que no es JSON es inválido', () {
      expect(
        () => parseTradingViewScan('no json', fetchedAt: _fetchedAt),
        throwsA(isA<InvalidResponseException>()),
      );
    });
  });
}
