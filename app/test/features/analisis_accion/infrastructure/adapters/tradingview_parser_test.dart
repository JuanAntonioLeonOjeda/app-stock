import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/stock_data.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';
import 'package:stock_app/features/analisis_accion/domain/search/group_listings.dart';
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
  _searchPipelineTests();
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

    test('conserva el orden de relevancia del proveedor', () {
      final matches = parseTradingViewSearch(
        readTradingViewFixture('search_nintendo'),
      );
      final scores = [for (final m in matches) m.matchScore];

      expect(scores.first, 1);
      expect(scores, [...scores]..sort((a, b) => b.compareTo(a)));
    });

    test('marca la cotización principal y la bolsa de origen', () {
      final first = parseTradingViewSearch(
        readTradingViewFixture('search_nintendo'),
      ).first;

      expect(first.isPrimaryListing, isTrue);
      expect(first.isin, 'JP3756600007');
      expect(first.exchange, 'TSE');
      expect(first.exchangeName, 'Tokyo Stock Exchange');
      expect(first.isDepositaryReceipt, isFalse);
    });

    test('las demás cotizaciones no son la principal y comparten el ISIN', () {
      final matches = parseTradingViewSearch(
        readTradingViewFixture('search_nintendo'),
      );
      final others = matches.where((m) => m.symbol == 'GETTEX:NTO').single;

      expect(others.isPrimaryListing, isFalse);
      expect(others.isin, 'JP3756600007');
      expect(others.currency, 'EUR');
    });

    test('los certificados ADR se marcan y tienen otro ISIN', () {
      final matches = parseTradingViewSearch(
        readTradingViewFixture('search_nintendo'),
      );
      final adr = matches.where((m) => m.symbol == 'OTC:NTDOY').single;

      expect(adr.isDepositaryReceipt, isTrue);
      expect(adr.isin, isNot('JP3756600007'));
    });

    test('no recorta la lista: devuelve todo lo que trae el proveedor', () {
      final matches = parseTradingViewSearch(
        readTradingViewFixture('search_apple'),
      );

      expect(matches.length, greaterThan(15));
    });

    test(
      'un resultado sin ISIN llega con isin null (el dominio lo descarta)',
      () {
        final matches = parseTradingViewSearch(
          readTradingViewFixture('search_apple'),
        );

        expect(matches.where((m) => m.isin == null), isNotEmpty);
      },
    );

    test('descarta lo que no es acción ni certificado', () {
      final matches = parseTradingViewSearch(
        readTradingViewFixture('search_inditex'),
      );

      expect(matches.every((m) => m.symbol.startsWith('OTC:')), isTrue);
    });

    test('"inditex" no trae la cotización principal de Madrid', () {
      final matches = parseTradingViewSearch(
        readTradingViewFixture('search_inditex'),
      );

      expect(matches.any((m) => m.isPrimaryListing), isFalse);
      expect(matches.any((m) => m.symbol == 'BME:ITX'), isFalse);
    });

    test('buscar por el ISIN trae la principal de Madrid', () {
      final matches = parseTradingViewSearch(
        readTradingViewFixture('search_isin_inditex'),
      );
      final main = matches.where((m) => m.symbol == 'BME:ITX').single;

      expect(main.isPrimaryListing, isTrue);
      expect(main.currency, 'EUR');
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

    test(
      'lleva el ISIN, la bolsa y si es la cotización principal (criterio 80)',
      () {
        final overview = _parse('scan_tse_7974').overview;

        expect(overview.isin, 'JP3756600007');
        expect(overview.exchange, 'TSE');
        expect(overview.isPrimaryListing, isTrue);
      },
    );

    test('un ADR no es la cotización principal y tiene otro ISIN', () {
      final overview = _parse('scan_otc_ntdoy').overview;

      expect(overview.isPrimaryListing, isFalse);
      expect(overview.isin, 'US6544453037');
      expect(overview.exchange, 'OTC');
    });

    test('Iberdrola es principal en Madrid', () {
      final overview = _parse('scan_bme_ibe').overview;

      expect(overview.isin, 'ES0144580Y14');
      expect(overview.exchange, 'BME');
      expect(overview.isPrimaryListing, isTrue);
    });

    test('si el proveedor no da esos datos quedan en null, no en falso', () {
      final body = _withField('scan_tse_7974', 'is_primary', null);

      final overview = parseTradingViewScan(
        body,
        fetchedAt: _fetchedAt,
      ).overview;

      expect(overview.isPrimaryListing, isNull);
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

// La búsqueda real, de punta a punta: parser + agrupación por ISIN.
void _searchPipelineTests() {
  group('búsqueda real agrupada por ISIN', () {
    test(
      'Nintendo sale como una empresa con la principal de Tokio (criterio 72)',
      () {
        final companies = groupListings(
          parseTradingViewSearch(readTradingViewFixture('search_nintendo')),
        );
        final nintendo = companies.firstWhere((c) => c.isin == 'JP3756600007');

        expect(nintendo.defaultListing.symbol, 'TSE:7974');
        expect(nintendo.hasConfirmedPrimary, isTrue);
        expect(nintendo.others.length, greaterThan(5));
      },
    );

    test('las 14 versiones de Nintendo quedan en pocas filas', () {
      final companies = groupListings(
        parseTradingViewSearch(readTradingViewFixture('search_nintendo')),
      );

      expect(companies.length, lessThan(6));
    });

    test('los ADR de Nintendo van aparte y al final', () {
      final companies = groupListings(
        parseTradingViewSearch(readTradingViewFixture('search_nintendo')),
      );
      final adrIndex = companies.indexWhere((c) => c.isDepositaryReceipt);

      expect(adrIndex, greaterThan(0));
      expect(
        companies.skip(adrIndex).every((c) => c.isDepositaryReceipt),
        isTrue,
      );
    });

    test('Iberdrola sale con la principal de Madrid y las de Fráncfort en euros primero', () {
      final iberdrola = groupListings(
        parseTradingViewSearch(readTradingViewFixture('search_iberdrola')),
      ).firstWhere((c) => c.isin == 'ES0144580Y14');

      expect(iberdrola.defaultListing.symbol, 'BME:IBE');
      expect(iberdrola.others.first.currency, 'EUR');
    });

    test('"inditex" necesita completar el grupo con el ISIN (criterio 77)', () {
      final byName = parseTradingViewSearch(
        readTradingViewFixture('search_inditex'),
      );

      expect(isinsMissingPrimary(byName), ['ES0148396007']);
    });

    test(
      'completado con la búsqueda por ISIN, aparece BME:ITX como principal',
      () {
        final merged = [
          ...parseTradingViewSearch(readTradingViewFixture('search_inditex')),
          ...parseTradingViewSearch(
            readTradingViewFixture('search_isin_inditex'),
          ),
        ];

        final inditex = groupListings(merged)
            .firstWhere((c) => c.isin == 'ES0148396007');

        expect(inditex.defaultListing.symbol, 'BME:ITX');
        expect(inditex.hasConfirmedPrimary, isTrue);
        expect(isinsMissingPrimary(merged), isEmpty);
      },
    );

    test('buscar por ISIN agrupa todas sus cotizaciones en una empresa (criterio 78)', () {
      final companies = groupListings(
        parseTradingViewSearch(readTradingViewFixture('search_isin_nintendo')),
      );

      expect(companies, hasLength(1));
      expect(companies.single.defaultListing.symbol, 'TSE:7974');
    });

    test('Apple no mezcla otras empresas parecidas ni instrumentos sin ISIN (criterio 76)', () {
      final companies = groupListings(
        parseTradingViewSearch(readTradingViewFixture('search_apple')),
      );

      expect(companies.first.isin, 'US0378331005');
      expect(companies.every((c) => c.isin.isNotEmpty), isTrue);
      expect(
        companies
            .expand((c) => [c.defaultListing, ...c.others])
            .any((m) => m.symbol == 'Pyth:AAPL'),
        isFalse,
      );
    });
  });
}
