import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/get_price_history_use_case.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/daily_bar.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';
import 'package:stock_app/features/analisis_accion/presentation/controllers/price_chart_controller.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/price_chart_panel.dart';

import '../../application/fake_ports.dart';
import '../../domain/motor/synthetic_companies.dart';

Future<(PriceChartController, FakePriceHistory)> _pump(
  WidgetTester tester, {
  FakePriceHistory? port,
  bool load = true,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final history = port ?? FakePriceHistory(bars: priceHistory(sessions: 800));
  final controller = PriceChartController(
    getPriceHistory: GetPriceHistoryUseCase(history),
    symbol: 'TSE:7974',
  );
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: PriceChartPanel(controller: controller, currency: 'JPY'),
        ),
      ),
    ),
  );
  if (load) {
    await controller.load();
    await tester.pump();
  }
  return (controller, history);
}

LineChartData _chartData(WidgetTester tester) =>
    tester.widget<LineChart>(find.byType(LineChart)).data;

void main() {
  group('PriceChartPanel', () {
    testWidgets('muestra un indicador mientras carga', (tester) async {
      await _pump(tester, load: false);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
    });

    testWidgets('con histórico muestra la gráfica, el selector y el pie', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.byType(LineChart), findsOneWidget);
      for (final label in ['1M', '3M', '6M', '1A', '5A', 'Todo']) {
        expect(find.widgetWithText(ChoiceChip, label), findsOneWidget);
      }
      expect(find.text(priceChartSourceText), findsOneWidget);
    });

    testWidgets('empieza en 1 año (criterio 46)', (tester) async {
      await _pump(tester);

      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, '1A'),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('elegir un periodo redibuja la gráfica (criterio 47)', (
      tester,
    ) async {
      await _pump(tester);
      final before = _chartData(tester).lineBarsData.first.spots.length;

      await tester.tap(find.widgetWithText(ChoiceChip, '1M'));
      await tester.pump();

      final after = _chartData(tester).lineBarsData.first.spots.length;
      expect(after, 31);
      expect(after, lessThan(before));
    });

    testWidgets(
      'muestra el máximo y el mínimo con valor y fecha (criterio 48)',
      (tester) async {
        await _pump(tester);

        expect(find.textContaining('Máx '), findsOneWidget);
        expect(find.textContaining('Mín '), findsOneWidget);
        expect(find.textContaining('JPY'), findsWidgets);
        expect(find.textContaining(RegExp(r'\d{2}/\d{2}/\d{4}')), findsWidgets);
      },
    );

    testWidgets('marca el máximo y el mínimo con puntos en la línea', (
      tester,
    ) async {
      await _pump(tester);

      final bar = _chartData(tester).lineBarsData.first;
      final marked = bar.spots
          .where((spot) => bar.dotData.checkToShowDot(spot, bar))
          .length;
      expect(marked, 2);
    });

    testWidgets('las medias empiezan desactivadas y se activan una a una', (
      tester,
    ) async {
      await _pump(tester);
      expect(_chartData(tester).lineBarsData, hasLength(1));

      await tester.tap(find.widgetWithText(FilterChip, 'Media 50'));
      await tester.pump();
      expect(_chartData(tester).lineBarsData, hasLength(2));

      await tester.tap(find.widgetWithText(FilterChip, 'Media 200'));
      await tester.pump();
      expect(_chartData(tester).lineBarsData, hasLength(3));
    });

    testWidgets('desactivar una media quita su línea', (tester) async {
      await _pump(tester);
      await tester.tap(find.widgetWithText(FilterChip, 'Media 50'));
      await tester.pump();

      await tester.tap(find.widgetWithText(FilterChip, 'Media 50'));
      await tester.pump();

      expect(_chartData(tester).lineBarsData, hasLength(1));
    });

    testWidgets(
      'una media sin sesiones suficientes no dibuja nada (criterio 50)',
      (tester) async {
        await _pump(
          tester,
          port: FakePriceHistory(bars: priceHistory(sessions: 120)),
        );

        await tester.tap(find.widgetWithText(FilterChip, 'Media 200'));
        await tester.pump();

        expect(_chartData(tester).lineBarsData, hasLength(1));
      },
    );

    testWidgets('una serie sin variación se dibuja sin romperse', (
      tester,
    ) async {
      final flat = [
        for (final bar in priceHistory(sessions: 60))
          DailyBar(
            date: bar.date,
            open: 100,
            high: 100,
            low: 100,
            close: 100,
            volume: 1,
          ),
      ];
      await _pump(tester, port: FakePriceHistory(bars: flat));

      final data = _chartData(tester);

      expect(tester.takeException(), isNull);
      expect(data.maxY, greaterThan(data.minY));
    });

    testWidgets('sin histórico muestra el error con Reintentar (criterio 53)', (
      tester,
    ) async {
      final port = FakePriceHistory(error: const NetworkException());
      await _pump(tester, port: port);

      expect(find.text(priceChartErrorText), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      expect(port.calls, hasLength(2));
    });
  });
}
