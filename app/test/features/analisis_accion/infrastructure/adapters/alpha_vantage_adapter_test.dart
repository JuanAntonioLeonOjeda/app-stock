import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/fetch_step.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/alpha_vantage_adapter.dart';

import '../../../../fixtures/alpha_vantage_fixtures.dart';
import '../../application/fake_ports.dart';

const _apiKey = 'CLAVE_DE_TEST_123';

const _rateLimitBody =
    '{"Information": "Thank you for using Alpha Vantage! Our standard API '
    'rate limit is 25 requests per day."}';

/// Respuesta real (fixture) de IBM para cada función de la API.
const _fixtureByFunction = {
  'OVERVIEW': 'overview_ibm',
  'INCOME_STATEMENT': 'income_statement_ibm',
  'BALANCE_SHEET': 'balance_sheet_ibm',
  'CASH_FLOW': 'cash_flow_ibm',
  'EARNINGS': 'earnings_ibm',
  'SYMBOL_SEARCH': 'symbol_search_tesco',
};

/// API simulada: registra cada petición y responde con los fixtures reales.
/// [overrides] sustituye la respuesta de una función (clave = función).
class _FakeApi {
  _FakeApi({this.overrides = const {}});

  final Map<String, http.Response> overrides;
  final List<Uri> requests = [];

  List<String> get functions => [
    for (final uri in requests)
      [
        uri.queryParameters['function'],
        ?uri.queryParameters['outputsize'],
      ].join(':'),
  ];

  late final client = MockClient((request) async {
    requests.add(request.url);
    final function = request.url.queryParameters['function']!;
    final override = overrides[function];
    if (override != null) return override;
    if (function == 'TIME_SERIES_DAILY') {
      final isFull = request.url.queryParameters['outputsize'] == 'full';
      return _fixture(
        isFull ? 'time_series_daily_full_ibm' : 'time_series_daily_compact_ibm',
      );
    }
    return _fixture(_fixtureByFunction[function]!);
  });

