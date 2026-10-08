import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/get_price_history_use_case.dart';
import 'package:stock_app/features/analisis_accion/domain/chart/chart_range.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/daily_bar.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';
import 'package:stock_app/features/analisis_accion/presentation/controllers/price_chart_controller.dart';

import '../../application/fake_ports.dart';
import '../../domain/motor/synthetic_companies.dart';

PriceChartController _controller(FakePriceHistory port) => PriceChartController(
  getPriceHistory: GetPriceHistoryUseCase(port),
  symbol: 'TSE:7974',
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
