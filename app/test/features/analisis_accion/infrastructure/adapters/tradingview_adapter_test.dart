import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stock_app/features/analisis_accion/domain/chart/intraday_resolution.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/tradingview_chart_connection.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/tradingview_adapter.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/tradingview_fields.dart';

import '../../../../fixtures/tradingview_fixtures.dart';
import '../../application/fake_ports.dart';
import 'fake_chart_connection.dart';

final _now = DateTime.utc(2026, 10, 6, 12);

/// Servidor simulado: registra cada petición y responde con fixtures reales.
class _FakeServer {
  _FakeServer({
    this.override,
    this.searchFixtures = const {},
    this.failingSearches = const {},
  });

  final http.Response? override;

  /// Fixture que responde cada búsqueda, por texto en minúsculas; el resto
  /// responde con la de "nintendo".
  final Map<String, String> searchFixtures;

  /// Búsquedas (por texto en minúsculas) que fallan con HTTP 503.
  final Set<String> failingSearches;
  final List<http.Request> requests = [];

  /// Textos buscados, en orden.
  List<String> get searchedTexts => [
    for (final request in requests)
      if (request.url.host == 'symbol-search.tradingview.com')
        request.url.queryParameters['text']!,
  ];

  late final client = MockClient((request) async {
    requests.add(request);
    final fixed = override;
    if (fixed != null) return fixed;
    if (request.url.host == 'symbol-search.tradingview.com') {
      final text = request.url.queryParameters['text']!.toLowerCase();
      if (failingSearches.contains(text)) return http.Response('error', 503);
      return _json(
        readTradingViewFixture(searchFixtures[text] ?? 'search_nintendo'),
      );
    }
    return _json(readTradingViewFixture('scan_tse_7974'));
  });

