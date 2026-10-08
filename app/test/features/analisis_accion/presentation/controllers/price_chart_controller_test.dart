import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/get_exchange_rates_use_case.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/get_intraday_history_use_case.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/get_price_history_use_case.dart';
import 'package:stock_app/features/analisis_accion/domain/chart/chart_range.dart';
import 'package:stock_app/features/analisis_accion/domain/chart/intraday_resolution.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/daily_bar.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/exchange_rate_series.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';
import 'package:stock_app/features/analisis_accion/presentation/controllers/display_currency_controller.dart';
import 'package:stock_app/features/analisis_accion/presentation/controllers/price_chart_controller.dart';

import '../../application/fake_ports.dart';
import '../intraday_samples.dart';
import '../../domain/motor/synthetic_companies.dart';

PriceChartController _controller(FakePriceHistory port) => PriceChartController(
  getPriceHistory: GetPriceHistoryUseCase(port),
  getIntradayHistory: GetIntradayHistoryUseCase(FakeIntradayHistory()),
  symbol: 'TSE:7974',
);

PriceChartController _withIntraday(
  FakeIntradayHistory intraday, {
  FakePriceHistory? history,
}) => PriceChartController(
  getPriceHistory: GetPriceHistoryUseCase(
    history ?? FakePriceHistory(bars: priceHistory(sessions: 400)),
  ),
  getIntradayHistory: GetIntradayHistoryUseCase(intraday),
  symbol: 'BME:IBE',
);

/// 800 sesiones diarias consecutivas, con un pico y un valle conocidos.
List<DailyBar> _bars({int sessions = 800}) {
  final bars = priceHistory(sessions: sessions);
  DailyBar withClose(DailyBar bar, double close) => DailyBar(
    date: bar.date,
    open: close,
    high: close,
    low: close,
    close: close,
    volume: bar.volume,
  );
  if (sessions < 400) return bars;
  return [
    for (var i = 0; i < bars.length; i++)
      if (i == 300)
        withClose(bars[i], 9999)
      else if (i == 500)
        withClose(bars[i], 1)
      else
        bars[i],
  ];
}

