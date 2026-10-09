import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/exchange_rate_series.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';
import 'package:stock_app/features/analisis_accion/domain/ports/exchange_rate_port.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/cached_exchange_rate_adapter.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/fallback_exchange_rate_adapter.dart';

import '../../application/fake_ports.dart';

ExchangeRateSeries _yen([double rate = 177.05]) => ExchangeRateSeries(
  currency: 'JPY',
  points: [
    RatePoint(DateTime.utc(2026, 10, 7), rate - 0.2),
    RatePoint(DateTime.utc(2026, 10, 8), rate),
  ],
);

/// Un proveedor de mentira que devuelve [series] o lanza [error].
class _Source implements ExchangeRatePort {
  _Source({this.series, this.error});

  final ExchangeRateSeries? series;
  final MarketDataException? error;
  Completer<void>? gate;
  int calls = 0;
  bool? lastForceRefresh;

  @override
  Future<ExchangeRateSeries> fetchRates(
    String isoCode, {
    bool forceRefresh = false,
  }) async {
    calls++;
    lastForceRefresh = forceRefresh;
    await gate?.future;
    final failure = error;
    if (failure != null) throw failure;
    return series!;
  }
}

void main() {
  group('FallbackExchangeRateAdapter', () {
    test('si el BCE responde, no pregunta al Banco de España', () async {
      final primary = _Source(series: _yen());
      final secondary = _Source(series: _yen(170));

      final series = await FallbackExchangeRateAdapter(
        primary: primary,
        secondary: secondary,
      ).fetchRates('JPY');

      expect(series.latest?.unitsPerEuro, 177.05);
      expect(secondary.calls, 0);
    });

    for (final failure in <MarketDataException>[
      const NetworkException('sin red'),
      const RateLimitException('429'),
      const InvalidResponseException('formato'),
    ]) {
      test(
        'si el BCE falla con ${failure.runtimeType}, usa el Banco de España (criterio 93)',
        () async {
          final primary = _Source(error: failure);
          final secondary = _Source(series: _yen(170));

          final series = await FallbackExchangeRateAdapter(
            primary: primary,
            secondary: secondary,
          ).fetchRates('JPY');

          expect(series.latest?.unitsPerEuro, 170);
          expect(secondary.calls, 1);
        },
      );
    }

    test(
      'si el BCE dice que la moneda no existe, no se pregunta al respaldo',
      () async {
        final primary = _Source(error: const NotFoundException('no existe'));
        final secondary = _Source(series: _yen());

        await expectLater(
          FallbackExchangeRateAdapter(
            primary: primary,
            secondary: secondary,
          ).fetchRates('SAR'),
          throwsA(isA<NotFoundException>()),
        );
        expect(secondary.calls, 0);
      },
    );

    test('si fallan los dos, sale el error del respaldo', () async {
      final primary = _Source(error: const NetworkException('BCE'));
      final secondary = _Source(error: const InvalidResponseException('BdE'));

      await expectLater(
        FallbackExchangeRateAdapter(
          primary: primary,
          secondary: secondary,
        ).fetchRates('JPY'),
        throwsA(isA<InvalidResponseException>()),
      );
    });

    test(
      'si el BCE falla y el respaldo no tiene la moneda, sale el error del BCE',
      () async {
        final primary = _Source(error: const NetworkException('BCE caído'));
        final secondary = _Source(error: const NotFoundException('sin TWD'));

        await expectLater(
          FallbackExchangeRateAdapter(
            primary: primary,
            secondary: secondary,
          ).fetchRates('TWD'),
          throwsA(isA<NetworkException>()),
        );
      },
    );

    test('reenvía forceRefresh', () async {
      final primary = _Source(series: _yen());

      await FallbackExchangeRateAdapter(
        primary: primary,
        secondary: _Source(series: _yen()),
      ).fetchRates('JPY', forceRefresh: true);

      expect(primary.lastForceRefresh, isTrue);
    });
  });

  group('CachedExchangeRateAdapter', () {
    test('guarda los tipos 6 horas', () async {
      final cache = FakeCache();

      await CachedExchangeRateAdapter(
        inner: _Source(series: _yen()),
        cache: cache,
      ).fetchRates('JPY');

      expect(cache.values.keys, ['fx:v1:JPY']);
      expect(cache.ttls['fx:v1:JPY'], const Duration(hours: 6));
    });

    test('con la caché vigente no vuelve a pedir (criterio 95)', () async {
      final source = _Source(series: _yen());
      final adapter = CachedExchangeRateAdapter(
        inner: source,
        cache: FakeCache(),
      );
      await adapter.fetchRates('JPY');

      final series = await adapter.fetchRates('JPY');

      expect(source.calls, 1);
      expect(series.latest?.unitsPerEuro, 177.05);
      expect(series.latest?.date, DateTime.utc(2026, 10, 8));
    });

    test('lo recuperado de la caché es igual a lo guardado', () async {
      final adapter = CachedExchangeRateAdapter(
        inner: _Source(series: _yen()),
        cache: FakeCache(),
      );
      final first = await adapter.fetchRates('JPY');

      final second = await adapter.fetchRates('JPY');

      expect(second.currency, 'JPY');
      expect(second.points.map((p) => p.date), first.points.map((p) => p.date));
      expect(
        second.points.map((p) => p.unitsPerEuro),
        first.points.map((p) => p.unitsPerEuro),
      );
    });

    test('con la caché caducada vuelve a pedir', () async {
      final cache = FakeCache();
      final source = _Source(series: _yen());
      final adapter = CachedExchangeRateAdapter(inner: source, cache: cache);
      await adapter.fetchRates('JPY');
      cache.expire('fx:v1:JPY');

      await adapter.fetchRates('JPY');

      expect(source.calls, 2);
    });

    test('forceRefresh ignora la caché y se lo pasa al origen', () async {
      final source = _Source(series: _yen());
      final adapter = CachedExchangeRateAdapter(
        inner: source,
        cache: FakeCache(),
      );
      await adapter.fetchRates('JPY');

      await adapter.fetchRates('JPY', forceRefresh: true);

      expect(source.calls, 2);
      expect(source.lastForceRefresh, isTrue);
    });

    test('cada moneda tiene su propia caché', () async {
      final source = _Source(series: _yen());
      final adapter = CachedExchangeRateAdapter(
        inner: source,
        cache: FakeCache(),
      );

      await adapter.fetchRates('JPY');
      await adapter.fetchRates('USD');

      expect(source.calls, 2);
    });

    test('una entrada ilegible se ignora y se sustituye', () async {
      final cache = FakeCache()..values['fx:v1:JPY'] = '{"formato":"antiguo"}';
      final source = _Source(series: _yen());

      final series = await CachedExchangeRateAdapter(
        inner: source,
        cache: cache,
      ).fetchRates('JPY');

      expect(series.points, hasLength(2));
      expect(source.calls, 1);
      expect(cache.values['fx:v1:JPY'], isNot(contains('antiguo')));
    });

    test(
      'dos peticiones simultáneas de una moneda comparten una sola descarga',
      () async {
        final source = _Source(series: _yen())..gate = Completer<void>();
        final adapter = CachedExchangeRateAdapter(
          inner: source,
          cache: FakeCache(),
        );

        final both = Future.wait([
          adapter.fetchRates('JPY'),
          adapter.fetchRates('JPY'),
        ]);
        await Future<void>.delayed(Duration.zero);
        source.gate!.complete();
        await both;

        expect(source.calls, 1);
      },
    );

    test('un fallo no se guarda en la caché', () async {
      final cache = FakeCache();

      await expectLater(
        CachedExchangeRateAdapter(
          inner: _Source(error: const NetworkException('sin red')),
          cache: cache,
        ).fetchRates('JPY'),
        throwsA(isA<NetworkException>()),
      );
      expect(cache.values, isEmpty);
    });

    test('tras un fallo se puede volver a intentar', () async {
      final cache = FakeCache();
      final failing = CachedExchangeRateAdapter(
        inner: _Source(error: const NetworkException('sin red')),
        cache: cache,
      );
      await expectLater(
        failing.fetchRates('JPY'),
        throwsA(isA<NetworkException>()),
      );

      final working = await CachedExchangeRateAdapter(
        inner: _Source(series: _yen()),
        cache: cache,
      ).fetchRates('JPY');

      expect(working.points, hasLength(2));
    });

    test(
      'un código de moneda no válido es NotFound sin consultar nada',
      () async {
        final source = _Source(series: _yen());

        await expectLater(
          CachedExchangeRateAdapter(
            inner: source,
            cache: FakeCache(),
          ).fetchRates('../x'),
          throwsA(isA<NotFoundException>()),
        );
        expect(source.calls, 0);
      },
    );

    test('normaliza el código a mayúsculas', () async {
      final cache = FakeCache();

      await CachedExchangeRateAdapter(
        inner: _Source(series: _yen()),
        cache: cache,
      ).fetchRates('jpy');

      expect(cache.values.keys, ['fx:v1:JPY']);
    });
  });
}