  static http.Response _json(String body) => http.Response.bytes(
    utf8.encode(body),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

/// Canal de gráficos simulado: cada conexión reproduce un guion y se cuenta.
class _FakeChart {
  _FakeChart({List<String>? script, this.error, this.neverConnects = false})
    : script = script ?? readChartTranscript('chart_tse_7974').received;

  /// La conexión no llega nunca (simula un canal lento).
  final bool neverConnects;

  final List<String> script;
  final Object? error;
  final List<FakeChartConnection> connections = [];

  Future<ChartConnection> connect() async {
    final failure = error;
    if (failure != null) throw failure;
    if (neverConnects) return Completer<ChartConnection>().future;
    final connection = FakeChartConnection(script);
    connections.add(connection);
    return connection;
  }
}

TradingViewAdapter _adapter(
  _FakeServer server,
  FakeCache cache, {
  _FakeChart? chart,
}) => TradingViewAdapter(
  client: server.client,
  cache: cache,
  chartConnector: (chart ?? _FakeChart()).connect,
  now: () => _now,
);

/// Claves de la caché que guardan respuestas del scanner.
Iterable<String> _scanKeys(FakeCache cache) =>
    cache.values.keys.where((key) => key.startsWith('tv:v1:scan:'));

void main() {
  group('TradingViewAdapter.fetchStockData', () {
    test('pide al scanner el símbolo con todos los campos', () async {
      final server = _FakeServer();

      await _adapter(server, FakeCache()).fetchStockData('tse:7974');

      final request = server.requests.single;
      expect(request.method, 'POST');
      expect(request.url.host, 'scanner.tradingview.com');
      final body = jsonDecode(request.body) as Map<String, Object?>;
      expect(body['symbols'], {
        'tickers': ['TSE:7974'],
      });
      expect(body['columns'], tradingViewFields);
    });

    test('devuelve los datos normalizados', () async {
      final data = await _adapter(
        _FakeServer(),
        FakeCache(),
      ).fetchStockData('TSE:7974');

      expect(data.overview.name, 'Nintendo Co., Ltd.');
      expect(data.fetchedAt, _now);
    });

    test('una sola petición por análisis', () async {
      final server = _FakeServer();

      await _adapter(server, FakeCache()).fetchStockData('TSE:7974');

      expect(server.requests, hasLength(1));
    });

    test('guarda la respuesta en caché 6 horas', () async {
      final cache = FakeCache();

      await _adapter(_FakeServer(), cache).fetchStockData('TSE:7974');

      expect(cache.values.keys, contains('tv:v1:scan:TSE:7974'));
      expect(cache.ttls['tv:v1:scan:TSE:7974'], const Duration(hours: 6));
    });

    test('con la caché vigente no hace ninguna petición', () async {
      final cache = FakeCache();
      final server = _FakeServer();
      final adapter = _adapter(server, cache);
      await adapter.fetchStockData('TSE:7974');

      await adapter.fetchStockData('TSE:7974');

      expect(server.requests, hasLength(1));
    });

    test('con la caché caducada vuelve a pedir', () async {
      final cache = FakeCache();
      final server = _FakeServer();
      final adapter = _adapter(server, cache);
      await adapter.fetchStockData('TSE:7974');
      cache.expire('tv:v1:scan:TSE:7974');

      await adapter.fetchStockData('TSE:7974');

      expect(server.requests, hasLength(2));
    });

    test('forceRefresh ignora la caché', () async {
      final server = _FakeServer();
      final adapter = _adapter(server, FakeCache());
      await adapter.fetchStockData('TSE:7974');

      await adapter.fetchStockData('TSE:7974', forceRefresh: true);

      expect(server.requests, hasLength(2));
    });

    test('avisa del paso en curso', () async {
      final steps = <Object>[];

      await _adapter(
        _FakeServer(),
        FakeCache(),
      ).fetchStockData('TSE:7974', onProgress: steps.add);

      expect(steps, hasLength(1));
    });

    test('un símbolo vacío es NotFound sin hacer peticiones', () async {
      final server = _FakeServer();

      await expectLater(
        _adapter(server, FakeCache()).fetchStockData('  '),
        throwsA(isA<NotFoundException>()),
      );
      expect(server.requests, isEmpty);
    });

    test('un símbolo sin filas es NotFound y no se guarda', () async {
      final cache = FakeCache();
      final server = _FakeServer(
        override: http.Response(
          readTradingViewFixture('scan_unknown_symbol'),
          200,
        ),
      );

      await expectLater(
        _adapter(server, cache).fetchStockData('NASDAQ:ZZZZZZQ'),
        throwsA(isA<NotFoundException>()),
      );
      expect(_scanKeys(cache), isEmpty);
    });
  });

  group('TradingViewAdapter con una caché ilegible', () {
    test('ignora la entrada que ya no se puede interpretar', () async {
      final cache = FakeCache();
      cache.values['tv:v1:scan:TSE:7974'] = '{"formato": "antiguo"}';
      final server = _FakeServer();

      final data = await _adapter(server, cache).fetchStockData('TSE:7974');

      expect(data.overview.name, 'Nintendo Co., Ltd.');
      expect(server.requests, hasLength(1));
    });
  });

  group('TradingViewAdapter errores', () {
    Future<void> expectFailure(
      int status,
      TypeMatcher<MarketDataException> matcher,
    ) async {
      final cache = FakeCache();
      final server = _FakeServer(override: http.Response('error', status));

      await expectLater(
        _adapter(server, cache).fetchStockData('TSE:7974'),
        throwsA(matcher),
      );
      expect(_scanKeys(cache), isEmpty);
    }

    test('HTTP 429 es límite de peticiones', () {
      return expectFailure(429, isA<RateLimitException>());
    });

    test('HTTP 403 (bloqueo) es límite de peticiones', () {
      return expectFailure(403, isA<RateLimitException>());
    });

    test('HTTP 5xx es error de red', () {
      return expectFailure(503, isA<NetworkException>());
    });

    test('otro HTTP inesperado es respuesta inválida', () {
      return expectFailure(404, isA<InvalidResponseException>());
    });

    test('un fallo de conexión es error de red', () async {
      final client = MockClient(
        (_) async => throw http.ClientException('sin red'),
      );
      final adapter = TradingViewAdapter(
        client: client,
        cache: FakeCache(),
        chartConnector: _FakeChart().connect,
      );

      await expectLater(
        adapter.fetchStockData('TSE:7974'),
        throwsA(isA<NetworkException>()),
      );
    });

    test(
      'HTML en lugar de JSON es respuesta inválida y no se guarda',
      () async {
        final cache = FakeCache();
        final server = _FakeServer(
          override: http.Response('<html></html>', 200),
        );

        await expectLater(
          _adapter(server, cache).fetchStockData('TSE:7974'),
          throwsA(isA<InvalidResponseException>()),
        );
        expect(_scanKeys(cache), isEmpty);
      },
    );
  });

  group('TradingViewAdapter.searchSymbol', () {
    test('busca acciones con la cabecera Origin', () async {
      final server = _FakeServer();

      final matches = await _adapter(
        server,
        FakeCache(),
      ).searchSymbol(' Nintendo ');

      final request = server.requests.single;
      expect(request.url.host, 'symbol-search.tradingview.com');
      expect(request.url.queryParameters['text'], 'Nintendo');
      expect(request.url.queryParameters['search_type'], 'stock');
      expect(request.headers['Origin'], 'https://www.tradingview.com');
      expect(matches.first.symbol, 'TSE:7974');
    });

    test('la misma búsqueda sale de la caché', () async {
      final server = _FakeServer();
      final adapter = _adapter(server, FakeCache());
      await adapter.searchSymbol('Nintendo');

      await adapter.searchSymbol('nintendo');

      expect(server.requests, hasLength(1));
    });

    test('un texto vacío no hace peticiones', () async {
      final server = _FakeServer();

      final matches = await _adapter(server, FakeCache()).searchSymbol('   ');

      expect(matches, isEmpty);
      expect(server.requests, isEmpty);
    });
  });

  group('TradingViewAdapter.fetchPriceHistory', () {
    test('devuelve las velas del canal de gráficos', () async {
      final bars = await _adapter(
        _FakeServer(),
        FakeCache(),
      ).fetchPriceHistory('tse:7974');

      expect(bars, hasLength(30));
      expect(bars.last.close, 7851);
    });

    test('guarda el histórico en caché 6 horas', () async {
      final cache = FakeCache();

      await _adapter(_FakeServer(), cache).fetchPriceHistory('TSE:7974');

      expect(cache.values.keys, ['tv:v1:history:TSE:7974']);
      expect(cache.ttls['tv:v1:history:TSE:7974'], const Duration(hours: 6));
    });

    test('con la caché vigente no abre ninguna conexión', () async {
      final cache = FakeCache();
      final chart = _FakeChart();
      final adapter = _adapter(_FakeServer(), cache, chart: chart);
      await adapter.fetchPriceHistory('TSE:7974');

      final bars = await adapter.fetchPriceHistory('TSE:7974');

      expect(chart.connections, hasLength(1));
      expect(bars, hasLength(30));
    });

    test('con la caché caducada vuelve a pedir', () async {
      final cache = FakeCache();
      final chart = _FakeChart();
      final adapter = _adapter(_FakeServer(), cache, chart: chart);
      await adapter.fetchPriceHistory('TSE:7974');
      cache.expire('tv:v1:history:TSE:7974');

      await adapter.fetchPriceHistory('TSE:7974');

      expect(chart.connections, hasLength(2));
    });

    test('forceRefresh ignora la caché', () async {
      final chart = _FakeChart();
      final adapter = _adapter(_FakeServer(), FakeCache(), chart: chart);
      await adapter.fetchPriceHistory('TSE:7974');

      await adapter.fetchPriceHistory('TSE:7974', forceRefresh: true);

      expect(chart.connections, hasLength(2));
    });

    test('una entrada de caché ilegible se ignora y se sustituye', () async {
      final cache = FakeCache()
        ..values['tv:v1:history:TSE:7974'] = '{"formato":"antiguo"}';
      final chart = _FakeChart();

      final bars = await _adapter(
        _FakeServer(),
        cache,
        chart: chart,
      ).fetchPriceHistory('TSE:7974');

      expect(bars, hasLength(30));
      expect(chart.connections, hasLength(1));
      expect(
        cache.values['tv:v1:history:TSE:7974'],
        isNot(contains('antiguo')),
      );
    });

    test('dos peticiones simultáneas comparten una sola conexión', () async {
      final chart = _FakeChart();
      final adapter = _adapter(_FakeServer(), FakeCache(), chart: chart);

      final results = await Future.wait([
        adapter.fetchPriceHistory('TSE:7974'),
        adapter.fetchPriceHistory('TSE:7974'),
      ]);

      expect(chart.connections, hasLength(1));
      expect(results.first, hasLength(30));
      expect(results.last, hasLength(30));
    });

    test(
      'tras terminar, una nueva petición forzada abre otra conexión',
      () async {
        final chart = _FakeChart();
        final adapter = _adapter(_FakeServer(), FakeCache(), chart: chart);
        await Future.wait([
          adapter.fetchPriceHistory('TSE:7974', forceRefresh: true),
          adapter.fetchPriceHistory('TSE:7974', forceRefresh: true),
        ]);

        await adapter.fetchPriceHistory('TSE:7974', forceRefresh: true);

        expect(chart.connections, hasLength(2));
      },
    );

    test('un símbolo desconocido es NotFound y no se guarda', () async {
      final cache = FakeCache();
      final chart = _FakeChart(
        script: readChartTranscript('chart_unknown_symbol').received,
      );

      await expectLater(
        _adapter(_FakeServer(), cache, chart: chart).fetchPriceHistory('X:Y'),
        throwsA(isA<NotFoundException>()),
      );
      expect(cache.values, isEmpty);
    });

    test('un fallo de red es NetworkException y no se guarda', () async {
      final cache = FakeCache();
      final chart = _FakeChart(error: const SocketException('sin red'));

      await expectLater(
        _adapter(_FakeServer(), cache, chart: chart).fetchPriceHistory('X:Y'),
        throwsA(isA<NetworkException>()),
      );
      expect(cache.values, isEmpty);
    });

    test('un símbolo vacío es NotFound sin abrir conexiones', () async {
      final chart = _FakeChart();

      await expectLater(
        _adapter(
          _FakeServer(),
          FakeCache(),
          chart: chart,
        ).fetchPriceHistory(' '),
        throwsA(isA<NotFoundException>()),
      );
      expect(chart.connections, isEmpty);
    });
  });

  group('TradingViewAdapter.fetchStockData con histórico', () {
    test('usa el histórico real en lugar de la barra única', () async {
      final data = await _adapter(
        _FakeServer(),
        FakeCache(),
      ).fetchStockData('TSE:7974');

      expect(data.dailyBars, hasLength(30));
      expect(data.dailyBars.last.date, DateTime.utc(2026, 10, 8));
    });

    test(
      'si el histórico acaba antes que el scanner, añade el último cierre',
      () async {
        // El histórico llega hasta 2026-10-05 y el scanner trae 2026-10-06.
        final chart = _FakeChart(script: [chartChunk(20730), chartCompleted]);

        final data = await _adapter(
          _FakeServer(),
          FakeCache(),
          chart: chart,
        ).fetchStockData('TSE:7974');

        expect(data.dailyBars, hasLength(3));
        expect(data.dailyBars.last.date, DateTime.utc(2026, 10, 6));
        expect(data.dailyBars.last.close, 7815);
      },
    );

    test('si coinciden en el día, manda el cierre del scanner', () async {
      // El histórico llega hasta 2026-10-06, el mismo día que el scanner.
      final chart = _FakeChart(script: [chartChunk(20731), chartCompleted]);

      final data = await _adapter(
        _FakeServer(),
        FakeCache(),
        chart: chart,
      ).fetchStockData('TSE:7974');

      expect(data.dailyBars, hasLength(2));
      expect(data.dailyBars.last.close, 7815);
    });

    test(
      'si el histórico falla, se analiza con la barra única (criterio 56)',
      () async {
        final chart = _FakeChart(error: const SocketException('sin red'));

        final data = await _adapter(
          _FakeServer(),
          FakeCache(),
          chart: chart,
        ).fetchStockData('TSE:7974');

        expect(data.dailyBars, hasLength(1));
        expect(data.overview.name, 'Nintendo Co., Ltd.');
      },
    );

    test('si el símbolo no tiene histórico, también se analiza', () async {
      final chart = _FakeChart(
        script: readChartTranscript('chart_unknown_symbol').received,
      );

      final data = await _adapter(
        _FakeServer(),
        FakeCache(),
        chart: chart,
      ).fetchStockData('TSE:7974');

      expect(data.dailyBars, hasLength(1));
    });

    test('reutiliza el histórico de la caché', () async {
      final chart = _FakeChart();
      final adapter = _adapter(_FakeServer(), FakeCache(), chart: chart);
      await adapter.fetchStockData('TSE:7974');

      await adapter.fetchStockData('TSE:7974');

      expect(chart.connections, hasLength(1));
    });

    test('forceRefresh también vuelve a pedir el histórico', () async {
      final chart = _FakeChart();
      final adapter = _adapter(_FakeServer(), FakeCache(), chart: chart);
      await adapter.fetchStockData('TSE:7974');

      await adapter.fetchStockData('TSE:7974', forceRefresh: true);

      expect(chart.connections, hasLength(2));
    });

    test('si falla el scanner, el error sale al instante aunque el histórico '
        'tarde', () async {
      final server = _FakeServer(override: http.Response('error', 503));
      final chart = _FakeChart(neverConnects: true);

      await expectLater(
        _adapter(
          server,
          FakeCache(),
          chart: chart,
        ).fetchStockData('TSE:7974').timeout(const Duration(seconds: 2)),
        throwsA(isA<NetworkException>()),
      );
    });

    test(
      'si falla el scanner, el error sale y no queda nada colgado',
      () async {
        final server = _FakeServer(override: http.Response('error', 503));

        await expectLater(
          _adapter(server, FakeCache()).fetchStockData('TSE:7974'),
          throwsA(isA<NetworkException>()),
        );
      },
    );
  });

  group('TradingViewAdapter.fetchIntraday', () {
    _FakeChart intraday5() => _FakeChart(
      script: readChartTranscript('chart_intra5_bme_ibe').received,
    );

    test('devuelve las velas con la zona horaria y el retraso', () async {
      final series = await _adapter(
        _FakeServer(),
        FakeCache(),
        chart: intraday5(),
      ).fetchIntraday('bme:ibe', IntradayResolution.minutes5);

      expect(series.bars.length, greaterThan(40));
      expect(series.timezone, 'Europe/Madrid');
      expect(series.delay, const Duration(minutes: 15));
      expect(series.bars.first.time.isBefore(series.bars.last.time), isTrue);
    });

    test('pide la resolución y el número de velas de la resolución', () async {
      final chart = intraday5();

      await _adapter(
        _FakeServer(),
        FakeCache(),
        chart: chart,
      ).fetchIntraday('BME:IBE', IntradayResolution.minutes5);

      final request = chart.connections.single.sent[3];
      expect(request, contains('"5"'));
      expect(request, contains('400'));
    });

    test('la de 30 minutos pide su propia resolución', () async {
      final chart = _FakeChart(
        script: readChartTranscript('chart_intra30_tse_7974').received,
      );

      await _adapter(
        _FakeServer(),
        FakeCache(),
        chart: chart,
      ).fetchIntraday('TSE:7974', IntradayResolution.minutes30);

      expect(chart.connections.single.sent[3], contains('"30"'));
      expect(chart.connections.single.sent[3], contains('200'));
    });

    test('guarda en caché 5 minutos (criterio 65)', () async {
      final cache = FakeCache();

      await _adapter(
        _FakeServer(),
        cache,
        chart: intraday5(),
      ).fetchIntraday('BME:IBE', IntradayResolution.minutes5);

      expect(cache.values.keys, ['tv:v1:intraday:5:BME:IBE']);
      expect(
        cache.ttls['tv:v1:intraday:5:BME:IBE'],
        const Duration(minutes: 5),
      );
    });

    test('con la caché vigente no abre ninguna conexión', () async {
      final chart = intraday5();
      final adapter = _adapter(_FakeServer(), FakeCache(), chart: chart);
      await adapter.fetchIntraday('BME:IBE', IntradayResolution.minutes5);

      final series = await adapter.fetchIntraday(
        'BME:IBE',
        IntradayResolution.minutes5,
      );

      expect(chart.connections, hasLength(1));
      expect(series.timezone, 'Europe/Madrid');
    });

    test('forceRefresh y la caché caducada vuelven a pedir', () async {
      final cache = FakeCache();
      final chart = intraday5();
      final adapter = _adapter(_FakeServer(), cache, chart: chart);
      await adapter.fetchIntraday('BME:IBE', IntradayResolution.minutes5);

      await adapter.fetchIntraday(
        'BME:IBE',
        IntradayResolution.minutes5,
        forceRefresh: true,
      );
      cache.expire('tv:v1:intraday:5:BME:IBE');
      await adapter.fetchIntraday('BME:IBE', IntradayResolution.minutes5);

      expect(chart.connections, hasLength(3));
    });

    test('cada resolución tiene su propia caché', () async {
      final chart = intraday5();
      final adapter = _adapter(_FakeServer(), FakeCache(), chart: chart);

      await adapter.fetchIntraday('BME:IBE', IntradayResolution.minutes5);
      await adapter.fetchIntraday('BME:IBE', IntradayResolution.minutes30);

      expect(chart.connections, hasLength(2));
    });

    test('una entrada de caché ilegible se ignora y se sustituye', () async {
      final cache = FakeCache()
        ..values['tv:v1:intraday:5:BME:IBE'] = '{"formato":"antiguo"}';
      final chart = intraday5();

      final series = await _adapter(
        _FakeServer(),
        cache,
        chart: chart,
      ).fetchIntraday('BME:IBE', IntradayResolution.minutes5);

      expect(series.bars, isNotEmpty);
      expect(chart.connections, hasLength(1));
    });

    test('dos peticiones simultáneas comparten una sola conexión', () async {
      final chart = intraday5();
      final adapter = _adapter(_FakeServer(), FakeCache(), chart: chart);

      await Future.wait([
        adapter.fetchIntraday('BME:IBE', IntradayResolution.minutes5),
        adapter.fetchIntraday('BME:IBE', IntradayResolution.minutes5),
      ]);

      expect(chart.connections, hasLength(1));
    });

    test('un fallo no se guarda y es NetworkException', () async {
      final cache = FakeCache();
      final chart = _FakeChart(error: const SocketException('sin red'));

      await expectLater(
        _adapter(
          _FakeServer(),
          cache,
          chart: chart,
        ).fetchIntraday('BME:IBE', IntradayResolution.minutes5),
        throwsA(isA<NetworkException>()),
      );
      expect(cache.values, isEmpty);
    });

    test('un símbolo vacío es NotFound sin abrir conexiones', () async {
      final chart = intraday5();

      await expectLater(
        _adapter(
          _FakeServer(),
          FakeCache(),
          chart: chart,
        ).fetchIntraday(' ', IntradayResolution.minutes5),
        throwsA(isA<NotFoundException>()),
      );
      expect(chart.connections, isEmpty);
    });
  });

  group('TradingViewAdapter.searchSymbol agrupable', () {
    _FakeServer inditexServer() => _FakeServer(
      searchFixtures: {
        'inditex': 'search_inditex',
        'es0148396007': 'search_isin_inditex',
      },
    );

    test(
      'si solo salen versiones secundarias, completa con el ISIN (criterio 77)',
      () async {
        final server = inditexServer();

        final matches = await _adapter(
          server,
          FakeCache(),
        ).searchSymbol('inditex');

        expect(server.searchedTexts, ['inditex', 'ES0148396007']);
        final main = matches.where((m) => m.symbol == 'BME:ITX').single;
        expect(main.isPrimaryListing, isTrue);
      },
    );

    test('no repite símbolos al unir las dos búsquedas', () async {
      final matches = await _adapter(
        inditexServer(),
        FakeCache(),
      ).searchSymbol('inditex');

      final symbols = matches.map((m) => m.symbol).toList();
      expect(symbols.toSet(), hasLength(symbols.length));
    });

    test('si ya viene la principal, no hace ninguna petición más', () async {
      final server = _FakeServer();

      await _adapter(server, FakeCache()).searchSymbol('nintendo');

      expect(server.searchedTexts, ['nintendo']);
    });

    test('buscar por ISIN es una sola petición (criterio 78)', () async {
      final server = _FakeServer(
        searchFixtures: {'jp3756600007': 'search_isin_nintendo'},
      );

      final matches = await _adapter(
        server,
        FakeCache(),
      ).searchSymbol('JP3756600007');

      expect(server.searchedTexts, ['JP3756600007']);
      expect(matches.first.symbol, 'TSE:7974');
    });

    test('si falla la búsqueda complementaria, devuelve la primera sin error (criterio 82)', () async {
      final server = _FakeServer(
        searchFixtures: {'inditex': 'search_inditex'},
        failingSearches: {'es0148396007'},
      );

      final matches = await _adapter(
        server,
        FakeCache(),
      ).searchSymbol('inditex');

      expect(matches, isNotEmpty);
      expect(matches.any((m) => m.symbol == 'BME:ITX'), isFalse);
    });

    test('si falla la búsqueda principal, el error sale', () async {
      final server = _FakeServer(failingSearches: {'inditex'});

      await expectLater(
        _adapter(server, FakeCache()).searchSymbol('inditex'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('la repetición de la misma búsqueda sale de la caché, complementaria incluida (criterio 83)', () async {
      final server = inditexServer();
      final adapter = _adapter(server, FakeCache());
      await adapter.searchSymbol('inditex');

      await adapter.searchSymbol('inditex');

      expect(server.searchedTexts, ['inditex', 'ES0148396007']);
    });

    test('completa como máximo 3 empresas por búsqueda', () async {
      // Cinco empresas distintas, ninguna con cotización principal.
      final body = jsonEncode({
        'symbols': [
          for (var i = 1; i <= 5; i++)
            {
              'symbol': 'T$i',
              'exchange': 'OTC',
              'type': 'stock',
              'description': 'Empresa $i',
              'currency_code': 'USD',
              'country': 'US',
              'isin': 'US00000000$i',
            },
        ],
      });
      final server = _FakeServer(override: http.Response(body, 200));

      await _adapter(server, FakeCache()).searchSymbol('empresa');

      // La búsqueda original más 3 complementarias.
      expect(server.searchedTexts, hasLength(4));
    });
  });
}