  static http.Response _fixture(String name) => http.Response.bytes(
    utf8.encode(readAlphaVantageFixture(name)),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

AlphaVantageAdapter _adapter(
  _FakeApi api,
  FakeCache cache, {
  String apiKey = _apiKey,
  Duration pause = Duration.zero,
  List<Duration>? delays,
}) => AlphaVantageAdapter(
  client: api.client,
  cache: cache,
  apiKey: apiKey,
  pauseBetweenRequests: pause,
  delay: (duration) async => delays?.add(duration),
  now: () => DateTime(2026, 9, 30),
);

const _allEndpointsWithPremiumRetry = [
  'OVERVIEW',
  'TIME_SERIES_DAILY:full',
  'TIME_SERIES_DAILY',
  'INCOME_STATEMENT',
  'BALANCE_SHEET',
  'CASH_FLOW',
  'EARNINGS',
];

void main() {
  group('AlphaVantageAdapter.fetchStockData', () {
    test('pide los 6 endpoints y, si el histórico completo es de pago, '
        'reintenta con el compacto', () async {
      final api = _FakeApi();
      final cache = FakeCache();

      final data = await _adapter(api, cache).fetchStockData('IBM');

      expect(api.functions, _allEndpointsWithPremiumRetry);
      expect(data.overview.symbol, 'IBM');
      expect(data.dailyBars, hasLength(100));
      expect(data.annualIncome, hasLength(20));
      expect(data.quarterlyEarnings, hasLength(122));
      expect(cache.values, contains(fullHistoryUnavailableKey));
    });

    test('recuerda que el histórico completo es de pago y no lo vuelve a '
        'intentar', () async {
      final api = _FakeApi();
      final cache = FakeCache();
      final adapter = _adapter(api, cache);
      await adapter.fetchStockData('IBM');
      api.requests.clear();

      await adapter.fetchStockData('IBM', forceRefresh: true);

      expect(api.functions, isNot(contains('TIME_SERIES_DAILY:full')));
      expect(api.functions, hasLength(6));
    });

    test('con todo en caché no hace ninguna petición', () async {
      final api = _FakeApi();
      final cache = FakeCache();
      final adapter = _adapter(api, cache);
      await adapter.fetchStockData('IBM');
      api.requests.clear();

      final data = await adapter.fetchStockData('IBM');

      expect(api.requests, isEmpty);
      expect(data.dailyBars, hasLength(100));
    });

    test('solo pide lo que ha caducado', () async {
      final api = _FakeApi();
      final cache = FakeCache();
      final adapter = _adapter(api, cache);
      await adapter.fetchStockData('IBM');
      api.requests.clear();
      cache.expire('av:TIME_SERIES_DAILY:IBM');

      await adapter.fetchStockData('IBM');

      expect(api.functions, ['TIME_SERIES_DAILY']);
    });

    test('forceRefresh ignora la caché', () async {
      final api = _FakeApi();
      final cache = FakeCache();
      final adapter = _adapter(api, cache);
      await adapter.fetchStockData('IBM');
      api.requests.clear();

      await adapter.fetchStockData('IBM', forceRefresh: true);

      expect(api.requests, hasLength(6));
    });

    test('guarda cada respuesta con su caducidad', () async {
      final cache = FakeCache();

      await _adapter(_FakeApi(), cache).fetchStockData('IBM');

      expect(cache.ttls, {
        'av:OVERVIEW:IBM': const Duration(hours: 24),
        'av:TIME_SERIES_DAILY:IBM': const Duration(hours: 6),
        'av:INCOME_STATEMENT:IBM': const Duration(days: 7),
        'av:BALANCE_SHEET:IBM': const Duration(days: 7),
        'av:CASH_FLOW:IBM': const Duration(days: 7),
        'av:EARNINGS:IBM': const Duration(days: 7),
        fullHistoryUnavailableKey: const Duration(days: 30),
      });
    });

    test('informa de cada paso en orden', () async {
      final steps = <FetchStep>[];

      await _adapter(
        _FakeApi(),
        FakeCache(),
      ).fetchStockData('IBM', onProgress: steps.add);

      expect(steps, FetchStep.values);
    });

    test('normaliza el símbolo (espacios y minúsculas)', () async {
      final api = _FakeApi();

      await _adapter(api, FakeCache()).fetchStockData('  ibm ');

      expect(api.requests.first.queryParameters['symbol'], 'IBM');
    });

    test('un fallo a mitad conserva en caché lo ya obtenido', () async {
      final cache = FakeCache();
      final failingApi = _FakeApi(
        overrides: {'BALANCE_SHEET': http.Response(_rateLimitBody, 200)},
      );

      await expectLater(
        _adapter(failingApi, cache).fetchStockData('IBM'),
        throwsA(isA<RateLimitException>()),
      );
      final api = _FakeApi();
      await _adapter(api, cache).fetchStockData('IBM');

      expect(api.functions, ['BALANCE_SHEET', 'CASH_FLOW', 'EARNINGS']);
    });

    test('nunca guarda en caché una respuesta de error', () async {
      final cache = FakeCache();
      final api = _FakeApi(
        overrides: {'OVERVIEW': http.Response(_rateLimitBody, 200)},
      );

      await expectLater(
        _adapter(api, cache).fetchStockData('IBM'),
        throwsA(isA<RateLimitException>()),
      );

      expect(cache.values, isEmpty);
    });

    test('no guarda en caché una respuesta que el parser rechaza', () async {
      final cache = FakeCache();
      final api = _FakeApi(
        overrides: {'OVERVIEW': http.Response('{"Name": "Sin símbolo"}', 200)},
      );

      await expectLater(
        _adapter(api, cache).fetchStockData('IBM'),
        throwsA(isA<InvalidResponseException>()),
      );

      expect(cache.values, isEmpty);
    });

    test('un símbolo inexistente es NotFoundException', () async {
      final api = _FakeApi(
        overrides: {
          'OVERVIEW': http.Response(
            readAlphaVantageFixture('overview_unknown_symbol'),
            200,
          ),
        },
      );

      await expectLater(
        _adapter(api, FakeCache()).fetchStockData('NOEXISTE123'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('sin clave no hace ninguna petición', () async {
      final api = _FakeApi();

      await expectLater(
        _adapter(api, FakeCache(), apiKey: '  ').fetchStockData('IBM'),
        throwsA(isA<MissingApiKeyException>()),
      );
      expect(api.requests, isEmpty);
    });

    test('espera la pausa entre peticiones de red, no antes de la primera '
        'ni en las lecturas de caché', () async {
      final api = _FakeApi();
      final cache = FakeCache();
      final delays = <Duration>[];
      final adapter = _adapter(
        api,
        cache,
        pause: const Duration(milliseconds: 1200),
        delays: delays,
      );

      await adapter.fetchStockData('IBM');
      final delaysFirstFetch = delays.length;
      await adapter.fetchStockData('IBM');

      // 7 peticiones → 6 pausas; la segunda vez todo sale de la caché.
      expect(delaysFirstFetch, 6);
      expect(delays, hasLength(6));
      expect(delays.toSet(), {const Duration(milliseconds: 1200)});
    });
  });

  group('AlphaVantageAdapter: errores de red y HTTP', () {
    Future<void> expectFetchThrows<T>(MockClient client) => expectLater(
      AlphaVantageAdapter(
        client: client,
        cache: FakeCache(),
        apiKey: _apiKey,
        pauseBetweenRequests: Duration.zero,
      ).fetchStockData('IBM'),
      throwsA(isA<T>()),
    );

    test('un fallo de conexión es NetworkException sin la clave en el '
        'mensaje', () async {
      final client = MockClient(
        (request) async =>
            throw http.ClientException('Connection refused', request.url),
      );

      await expectLater(
        AlphaVantageAdapter(
          client: client,
          cache: FakeCache(),
          apiKey: _apiKey,
        ).fetchStockData('IBM'),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.toString(),
            'toString',
            isNot(contains(_apiKey)),
          ),
        ),
      );
    });

    test('HTTP 429 es RateLimitException', () async {
      await expectFetchThrows<RateLimitException>(
        MockClient((_) async => http.Response('', 429)),
      );
    });

    test('HTTP 5xx es NetworkException', () async {
      await expectFetchThrows<NetworkException>(
        MockClient((_) async => http.Response('', 503)),
      );
    });

    test('otro código HTTP es InvalidResponseException', () async {
      await expectFetchThrows<InvalidResponseException>(
        MockClient((_) async => http.Response('', 404)),
      );
    });
  });

  group('AlphaVantageAdapter.searchSymbol', () {
    test('devuelve las coincidencias de más a menos relevantes', () async {
      final matches = await _adapter(
        _FakeApi(),
        FakeCache(),
      ).searchSymbol('tesco');

      expect(matches.first.symbol, 'TSCO.LON');
      final scores = matches.map((m) => m.matchScore).toList();
      expect(scores, [...scores]..sort((a, b) => b.compareTo(a)));
    });

    test('la misma búsqueda sale de la caché 30 días', () async {
      final api = _FakeApi();
      final cache = FakeCache();
      final adapter = _adapter(api, cache);

      await adapter.searchSymbol('Tesco');
      await adapter.searchSymbol('  tesco ');

      expect(api.requests, hasLength(1));
      expect(cache.ttls['av:SYMBOL_SEARCH:tesco'], const Duration(days: 30));
    });

    test('un texto vacío no hace ninguna petición', () async {
      final api = _FakeApi();

      final matches = await _adapter(api, FakeCache()).searchSymbol('   ');

      expect(matches, isEmpty);
      expect(api.requests, isEmpty);
    });

    test('sin coincidencias devuelve una lista vacía', () async {
      final api = _FakeApi(
        overrides: {
          'SYMBOL_SEARCH': http.Response(
            readAlphaVantageFixture('symbol_search_no_results'),
            200,
          ),
        },
      );

      expect(await _adapter(api, FakeCache()).searchSymbol('zzqx'), isEmpty);
    });
  });

  test('la clave de la API nunca aparece en las claves de caché', () async {
    final cache = FakeCache();
    final adapter = _adapter(_FakeApi(), cache);

    await adapter.fetchStockData('IBM');
    await adapter.searchSymbol('tesco');

    expect(cache.values.keys.where((k) => k.contains(_apiKey)), isEmpty);
  });
}
