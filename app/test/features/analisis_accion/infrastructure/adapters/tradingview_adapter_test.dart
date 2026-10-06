import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/tradingview_adapter.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/tradingview_fields.dart';

import '../../../../fixtures/tradingview_fixtures.dart';
import '../../application/fake_ports.dart';

final _now = DateTime.utc(2026, 10, 6, 12);

/// Servidor simulado: registra cada petición y responde con fixtures reales.
class _FakeServer {
  _FakeServer({this.override});

  final http.Response? override;
  final List<http.Request> requests = [];

  late final client = MockClient((request) async {
    requests.add(request);
    final fixed = override;
    if (fixed != null) return fixed;
    if (request.url.host == 'symbol-search.tradingview.com') {
      return _json(readTradingViewFixture('search_nintendo'));
    }
    return _json(readTradingViewFixture('scan_tse_7974'));
  });

  static http.Response _json(String body) => http.Response.bytes(
    utf8.encode(body),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

TradingViewAdapter _adapter(_FakeServer server, FakeCache cache) =>
    TradingViewAdapter(client: server.client, cache: cache, now: () => _now);

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

      expect(cache.values.keys, ['tv:v1:scan:TSE:7974']);
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
      expect(cache.values, isEmpty);
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
      expect(cache.values, isEmpty);
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
      final adapter = TradingViewAdapter(client: client, cache: FakeCache());

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
        expect(cache.values, isEmpty);
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
}
