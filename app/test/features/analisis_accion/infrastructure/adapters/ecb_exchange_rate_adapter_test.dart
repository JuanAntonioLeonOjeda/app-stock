import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/bde_exchange_rate_adapter.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/ecb_exchange_rate_adapter.dart';

import '../../../../fixtures/exchange_rates_fixtures.dart';

({MockClient client, List<http.Request> requests}) _server(
  http.Response Function(http.Request request) respond,
) {
  final requests = <http.Request>[];
  final client = MockClient((request) async {
    requests.add(request);
    return respond(request);
  });
  return (client: client, requests: requests);
}

void main() {
  group('EcbExchangeRateAdapter', () {
    test('un fallo de TLS es un NetworkException, no escapa', () async {
      final client = MockClient(
        (_) async => throw const HandshakeException('certificado no válido'),
      );

      expect(
        () => EcbExchangeRateAdapter(client: client).fetchRates('JPY'),
        throwsA(isA<NetworkException>()),
      );
    });

    test(
      'pide los tipos diarios de la moneda frente al euro desde 2001',
      () async {
        final server = _server(
          (_) => http.Response(readRateFixture('ecb_jpy.json'), 200),
        );

        await EcbExchangeRateAdapter(client: server.client).fetchRates('jpy');

        final uri = server.requests.single.url;
        expect(uri.host, 'data-api.ecb.europa.eu');
        expect(uri.path, '/service/data/EXR/D.JPY.EUR.SP00.A');
        expect(uri.queryParameters['startPeriod'], '2001-01-01');
        expect(uri.queryParameters['format'], 'jsondata');
        expect(server.requests.single.headers['Accept'], 'application/json');
      },
    );

    test('devuelve la serie de la respuesta real', () async {
      final server = _server(
        (_) => http.Response(readRateFixture('ecb_jpy.json'), 200),
      );

      final series = await EcbExchangeRateAdapter(client: server.client)
          .fetchRates('JPY');

      expect(series.currency, 'JPY');
      expect(series.points, hasLength(14));
    });

    test('una moneda que el BCE no publica (404) es NotFound', () async {
      final server = _server(
        (_) => http.Response(readRateFixture('ecb_unknown_currency.txt'), 404),
      );

      await expectLater(
        EcbExchangeRateAdapter(client: server.client).fetchRates('SAR'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('HTTP 429 es límite de peticiones', () async {
      final server = _server((_) => http.Response('', 429));

      await expectLater(
        EcbExchangeRateAdapter(client: server.client).fetchRates('JPY'),
        throwsA(isA<RateLimitException>()),
      );
    });

    test('HTTP 5xx es error de red', () async {
      final server = _server((_) => http.Response('', 503));

      await expectLater(
        EcbExchangeRateAdapter(client: server.client).fetchRates('JPY'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('otro HTTP inesperado (400) es respuesta inválida', () async {
      final server = _server(
        (_) => http.Response(readRateFixture('ecb_no_data.txt'), 400),
      );

      await expectLater(
        EcbExchangeRateAdapter(client: server.client).fetchRates('JPY'),
        throwsA(isA<InvalidResponseException>()),
      );
    });

    test(
      'un cuerpo que no es JSON con HTTP 200 es respuesta inválida',
      () async {
        final server = _server((_) => http.Response('<html></html>', 200));

        await expectLater(
          EcbExchangeRateAdapter(client: server.client).fetchRates('JPY'),
          throwsA(isA<InvalidResponseException>()),
        );
      },
    );

    test('un fallo de conexión es error de red', () async {
      final client = MockClient(
        (_) async => throw http.ClientException('sin red'),
      );

      await expectLater(
        EcbExchangeRateAdapter(client: client).fetchRates('JPY'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('un SocketException también es error de red', () async {
      final client = MockClient(
        (_) async => throw const SocketException('sin red'),
      );

      await expectLater(
        EcbExchangeRateAdapter(client: client).fetchRates('JPY'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('un código que no son tres letras no llega a la URL', () async {
      final server = _server((_) => http.Response('', 200));

      for (final bad in ['', 'JP', 'JPYX', '../x', 'J/Y', 'J Y', 'J1Y']) {
        await expectLater(
          EcbExchangeRateAdapter(client: server.client).fetchRates(bad),
          throwsA(isA<NotFoundException>()),
          reason: '"$bad"',
        );
      }
      expect(server.requests, isEmpty);
    });
  });

  group('BdeExchangeRateAdapter', () {
    test('pide el CSV oficial y lee la moneda', () async {
      final server = _server(
        (_) => http.Response.bytes(readRateFixtureBytes('bde_tc_1_1.csv'), 200),
      );

      final series = await BdeExchangeRateAdapter(client: server.client)
          .fetchRates('JPY');

      expect(server.requests.single.url.host, 'www.bde.es');
      expect(server.requests.single.url.path, endsWith('/csv/tc_1_1.csv'));
      expect(series.latest?.unitsPerEuro, 176.85);
    });

    test('decodifica el archivo como latin-1 (la cabecera lleva Ó)', () async {
      final bytes = readRateFixtureBytes('bde_tc_1_1.csv');
      // En latin-1, la Ó de "CÓDIGO" es un solo byte (0xD3), no UTF-8.
      expect(bytes.contains(0xD3), isTrue);
      final server = _server((_) => http.Response.bytes(bytes, 200));

      await expectLater(
        BdeExchangeRateAdapter(client: server.client).fetchRates('USD'),
        completes,
      );
    });

    test('HTTP 5xx es error de red', () async {
      final server = _server((_) => http.Response('', 500));

      await expectLater(
        BdeExchangeRateAdapter(client: server.client).fetchRates('JPY'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('una moneda que el Banco de España no publica es NotFound', () async {
      final server = _server(
        (_) => http.Response.bytes(readRateFixtureBytes('bde_tc_1_1.csv'), 200),
      );

      await expectLater(
        BdeExchangeRateAdapter(client: server.client).fetchRates('TWD'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('un cuerpo distinto del CSV es respuesta inválida', () async {
      final server = _server(
        (_) => http.Response.bytes(utf8.encode('<html></html>'), 200),
      );

      await expectLater(
        BdeExchangeRateAdapter(client: server.client).fetchRates('JPY'),
        throwsA(isA<InvalidResponseException>()),
      );
    });

    test('un código no válido no hace ninguna petición', () async {
      final server = _server((_) => http.Response('', 200));

      await expectLater(
        BdeExchangeRateAdapter(client: server.client).fetchRates('../etc'),
        throwsA(isA<NotFoundException>()),
      );
      expect(server.requests, isEmpty);
    });
  });
}