void main() {
  group('PriceChartController.load', () {
    test('carga el histórico y prepara la vista del último año', () async {
      final controller = _controller(FakePriceHistory(bars: _bars()));

      await controller.load();

      expect(controller.bars, hasLength(800));
      expect(controller.range, ChartRange.year1);
      expect(controller.view, isNotNull);
      expect(controller.view!.closes.length, lessThanOrEqualTo(366));
      expect(controller.error, isNull);
    });

    test('mientras carga, isLoading es true y no hay vista', () async {
      final port = FakePriceHistory(bars: _bars())..gate = Completer<void>();
      final controller = _controller(port);

      final loading = controller.load();

      expect(controller.isLoading, isTrue);
      expect(controller.view, isNull);
      port.gate!.complete();
      await loading;
      expect(controller.isLoading, isFalse);
    });

    test('un fallo deja el error, sin vista, y se puede reintentar', () async {
      final port = FakePriceHistory(error: const NetworkException());
      final controller = _controller(port);

      await controller.load();

      expect(controller.error, isA<NetworkException>());
      expect(controller.view, isNull);
      await controller.load();
      expect(port.calls, hasLength(2));
    });

    test('forceRefresh se reenvía al caso de uso', () async {
      final port = FakePriceHistory(bars: _bars());
      final controller = _controller(port);

      await controller.load(forceRefresh: true);

      expect(port.calls.single.forceRefresh, isTrue);
      expect(port.calls.single.symbol, 'TSE:7974');
    });

    test('si falla una recarga, el histórico anterior se conserva', () async {
      final flaky = _FlakyHistory(_bars());
      final controller = PriceChartController(
        getPriceHistory: GetPriceHistoryUseCase(flaky),
        getIntradayHistory: GetIntradayHistoryUseCase(FakeIntradayHistory()),
        symbol: 'TSE:7974',
      );
      await controller.load();
      flaky.shouldFail = true;

      await controller.load(forceRefresh: true);

      expect(controller.error, isA<NetworkException>());
      expect(controller.view, isNotNull);
    });

    test('una llamada mientras carga no abre una segunda carga', () async {
      final port = FakePriceHistory(bars: _bars())..gate = Completer<void>();
      final controller = _controller(port);

      final first = controller.load();
      await controller.load();
      port.gate!.complete();
      await first;

      expect(port.calls, hasLength(1));
    });

    test('una recarga forzada pedida durante una carga se repite al terminar (criterio 45)', () async {
      final port = FakePriceHistory(bars: _bars())..gate = Completer<void>();
      final controller = _controller(port);

      final first = controller.load();
      await controller.load(forceRefresh: true);
      port.gate!.complete();
      await first;
      await Future<void>.delayed(Duration.zero);

      expect(port.calls, hasLength(2));
      expect(port.calls.first.forceRefresh, isFalse);
      expect(port.calls.last.forceRefresh, isTrue);
    });

    test('una carga normal pedida durante otra no se repite', () async {
      final port = FakePriceHistory(bars: _bars())..gate = Completer<void>();
      final controller = _controller(port);

      final first = controller.load();
      await controller.load();
      port.gate!.complete();
      await first;
      await Future<void>.delayed(Duration.zero);

      expect(port.calls, hasLength(1));
    });

    test('tras liberarlo, una carga pendiente no lanza', () async {
      final port = FakePriceHistory(bars: _bars())..gate = Completer<void>();
      final controller = _controller(port);
      final loading = controller.load();

      controller.dispose();
      port.gate!.complete();

      await expectLater(loading, completes);
    });
  });

  group('PriceChartController periodo', () {
    test('cambiar de periodo redibuja con ese periodo', () async {
      final controller = _controller(FakePriceHistory(bars: _bars()));
      await controller.load();

      controller.selectRange(ChartRange.month1);

      expect(controller.range, ChartRange.month1);
      expect(controller.view!.closes, hasLength(31));
    });

    test('todo agrupa los puntos y no pasa de 500 (criterio 51)', () async {
      final controller = _controller(FakePriceHistory(bars: _bars()));
      await controller.load();

      controller.selectRange(ChartRange.all);

      expect(controller.view!.closes.length, lessThanOrEqualTo(500));
      expect(controller.view!.closes.length, greaterThan(100));
    });

    test(
      'con un histórico corto, cualquier periodo muestra todo lo que hay',
      () async {
        final controller = _controller(
          FakePriceHistory(bars: priceHistory(sessions: 20)),
        );
        await controller.load();

        controller.selectRange(ChartRange.years5);

        expect(controller.view!.closes, hasLength(20));
      },
    );

    test(
      'el máximo y el mínimo salen de todos los cierres, no de los agrupados',
      () async {
        final controller = _controller(FakePriceHistory(bars: _bars()));
        await controller.load();

        controller.selectRange(ChartRange.all);

        expect(controller.view!.extremes!.high.value, 9999);
        expect(controller.view!.extremes!.low.value, 1);
      },
    );

    test('elegir el mismo periodo no notifica', () async {
      final controller = _controller(FakePriceHistory(bars: _bars()));
      await controller.load();
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.selectRange(ChartRange.year1);

      expect(notifications, 0);
    });

    test('elegir un periodo antes de cargar no rompe nada', () async {
      final controller = _controller(FakePriceHistory(bars: _bars()));

      controller.selectRange(ChartRange.month1);
      await controller.load();

      expect(controller.view!.closes, hasLength(31));
    });
  });

  group('PriceChartController medias', () {
    test('empiezan desactivadas y sin líneas (criterio 50)', () async {
      final controller = _controller(FakePriceHistory(bars: _bars()));
      await controller.load();

      expect(controller.showShortAverage, isFalse);
      expect(controller.showLongAverage, isFalse);
      expect(controller.view!.shortAverage, isEmpty);
      expect(controller.view!.longAverage, isEmpty);
    });

    test('activar la media de 50 añade su línea', () async {
      final controller = _controller(FakePriceHistory(bars: _bars()));
      await controller.load();

      controller.setShortAverage(isVisible: true);

      expect(controller.view!.shortAverage, isNotEmpty);
      expect(controller.view!.longAverage, isEmpty);
    });

    test('la media usa las sesiones anteriores al periodo', () async {
      final controller = _controller(FakePriceHistory(bars: _bars()));
      await controller.load();
      controller
        ..selectRange(ChartRange.month1)
        ..setLongAverage(isVisible: true);

      // Con 800 sesiones, la media de 200 existe ya el primer día del mes.
      expect(controller.view!.longAverage, hasLength(31));
    });

    test(
      'sin sesiones suficientes no se dibuja ni se inventa la media',
      () async {
        final controller = _controller(
          FakePriceHistory(bars: priceHistory(sessions: 150)),
        );
        await controller.load();

        controller
          ..setLongAverage(isVisible: true)
          ..setShortAverage(isVisible: true);

        expect(controller.view!.longAverage, isEmpty);
        expect(controller.view!.shortAverage, isNotEmpty);
        // La media de 50 empieza cuando hay 50 sesiones: 101 puntos de 150.
        expect(controller.view!.shortAverage, hasLength(101));
      },
    );

    test('desactivar la media quita su línea', () async {
      final controller = _controller(FakePriceHistory(bars: _bars()));
      await controller.load();
      controller.setShortAverage(isVisible: true);

      controller.setShortAverage(isVisible: false);

      expect(controller.view!.shortAverage, isEmpty);
    });
  });

  group('PriceChartController día y semana', () {
    test('elegir 1D carga las velas de 5 minutos y muestra la última sesión (criterio 59)', () async {
      final intraday = FakeIntradayHistory(
        byResolution: {IntradayResolution.minutes5: intradaySeries()},
      );
      final controller = _withIntraday(intraday);
      await controller.load();

      controller.selectRange(ChartRange.day);
      await Future<void>.delayed(Duration.zero);

      expect(intraday.calls.single.resolution, IntradayResolution.minutes5);
      final view = controller.view!;
      expect(view.isIntraday, isTrue);
      expect(view.closes, hasLength(12));
      expect(view.sessionStarts, [0]);
    });

    test('elegir 1S carga las de 30 minutos y muestra 5 sesiones pegadas (criterio 60)', () async {
      final intraday = FakeIntradayHistory(
        byResolution: {IntradayResolution.minutes30: intradaySeries()},
      );
      final controller = _withIntraday(intraday);
      await controller.load();

      controller.selectRange(ChartRange.week);
      await Future<void>.delayed(Duration.zero);

      expect(intraday.calls.single.resolution, IntradayResolution.minutes30);
      final view = controller.view!;
      expect(view.closes, hasLength(60));
      expect(view.sessionStarts, [0, 12, 24, 36, 48]);
    });

    test(
      'con menos de 5 sesiones muestra las que haya (criterio 67)',
      () async {
        final intraday = FakeIntradayHistory(
          byResolution: {
            IntradayResolution.minutes30: intradaySeries(sessions: 2),
          },
        );
        final controller = _withIntraday(intraday);
        controller.selectRange(ChartRange.week);
        await Future<void>.delayed(Duration.zero);

        expect(controller.view!.closes, hasLength(24));
        expect(controller.view!.sessionStarts, [0, 12]);
      },
    );

    test(
      'lleva la zona horaria y el retraso del proveedor (criterio 64)',
      () async {
        final intraday = FakeIntradayHistory(
          byResolution: {IntradayResolution.minutes5: intradaySeries()},
        );
        final controller = _withIntraday(intraday);
        controller.selectRange(ChartRange.day);
        await Future<void>.delayed(Duration.zero);

        expect(controller.view!.timezone, 'Europe/Madrid');
        expect(controller.view!.delay, const Duration(minutes: 15));
      },
    );

    test(
      'el máximo y el mínimo son los de la sesión mostrada (criterio 61)',
      () async {
        final intraday = FakeIntradayHistory(
          byResolution: {IntradayResolution.minutes5: intradaySeries()},
        );
        final controller = _withIntraday(intraday);
        controller.selectRange(ChartRange.day);
        await Future<void>.delayed(Duration.zero);

        expect(controller.view!.extremes!.high.value, 500);
        expect(controller.view!.extremes!.low.value, lessThan(110));
      },
    );

    test('las medias no se dibujan en intradía y se recuerdan al volver (criterio 63)', () async {
      final intraday = FakeIntradayHistory(
        byResolution: {IntradayResolution.minutes5: intradaySeries()},
      );
      final controller = _withIntraday(intraday);
      await controller.load();
      controller.setShortAverage(isVisible: true);

      controller.selectRange(ChartRange.day);
      await Future<void>.delayed(Duration.zero);
      expect(controller.view!.shortAverage, isEmpty);
      expect(controller.showShortAverage, isTrue);

      controller.selectRange(ChartRange.year1);
      expect(controller.view!.shortAverage, isNotEmpty);
    });

    test('mientras carga no hay vista y isLoading es true', () async {
      final intraday = FakeIntradayHistory(
        byResolution: {IntradayResolution.minutes5: intradaySeries()},
      )..gate = Completer<void>();
      final controller = _withIntraday(intraday);
      await controller.load();

      controller.selectRange(ChartRange.day);

      expect(controller.isLoading, isTrue);
      expect(controller.view, isNull);
      intraday.gate!.complete();
      await Future<void>.delayed(Duration.zero);
      expect(controller.isLoading, isFalse);
      expect(controller.view, isNotNull);
    });

    test('un fallo del intradía es solo de esa vista (criterio 66)', () async {
      final intraday = FakeIntradayHistory(error: const NetworkException());
      final controller = _withIntraday(intraday);
      await controller.load();

      controller.selectRange(ChartRange.day);
      await Future<void>.delayed(Duration.zero);

      expect(controller.view, isNull);
      expect(controller.error, isA<NetworkException>());
      controller.selectRange(ChartRange.year1);
      expect(controller.error, isNull);
      expect(controller.view, isNotNull);
    });

    test('Reintentar en intradía repite el intradía y no el diario', () async {
      final intraday = FakeIntradayHistory(error: const NetworkException());
      final history = FakePriceHistory(bars: priceHistory(sessions: 400));
      final controller = _withIntraday(intraday, history: history);
      await controller.load();
      controller.selectRange(ChartRange.day);
      await Future<void>.delayed(Duration.zero);

      await controller.retry();

      expect(intraday.calls, hasLength(2));
      expect(history.calls, hasLength(1));
    });

    test('Reintentar en un periodo diario repite el diario', () async {
      final history = FakePriceHistory(error: const NetworkException());
      final controller = _withIntraday(FakeIntradayHistory(), history: history);
      await controller.load();

      await controller.retry();

      expect(history.calls, hasLength(2));
    });

    test('el día funciona aunque el histórico diario falle', () async {
      final intraday = FakeIntradayHistory(
        byResolution: {IntradayResolution.minutes5: intradaySeries()},
      );
      final controller = _withIntraday(
        intraday,
        history: FakePriceHistory(error: const NetworkException()),
      );
      await controller.load();

      controller.selectRange(ChartRange.day);
      await Future<void>.delayed(Duration.zero);

      expect(controller.bars, isNull);
      expect(controller.view, isNotNull);
      expect(controller.error, isNull);
    });

    test('volver a 1D muestra lo que ya había mientras se refresca', () async {
      final intraday = FakeIntradayHistory(
        byResolution: {IntradayResolution.minutes5: intradaySeries()},
      );
      final controller = _withIntraday(intraday);
      controller.selectRange(ChartRange.day);
      await Future<void>.delayed(Duration.zero);
      controller.selectRange(ChartRange.year1);
      intraday.gate = Completer<void>();

      controller.selectRange(ChartRange.day);

      expect(controller.view, isNotNull);
      expect(controller.view!.isIntraday, isTrue);
      expect(intraday.calls, hasLength(2));
      intraday.gate!.complete();
    });

    test('"Actualizar datos" pide de nuevo el intradía si se está mirando (criterio 65)', () async {
      final intraday = FakeIntradayHistory(
        byResolution: {IntradayResolution.minutes5: intradaySeries()},
      );
      final controller = _withIntraday(intraday);
      await controller.load();
      controller.selectRange(ChartRange.day);
      await Future<void>.delayed(Duration.zero);

      await controller.load(forceRefresh: true);

      expect(intraday.calls.last.forceRefresh, isTrue);
      expect(intraday.calls, hasLength(2));
    });

    test('elegir 1D dos veces seguidas no abre dos cargas', () async {
      final intraday = FakeIntradayHistory(
        byResolution: {IntradayResolution.minutes5: intradaySeries()},
      )..gate = Completer<void>();
      final controller = _withIntraday(intraday);

      controller.selectRange(ChartRange.day);
      await controller.loadIntraday();
      intraday.gate!.complete();
      await Future<void>.delayed(Duration.zero);

      expect(intraday.calls, hasLength(1));
    });
  });

  group('PriceChartController en euros', () {
    // Tres días hábiles consecutivos con el mismo cierre en yenes y un tipo
    // distinto cada día: lo que cambia en euros es solo la divisa.
    final start = DateTime.utc(2026, 10, 6);
    List<DailyBar> yenBars() => [
      for (var i = 0; i < 3; i++)
        DailyBar(
          date: start.add(Duration(days: i)),
          open: 17000,
          high: 18000,
          low: 16000,
          close: 17000,
          volume: 100,
        ),
    ];
    final rates = ExchangeRateSeries(
      currency: 'JPY',
      points: [
        RatePoint(start, 170),
        RatePoint(start.add(const Duration(days: 1)), 175),
        RatePoint(start.add(const Duration(days: 2)), 200),
      ],
    );

    Future<(PriceChartController, DisplayCurrencyController)> build({
      FakeIntradayHistory? intraday,
      List<DailyBar>? bars,
      ExchangeRateSeries? series,
    }) async {
      final display = DisplayCurrencyController(
        getExchangeRates: GetExchangeRatesUseCase(
          FakeExchangeRates(byCurrency: {'JPY': series ?? rates}),
        ),
        now: () => DateTime.utc(2026, 10, 9),
      );
      final chart = PriceChartController(
        getPriceHistory: GetPriceHistoryUseCase(
          FakePriceHistory(bars: bars ?? yenBars()),
        ),
        getIntradayHistory: GetIntradayHistoryUseCase(
          intraday ?? FakeIntradayHistory(),
        ),
        symbol: 'TSE:7974',
        displayCurrency: display,
      );
      addTearDown(chart.dispose);
      addTearDown(display.dispose);
      await display.configure('JPY');
      await chart.load();
      return (chart, display);
    }

    test(
      'cada cierre se convierte con el tipo de su día (criterio 87)',
      () async {
        final (chart, _) = await build();

        final closes = chart.view!.closes.map((p) => p.value).toList();

        expect(closes[0], closeTo(17000 / 170, 1e-9));
        expect(closes[1], closeTo(17000 / 175, 1e-9));
        expect(closes[2], closeTo(17000 / 200, 1e-9));
      },
    );

    test(
      'la línea en euros se mueve aunque el precio en yenes no (criterio 87)',
      () async {
        final (chart, _) = await build();

        final closes = chart.view!.closes.map((p) => p.value).toList();

        expect(closes.first, greaterThan(closes.last));
      },
    );

    test('el máximo y el mínimo se toman de los cierres ya convertidos (criterio 87)', () async {
      final (chart, _) = await build();

      final extremes = chart.view!.extremes!;

      expect(extremes.high.date, start);
      expect(extremes.high.value, closeTo(100, 1e-9));
      expect(extremes.low.date, start.add(const Duration(days: 2)));
      expect(extremes.low.value, closeTo(85, 1e-9));
    });

    test(
      'las medias se calculan sobre los cierres convertidos (criterio 89)',
      () async {
        final bars = [
          for (var i = 0; i < 60; i++)
            DailyBar(
              date: DateTime.utc(2026, 8, 1).add(Duration(days: i)),
              open: 1000,
              high: 1000,
              low: 1000,
              close: 1000,
              volume: 1,
            ),
        ];
        final steady = ExchangeRateSeries(
          currency: 'JPY',
          points: [
            for (var i = 0; i < 60; i++)
              RatePoint(
                DateTime.utc(2026, 8, 1).add(Duration(days: i)),
                100.0 + i,
              ),
          ],
        );
        final (chart, _) = await build(bars: bars, series: steady);

        chart.setShortAverage(isVisible: true);

        // La media de 50 de los 50 últimos cierres convertidos (1000 / tipo).
        final expected =
            [for (var i = 10; i < 60; i++) 1000 / (100.0 + i)]
                .reduce((a, b) => a + b) /
            50;
        expect(chart.view!.shortAverage.last.value, closeTo(expected, 1e-9));
        // Una media de yenes dividida entre el último tipo no daría lo mismo.
        expect(
          chart.view!.shortAverage.last.value,
          isNot(closeTo(1000 / 159, 1e-3)),
        );
      },
    );

    test('elegir la divisa original devuelve los valores sin convertir (criterio 85)', () async {
      final (chart, display) = await build();

      display.showOriginal(original: true);

      expect(chart.view!.closes.map((p) => p.value), [17000, 17000, 17000]);
    });

    test('volver a euros convierte otra vez y avisa a los oyentes', () async {
      final (chart, display) = await build();
      display.showOriginal(original: true);
      var notifications = 0;
      chart.addListener(() => notifications++);

      display.showOriginal(original: false);

      expect(notifications, 1);
      expect(chart.view!.closes.first.value, closeTo(100, 1e-9));
    });

    test(
      'mientras llegan los tipos se dibuja la divisa original (criterio 96)',
      () async {
        final display = DisplayCurrencyController(
          getExchangeRates: GetExchangeRatesUseCase(
            FakeExchangeRates(byCurrency: {'JPY': rates})
              ..gate = Completer<void>(),
          ),
        );
        final chart = PriceChartController(
          getPriceHistory: GetPriceHistoryUseCase(
            FakePriceHistory(bars: yenBars()),
          ),
          getIntradayHistory: GetIntradayHistoryUseCase(FakeIntradayHistory()),
          symbol: 'TSE:7974',
          displayCurrency: display,
        );
        addTearDown(chart.dispose);
        unawaited(display.configure('JPY'));
        await chart.load();

        expect(chart.view!.closes.map((p) => p.value), [17000, 17000, 17000]);
      },
    );

    test('al llegar los tipos la gráfica pasa a euros sola', () async {
      final gate = Completer<void>();
      final display = DisplayCurrencyController(
        getExchangeRates: GetExchangeRatesUseCase(
          FakeExchangeRates(byCurrency: {'JPY': rates})..gate = gate,
        ),
      );
      final chart = PriceChartController(
        getPriceHistory: GetPriceHistoryUseCase(
          FakePriceHistory(bars: yenBars()),
        ),
        getIntradayHistory: GetIntradayHistoryUseCase(FakeIntradayHistory()),
        symbol: 'TSE:7974',
        displayCurrency: display,
      );
      addTearDown(chart.dispose);
      final configuring = display.configure('JPY');
      await chart.load();

      gate.complete();
      await configuring;

      expect(chart.view!.closes.first.value, closeTo(100, 1e-9));
    });

    test('los días anteriores al primer tipo no se dibujan en euros', () async {
      final shortRates = ExchangeRateSeries(
        currency: 'JPY',
        points: [RatePoint(start.add(const Duration(days: 1)), 175)],
      );
      final (chart, _) = await build(series: shortRates);

      expect(chart.view!.closes, hasLength(2));
      expect(chart.view!.closes.first.date, start.add(const Duration(days: 1)));
    });

    test(
      'el día usa el último tipo para todos los puntos (criterio 88)',
      () async {
        final intraday = FakeIntradayHistory(
          byResolution: {IntradayResolution.minutes5: intradaySeries()},
        );
        final (chart, _) = await build(intraday: intraday);

        chart.selectRange(ChartRange.day);
        await Future<void>.delayed(Duration.zero);

        final original = intradaySeries().bars
            .where((b) => b.time.day == intradaySeries().bars.last.time.day)
            .map((b) => b.close)
            .toList();
        final converted = chart.view!.closes.map((p) => p.value).toList();
        expect(converted, hasLength(original.length));
        for (var i = 0; i < converted.length; i++) {
          expect(converted[i], closeTo(original[i] / 200, 1e-9));
        }
      },
    );

    test('la semana en la divisa original no convierte nada', () async {
      final intraday = FakeIntradayHistory(
        byResolution: {IntradayResolution.minutes30: intradaySeries()},
      );
      final (chart, display) = await build(intraday: intraday);
      display.showOriginal(original: true);

      chart.selectRange(ChartRange.week);
      await Future<void>.delayed(Duration.zero);

      expect(chart.view!.extremes!.high.value, 500);
    });

    test('tras liberar la gráfica ya no escucha a la moneda', () async {
      final display = DisplayCurrencyController(
        getExchangeRates: GetExchangeRatesUseCase(
          FakeExchangeRates(byCurrency: {'JPY': rates}),
        ),
      );
      addTearDown(display.dispose);
      final chart = PriceChartController(
        getPriceHistory: GetPriceHistoryUseCase(
          FakePriceHistory(bars: yenBars()),
        ),
        getIntradayHistory: GetIntradayHistoryUseCase(FakeIntradayHistory()),
        symbol: 'TSE:7974',
        displayCurrency: display,
      );
      await display.configure('JPY');
      chart.dispose();

      // Si siguiera escuchando, notificaría a una gráfica ya liberada.
      expect(() => display.showOriginal(original: true), returnsNormally);
    });

    test('sin controller de moneda dibuja la divisa original', () async {
      final chart = PriceChartController(
        getPriceHistory: GetPriceHistoryUseCase(
          FakePriceHistory(bars: yenBars()),
        ),
        getIntradayHistory: GetIntradayHistoryUseCase(FakeIntradayHistory()),
        symbol: 'TSE:7974',
      );
      addTearDown(chart.dispose);
      await chart.load();

      expect(chart.view!.closes.map((p) => p.value), [17000, 17000, 17000]);
    });
  });
}

/// Histórico que falla cuando el test lo pide.
class _FlakyHistory extends FakePriceHistory {
  _FlakyHistory(List<DailyBar> bars) : super(bars: bars);

  bool shouldFail = false;

  @override
  Future<List<DailyBar>> fetchPriceHistory(
    String symbol, {
    bool forceRefresh = false,
  }) {
    if (shouldFail) throw const NetworkException();
    return super.fetchPriceHistory(symbol, forceRefresh: forceRefresh);
  }
}
