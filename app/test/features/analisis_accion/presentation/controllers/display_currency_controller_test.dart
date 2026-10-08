import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/get_exchange_rates_use_case.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/exchange_rate_series.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';
import 'package:stock_app/features/analisis_accion/presentation/controllers/display_currency_controller.dart';

import '../../application/fake_ports.dart';

final _thursday = DateTime.utc(2026, 10, 8);

ExchangeRateSeries _series(String currency, double rate) => ExchangeRateSeries(
  currency: currency,
  points: [
    RatePoint(DateTime.utc(2026, 10, 6), rate - 1),
    RatePoint(_thursday, rate),
  ],
);

DisplayCurrencyController _controller(
  FakeExchangeRates rates, {
  DateTime? now,
}) => DisplayCurrencyController(
  getExchangeRates: GetExchangeRatesUseCase(rates),
  now: () => now ?? DateTime.utc(2026, 10, 9),
);

void main() {
  group('DisplayCurrencyController.configure', () {
    test('al empezar no hay nada que convertir', () {
      final controller = _controller(FakeExchangeRates());

      expect(controller.status, CurrencyStatus.none);
      expect(controller.canSwitch, isFalse);
      expect(controller.isInEuros, isFalse);
    });

    test(
      'una acción en euros no pide tipos ni tiene selector (criterio 86)',
      () async {
        final rates = FakeExchangeRates();
        final controller = _controller(rates);

        await controller.configure('EUR');

        expect(controller.status, CurrencyStatus.none);
        expect(controller.canSwitch, isFalse);
        expect(rates.calls, isEmpty);
        expect(controller.toDisplay(42, _thursday), 42);
        expect(controller.currencyLabel, 'EUR');
      },
    );

    test('sin moneda tampoco hay conversión', () async {
      final rates = FakeExchangeRates();
      final controller = _controller(rates);

      await controller.configure(null);

      expect(controller.status, CurrencyStatus.none);
      expect(rates.calls, isEmpty);
    });

    test(
      'con otra moneda pide sus tipos y pasa a euros por defecto (criterio 84)',
      () async {
        final rates = FakeExchangeRates(
          byCurrency: {'JPY': _series('JPY', 177)},
        );
        final controller = _controller(rates);

        await controller.configure('JPY');

        expect(rates.calls.single.currency, 'JPY');
        expect(controller.status, CurrencyStatus.ready);
        expect(controller.isInEuros, isTrue);
        expect(controller.canSwitch, isTrue);
        expect(controller.currencyLabel, 'EUR');
      },
    );

    test(
      'mientras llegan los tipos se ve la divisa original (criterio 96)',
      () async {
        final rates = FakeExchangeRates(
          byCurrency: {'JPY': _series('JPY', 177)},
        )..gate = Completer<void>();
        final controller = _controller(rates);

        final configuring = controller.configure('JPY');

        expect(controller.isConverting, isTrue);
        expect(controller.isInEuros, isFalse);
        expect(controller.currencyLabel, 'JPY');
        expect(controller.toDisplay(7851, _thursday), 7851);
        rates.gate!.complete();
        await configuring;
        expect(controller.isInEuros, isTrue);
      },
    );

    test('los peniques piden la libra y se muestran en GBX al ver el original (criterio 91)', () async {
      final rates = FakeExchangeRates(
        byCurrency: {'GBP': _series('GBP', 0.85)},
      );
      final controller = _controller(rates);

      await controller.configure('GBX');

      expect(rates.calls.single.currency, 'GBP');
      expect(controller.isoCode, 'GBP');
      expect(controller.quoteCode, 'GBX');
      expect(controller.toDisplay(500, _thursday), closeTo(5 / 0.85, 1e-9));
      controller.showOriginal(original: true);
      expect(controller.currencyLabel, 'GBX');
      expect(controller.toDisplay(500, _thursday), 500);
    });

    test(
      'una moneda sin tipo queda sin selector y en su divisa (criterio 92)',
      () async {
        final controller = _controller(FakeExchangeRates());

        await controller.configure('SAR');

        expect(controller.status, CurrencyStatus.unsupported);
        expect(controller.canSwitch, isFalse);
        expect(controller.isInEuros, isFalse);
        expect(controller.currencyLabel, 'SAR');
        expect(controller.toDisplay(100, _thursday), 100);
      },
    );

    test('si fallan las fuentes queda como fallo y se ve la divisa original (criterio 93)', () async {
      final controller = _controller(
        FakeExchangeRates(error: const NetworkException()),
      );

      await controller.configure('JPY');

      expect(controller.status, CurrencyStatus.failed);
      expect(controller.isInEuros, isFalse);
      expect(controller.currencyLabel, 'JPY');
    });

    test(
      'configurar dos veces la misma moneda no repite la petición',
      () async {
        final rates = FakeExchangeRates(
          byCurrency: {'JPY': _series('JPY', 177)},
        );
        final controller = _controller(rates);
        await controller.configure('JPY');

        await controller.configure('JPY');
        await controller.configure(' jpy ');

        expect(rates.calls, hasLength(1));
      },
    );

    test('cambiar de moneda vuelve a euros y pide los nuevos tipos', () async {
      final rates = FakeExchangeRates(
        byCurrency: {'JPY': _series('JPY', 177), 'USD': _series('USD', 1.1)},
      );
      final controller = _controller(rates);
      await controller.configure('JPY');
      controller.showOriginal(original: true);

      await controller.configure('USD');

      expect(rates.calls.map((c) => c.currency), ['JPY', 'USD']);
      expect(controller.isInEuros, isTrue);
    });

    test('pasar a una acción en euros quita la conversión', () async {
      final controller = _controller(
        FakeExchangeRates(byCurrency: {'JPY': _series('JPY', 177)}),
      );
      await controller.configure('JPY');

      await controller.configure('EUR');

      expect(controller.status, CurrencyStatus.none);
      expect(controller.latestRate, isNull);
    });
  });

  group('DisplayCurrencyController selector', () {
    Future<DisplayCurrencyController> ready() async {
      final controller = _controller(
        FakeExchangeRates(byCurrency: {'JPY': _series('JPY', 177)}),
      );
      await controller.configure('JPY');
      return controller;
    }

    test('en euros convierte con el tipo del día (criterio 87)', () async {
      final controller = await ready();

      expect(controller.toDisplay(17700, _thursday), closeTo(100, 1e-9));
      // El 6 de octubre el tipo era 176.
      expect(
        controller.toDisplay(17600, DateTime.utc(2026, 10, 6)),
        closeTo(100, 1e-9),
      );
    });

    test('un fin de semana usa el último tipo publicado', () async {
      final controller = await ready();

      expect(
        controller.toDisplay(17700, DateTime.utc(2026, 10, 10)),
        closeTo(100, 1e-9),
      );
    });

    test('un día anterior al primer tipo no se convierte', () async {
      final controller = await ready();

      expect(controller.toDisplay(100, DateTime.utc(2026, 9, 1)), isNull);
    });

    test('toDisplayLatest usa el último tipo (criterio 88)', () async {
      final controller = await ready();

      expect(controller.toDisplayLatest(17700), closeTo(100, 1e-9));
    });

    test('elegir la divisa original devuelve los valores sin convertir (criterio 85)', () async {
      final controller = await ready();

      controller.showOriginal(original: true);

      expect(controller.isInEuros, isFalse);
      expect(controller.currencyLabel, 'JPY');
      expect(controller.toDisplay(17700, _thursday), 17700);
      expect(controller.toDisplayLatest(17700), 17700);
      expect(controller.canSwitch, isTrue);
    });

    test('volver a elegir euros convierte otra vez', () async {
      final controller = await ready();
      controller.showOriginal(original: true);

      controller.showOriginal(original: false);

      expect(controller.isInEuros, isTrue);
    });

    test('notifica en cada cambio y no cuando no cambia nada', () async {
      final controller = await ready();
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.showOriginal(original: false);
      expect(notifications, 0);
      controller.showOriginal(original: true);
      controller.showOriginal(original: false);

      expect(notifications, 2);
    });
  });

  group('DisplayCurrencyController reload', () {
    test('Reintentar tras un fallo vuelve a pedir y pasa a euros', () async {
      final rates = FakeExchangeRates(error: const NetworkException());
      final controller = _controller(rates);
      await controller.configure('JPY');

      final working = FakeExchangeRates(
        byCurrency: {'JPY': _series('JPY', 177)},
      );
      final retrying = _controller(working);
      await retrying.configure('JPY');
      await retrying.reload();

      expect(controller.status, CurrencyStatus.failed);
      expect(retrying.status, CurrencyStatus.ready);
      expect(working.calls, hasLength(2));
    });

    test('"Actualizar datos" pide los tipos forzando (criterio 95)', () async {
      final rates = FakeExchangeRates(byCurrency: {'JPY': _series('JPY', 177)});
      final controller = _controller(rates);
      await controller.configure('JPY');

      await controller.reload(forceRefresh: true);

      expect(rates.calls.last.forceRefresh, isTrue);
      expect(controller.isInEuros, isTrue);
    });

    test('no hace nada con una acción en euros ni sin moneda', () async {
      final rates = FakeExchangeRates();
      final controller = _controller(rates);

      await controller.reload();
      await controller.configure('EUR');
      await controller.reload();

      expect(rates.calls, isEmpty);
    });

    test('no abre una segunda petición mientras hay una en curso', () async {
      final rates = FakeExchangeRates(byCurrency: {'JPY': _series('JPY', 177)})
        ..gate = Completer<void>();
      final controller = _controller(rates);
      final configuring = controller.configure('JPY');

      await controller.reload();
      rates.gate!.complete();
      await configuring;

      expect(rates.calls, hasLength(1));
    });

    test(
      'al recargar se conserva lo elegido: la divisa original sigue',
      () async {
        final rates = FakeExchangeRates(
          byCurrency: {'JPY': _series('JPY', 177)},
        );
        final controller = _controller(rates);
        await controller.configure('JPY');
        controller.showOriginal(original: true);

        await controller.reload(forceRefresh: true);

        expect(controller.isInEuros, isFalse);
      },
    );
  });

  group('DisplayCurrencyController tipos', () {
    test('rateOn da el tipo y el día usados para un precio', () async {
      final controller = _controller(
        FakeExchangeRates(byCurrency: {'JPY': _series('JPY', 177)}),
      );
      await controller.configure('JPY');

      final point = controller.rateOn(DateTime.utc(2026, 10, 10));

      expect(point?.date, _thursday);
      expect(point?.unitsPerEuro, 177);
    });

    test('un tipo reciente no está desfasado', () async {
      final controller = _controller(
        FakeExchangeRates(byCurrency: {'JPY': _series('JPY', 177)}),
        now: DateTime.utc(2026, 10, 10),
      );
      await controller.configure('JPY');

      expect(controller.isRateStale, isFalse);
    });

    test(
      'un tipo de hace más de 5 días está desfasado (criterio 97)',
      () async {
        final controller = _controller(
          FakeExchangeRates(byCurrency: {'JPY': _series('JPY', 177)}),
          now: DateTime.utc(2026, 10, 15),
        );
        await controller.configure('JPY');

        expect(controller.isRateStale, isTrue);
        expect(controller.latestRateAgeInDays, 7);
      },
    );

    test('sin tipos no hay desfase que avisar', () {
      final controller = _controller(FakeExchangeRates());

      expect(controller.isRateStale, isFalse);
      expect(controller.latestRateAgeInDays, isNull);
    });
  });

  test('tras liberarlo, una carga pendiente no lanza', () async {
    final rates = FakeExchangeRates(byCurrency: {'JPY': _series('JPY', 177)})
      ..gate = Completer<void>();
    final controller = _controller(rates);
    final configuring = controller.configure('JPY');

    controller.dispose();
    rates.gate!.complete();

    await expectLater(configuring, completes);
  });

  group('DisplayCurrencyController carreras y refresco', () {
    test('una respuesta de una moneda anterior se descarta', () async {
      final gate = Completer<void>();
      final rates = FakeExchangeRates(
        byCurrency: {'JPY': _series('JPY', 177), 'USD': _series('USD', 1.2)},
      )..gate = gate;
      final controller = _controller(rates);
      final first = controller.configure('JPY');
      final second = controller.configure('USD');

      gate.complete();
      await Future.wait([first, second]);

      expect(controller.isoCode, 'USD');
      expect(controller.latestRate!.unitsPerEuro, 1.2);
    });

    test(
      'al refrescar no vuelve a "cargando" y conserva los tipos si falla',
      () async {
        final rates = FakeExchangeRates(
          byCurrency: {'JPY': _series('JPY', 177)},
        );
        final controller = _controller(rates);
        await controller.configure('JPY');
        final seen = <CurrencyStatus>[];
        controller.addListener(() => seen.add(controller.status));

        await controller.reload(forceRefresh: true);

        expect(seen, everyElement(CurrencyStatus.ready));
        expect(controller.latestRate!.unitsPerEuro, 177);
      },
    );

    test('un refresco forzado pedido durante una carga se repite', () async {
      final gate = Completer<void>();
      final rates = FakeExchangeRates(byCurrency: {'JPY': _series('JPY', 177)})
        ..gate = gate;
      final controller = _controller(rates);
      final loading = controller.configure('JPY');
      await controller.reload(forceRefresh: true);

      gate.complete();
      await loading;

      expect(rates.calls.last.forceRefresh, isTrue);
      expect(rates.calls, hasLength(2));
    });
  });
}
