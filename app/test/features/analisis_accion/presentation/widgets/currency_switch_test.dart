import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/get_exchange_rates_use_case.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/exchange_rate_series.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';
import 'package:stock_app/features/analisis_accion/presentation/controllers/display_currency_controller.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/currency_switch.dart';

import '../../application/fake_ports.dart';

final _series = ExchangeRateSeries(
  currency: 'JPY',
  points: [RatePoint(DateTime.utc(2026, 10, 8), 177.05)],
);

DisplayCurrencyController _controller(
  FakeExchangeRates rates, {
  DateTime? now,
}) {
  final controller = DisplayCurrencyController(
    getExchangeRates: GetExchangeRatesUseCase(rates),
    now: () => now ?? DateTime.utc(2026, 10, 9),
  );
  addTearDown(controller.dispose);
  return controller;
}

Future<void> _pump(WidgetTester tester, DisplayCurrencyController controller) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CurrencySwitch(controller: controller, originalPrice: 7851),
        ),
      ),
    );

void main() {
  group('CurrencySwitch', () {
    testWidgets('en euros no pinta nada (criterio 86)', (tester) async {
      final controller = _controller(FakeExchangeRates());
      await controller.configure('EUR');

      await _pump(tester, controller);

      expect(find.byType(SegmentedButton<bool>), findsNothing);
    });

    testWidgets('con tipos muestra el selector y la nota (criterio 85)', (
      tester,
    ) async {
      final controller = _controller(
        FakeExchangeRates(byCurrency: {'JPY': _series}),
      );
      await controller.configure('JPY');

      await _pump(tester, controller);

      expect(find.text('EUR'), findsOneWidget);
      expect(find.text('JPY'), findsOneWidget);
      expect(
        find.text(
          'Equivale a 7.851,00 JPY · 1 € = 177,05 JPY (BCE, 08/10/2026)',
        ),
        findsOneWidget,
      );
    });

    testWidgets('elegir la divisa original quita la nota', (tester) async {
      final controller = _controller(
        FakeExchangeRates(byCurrency: {'JPY': _series}),
      );
      await controller.configure('JPY');
      await _pump(tester, controller);

      await tester.tap(find.text('JPY'));
      await tester.pump();

      expect(controller.isInEuros, isFalse);
      expect(find.textContaining('1 € ='), findsNothing);
    });

    testWidgets('un tipo de hace días lo avisa (criterio 97)', (tester) async {
      final controller = _controller(
        FakeExchangeRates(byCurrency: {'JPY': _series}),
        now: DateTime.utc(2026, 10, 20),
      );
      await controller.configure('JPY');

      await _pump(tester, controller);

      expect(find.textContaining('tipo de hace 12 días'), findsOneWidget);
    });

    testWidgets('mientras llegan los tipos lo dice (criterio 96)', (
      tester,
    ) async {
      final rates = FakeExchangeRates(byCurrency: {'JPY': _series})
        ..gate = Completer<void>();
      final controller = _controller(rates);
      final configuring = controller.configure('JPY');

      await _pump(tester, controller);

      expect(find.text('Convirtiendo a euros…'), findsOneWidget);
      rates.gate!.complete();
      await configuring;
    });

    testWidgets('sin tipo para la moneda lo dice', (tester) async {
      final controller = _controller(FakeExchangeRates());
      await controller.configure('SAR');

      await _pump(tester, controller);

      expect(find.text('Sin tipo de cambio del BCE para SAR'), findsOneWidget);
    });

    testWidgets('si falla ofrece reintentar', (tester) async {
      final rates = FakeExchangeRates(error: const NetworkException('sin red'));
      final controller = _controller(rates);
      await controller.configure('JPY');
      await _pump(tester, controller);

      expect(find.text('No se ha podido convertir a euros'), findsOneWidget);
      await tester.tap(find.text('Reintentar'));
      await tester.pump();

      expect(rates.calls, hasLength(2));
    });

    testWidgets('con peniques el tipo se muestra en la divisa mayor', (
      tester,
    ) async {
      final controller = _controller(
        FakeExchangeRates(
          byCurrency: {
            'GBP': ExchangeRateSeries(
              currency: 'GBP',
              points: [RatePoint(DateTime.utc(2026, 10, 8), 0.84698)],
            ),
          },
        ),
      );
      await controller.configure('GBX');

      await _pump(tester, controller);

      expect(find.textContaining('1 € = 0,8470 GBP'), findsOneWidget);
      expect(find.text('GBX'), findsOneWidget);
    });
  });
}
