import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/get_intraday_history_use_case.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/get_price_history_use_case.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/daily_bar.dart';
import 'package:stock_app/features/analisis_accion/domain/chart/intraday_resolution.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';
import 'package:stock_app/features/analisis_accion/presentation/controllers/price_chart_controller.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/info_builder.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/price_chart_panel.dart';

import '../../application/fake_ports.dart';
import '../../domain/motor/synthetic_companies.dart';
import '../intraday_samples.dart';

Future<(PriceChartController, FakePriceHistory)> _pump(
  WidgetTester tester, {
  InfoBuilder? buildInfo,
  FakePriceHistory? port,
  FakeIntradayHistory? intraday,
  bool load = true,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final history = port ?? FakePriceHistory(bars: priceHistory(sessions: 800));
  final controller = PriceChartController(
    getPriceHistory: GetPriceHistoryUseCase(history),
    getIntradayHistory: GetIntradayHistoryUseCase(
      intraday ?? FakeIntradayHistory(),
    ),
    symbol: 'TSE:7974',
  );
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: PriceChartPanel(
            controller: controller,
            currency: 'JPY',
            buildInfo: buildInfo,
          ),
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
      for (final label in ['1D', '1S', '1M', '3M', '6M', '1A', '5A', 'Todo']) {
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

  group('PriceChartPanel día y semana', () {
    FakeIntradayHistory sample({
      String? timezone = 'Europe/Madrid',
      Duration? delay = const Duration(minutes: 15),
    }) => FakeIntradayHistory(
      byResolution: {
        IntradayResolution.minutes5: intradaySeries(
          timezone: timezone,
          delay: delay,
        ),
        IntradayResolution.minutes30: intradaySeries(
          timezone: timezone,
          delay: delay,
        ),
      },
    );

    Future<void> choose(WidgetTester tester, String label) async {
      await tester.tap(find.widgetWithText(ChoiceChip, label));
      await tester.pump();
      await tester.pump();
    }

    testWidgets(
      '1D dibuja la última sesión con el eje por orden de velas (criterio 59)',
      (tester) async {
        await _pump(tester, intraday: sample());

        await choose(tester, '1D');

        final spots = _chartData(tester).lineBarsData.first.spots;
        expect(spots, hasLength(12));
        expect(spots.first.x, 0);
        expect(spots.last.x, 11);
      },
    );

    testWidgets('1D etiqueta el eje con horas en punto de la bolsa', (
      tester,
    ) async {
      await _pump(tester, intraday: sample());

      await choose(tester, '1D');

      // Las velas empiezan a las 07:00 UTC = 09:00 en Madrid (verano).
      expect(find.text('09:00'), findsOneWidget);
      expect(find.text('10:00'), findsOneWidget);
      expect(find.text('14:00'), findsOneWidget);
      expect(find.text('07:00'), findsNothing);
    });

    testWidgets(
      '1S dibuja 5 sesiones pegadas y etiqueta el día de cada una (criterio 60)',
      (tester) async {
        await _pump(tester, intraday: sample());

        await choose(tester, '1S');

        final spots = _chartData(tester).lineBarsData.first.spots;
        expect(spots, hasLength(60));
        for (var i = 0; i < spots.length; i++) {
          expect(spots[i].x, i.toDouble());
        }
        for (final label in ['mié 30', 'jue 1', 'vie 2', 'lun 5', 'mar 6']) {
          expect(find.text(label), findsOneWidget, reason: label);
        }
      },
    );

    testWidgets('marca el máximo y el mínimo con día y hora (criterios 61)', (
      tester,
    ) async {
      await _pump(tester, intraday: sample());

      await choose(tester, '1D');

      // El máximo está en la vela 6 de la última sesión (martes 6): 10:00 UTC.
      expect(find.textContaining('Máx 500,00'), findsOneWidget);
      expect(find.textContaining(RegExp(r'6 oct \d{2}:\d{2}')), findsWidgets);
      final bar = _chartData(tester).lineBarsData.first;
      final marked = bar.spots
          .where((spot) => bar.dotData.checkToShowDot(spot, bar))
          .length;
      expect(marked, 2);
    });

    testWidgets(
      'oculta las medias en día y semana y las recupera después (criterio 63)',
      (tester) async {
        await _pump(tester, intraday: sample());
        await tester.tap(find.widgetWithText(FilterChip, 'Media 50'));
        await tester.pump();

        await choose(tester, '1D');
        expect(find.widgetWithText(FilterChip, 'Media 50'), findsNothing);
        expect(find.widgetWithText(FilterChip, 'Media 200'), findsNothing);

        await choose(tester, '1A');
        final chip = tester.widget<FilterChip>(
          find.widgetWithText(FilterChip, 'Media 50'),
        );
        expect(chip.selected, isTrue);
      },
    );

    testWidgets(
      'el pie de 1D dice la sesión, las horas de la bolsa y el retraso (criterio 64)',
      (tester) async {
        await _pump(tester, intraday: sample());

        await choose(tester, '1D');

        expect(find.textContaining('Sesión del 06/10/2026.'), findsOneWidget);
        expect(find.textContaining('Horas de la bolsa.'), findsOneWidget);
        expect(
          find.textContaining('Datos con 15 minutos de retraso.'),
          findsOneWidget,
        );
        expect(find.textContaining('Datos de TradingView.'), findsOneWidget);
      },
    );

    testWidgets('el pie de 1S cuenta las sesiones que se ven', (tester) async {
      await _pump(tester, intraday: sample());

      await choose(tester, '1S');

      expect(find.textContaining('Últimas 5 sesiones.'), findsOneWidget);
    });

    testWidgets(
      'con una zona horaria desconocida usa la hora del dispositivo y lo dice',
      (tester) async {
        await _pump(tester, intraday: sample(timezone: 'Mars/Olympus'));

        await choose(tester, '1D');

        expect(find.textContaining('Horas de tu dispositivo.'), findsOneWidget);
        expect(find.textContaining('Horas de la bolsa.'), findsNothing);
      },
    );

    testWidgets('sin retraso informado no se menciona', (tester) async {
      await _pump(tester, intraday: sample(delay: null));

      await choose(tester, '1D');

      expect(find.textContaining('retraso'), findsNothing);
    });

    testWidgets(
      'si falla el intradía avisa solo ahí y los periodos largos siguen (criterio 66)',
      (tester) async {
        final intraday = FakeIntradayHistory(error: const NetworkException());
        await _pump(tester, intraday: intraday);

        await choose(tester, '1D');

        expect(find.text(priceChartErrorText), findsOneWidget);
        expect(find.byType(LineChart), findsNothing);
        expect(find.widgetWithText(ChoiceChip, '1A'), findsOneWidget);
        await choose(tester, '1A');
        expect(find.text(priceChartErrorText), findsNothing);
        expect(find.byType(LineChart), findsOneWidget);
      },
    );

    testWidgets('Reintentar en el intradía vuelve a pedir el intradía', (
      tester,
    ) async {
      final intraday = FakeIntradayHistory(error: const NetworkException());
      final (_, history) = await _pump(tester, intraday: intraday);
      await choose(tester, '1D');

      await tester.tap(find.text('Reintentar'));
      await tester.pump();

      expect(intraday.calls, hasLength(2));
      expect(history.calls, hasLength(1));
    });

    testWidgets('mientras carga el día muestra un indicador', (tester) async {
      final intraday = sample()..gate = Completer<void>();
      await _pump(tester, intraday: intraday);

      await tester.tap(find.widgetWithText(ChoiceChip, '1D'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      intraday.gate!.complete();
      await tester.pump();
    });

    testWidgets('el tooltip del día muestra el día y la hora', (tester) async {
      await _pump(tester, intraday: sample());
      await choose(tester, '1D');

      final data = _chartData(tester);
      final bar = data.lineBarsData.first;
      final item = data.lineTouchData.touchTooltipData.getTooltipItems([
        LineBarSpot(bar, 0, bar.spots[6]),
      ]).single!;

      // La vela 6 del martes 6: 07:00 + 3 h = 10:00 UTC = 12:00 en Madrid.
      expect(item.text, contains('6 oct 12:00'));
      expect(item.text, contains('500,00'));
    });
  });

  group('PriceChartPanel explicaciones', () {
    Widget fakeInfo(BuildContext context, String topicId) =>
        Text('Explicación de $topicId');

    testWidgets('sin buildInfo no hay iconos de información', (tester) async {
      await _pump(tester);

      expect(find.byIcon(Icons.info_outline), findsNothing);
    });

    testWidgets('la explicación de cada media empieza oculta (criterio 68)', (
      tester,
    ) async {
      await _pump(tester, buildInfo: fakeInfo);

      expect(find.text('Explicación de media_50'), findsNothing);
      expect(find.text('Explicación de media_200'), findsNothing);
      expect(find.text('Explicación de grafico_precio'), findsNothing);
    });

    testWidgets(
      'el icono de la media de 50 despliega su explicación y se oculta (criterio 68)',
      (tester) async {
        await _pump(tester, buildInfo: fakeInfo);

        await tester.tap(find.byTooltip('Qué es la media de 50 sesiones'));
        await tester.pumpAndSettle();
        expect(find.text('Explicación de media_50'), findsOneWidget);
        expect(find.text('Explicación de media_200'), findsNothing);

        await tester.tap(find.byTooltip('Ocultar la media de 50 sesiones'));
        await tester.pumpAndSettle();
        expect(find.text('Explicación de media_50'), findsNothing);
      },
    );

    testWidgets('el icono de la media de 200 despliega la suya', (
      tester,
    ) async {
      await _pump(tester, buildInfo: fakeInfo);

      await tester.tap(find.byTooltip('Qué es la media de 200 sesiones'));
      await tester.pumpAndSettle();

      expect(find.text('Explicación de media_200'), findsOneWidget);
    });

    testWidgets('las dos explicaciones pueden estar abiertas a la vez', (
      tester,
    ) async {
      await _pump(tester, buildInfo: fakeInfo);

      await tester.tap(find.byTooltip('Qué es la media de 50 sesiones'));
      await tester.tap(find.byTooltip('Qué es la media de 200 sesiones'));
      await tester.pumpAndSettle();

      expect(find.text('Explicación de media_50'), findsOneWidget);
      expect(find.text('Explicación de media_200'), findsOneWidget);
    });

    testWidgets(
      'el icono del título despliega cómo leer la gráfica (criterio 69)',
      (tester) async {
        await _pump(tester, buildInfo: fakeInfo);

        expect(find.text('Evolución del precio'), findsOneWidget);
        await tester.tap(find.byTooltip('Qué es cómo leer la gráfica'));
        await tester.pumpAndSettle();

        expect(find.text('Explicación de grafico_precio'), findsOneWidget);
      },
    );

    testWidgets('activar una media no despliega ni oculta su explicación', (
      tester,
    ) async {
      await _pump(tester, buildInfo: fakeInfo);
      await tester.tap(find.byTooltip('Qué es la media de 50 sesiones'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilterChip, 'Media 50'));
      await tester.pumpAndSettle();

      expect(find.text('Explicación de media_50'), findsOneWidget);
    });

    testWidgets('en 1D no hay iconos de las medias pero sí el de la gráfica', (
      tester,
    ) async {
      await _pump(
        tester,
        buildInfo: fakeInfo,
        intraday: FakeIntradayHistory(
          byResolution: {IntradayResolution.minutes5: intradaySeries()},
        ),
      );

      await tester.tap(find.widgetWithText(ChoiceChip, '1D'));
      await tester.pump();
      await tester.pump();

      expect(find.byTooltip('Qué es la media de 50 sesiones'), findsNothing);
      expect(find.byTooltip('Qué es cómo leer la gráfica'), findsOneWidget);
    });
  });
}
