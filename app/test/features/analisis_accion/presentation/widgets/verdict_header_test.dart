import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/get_exchange_rates_use_case.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/exchange_rate_series.dart';
import 'package:stock_app/features/analisis_accion/presentation/controllers/display_currency_controller.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/stock_analyzer.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/verdict_header.dart';

import '../../application/fake_ports.dart';
import '../../domain/motor/synthetic_companies.dart';

AnalysisResult _result({String? isin, String? exchange, bool? isPrimary}) =>
    const StockAnalyzer().analyze(
      buildCompany(
        companyOverview: overview(
          isin: isin,
          exchange: exchange,
          isPrimaryListing: isPrimary,
        ),
      ),
      referenceDate: referenceDate,
    );

Future<void> _pump(WidgetTester tester, AnalysisResult result) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: VerdictHeader(result: result)),
      ),
    );

void main() {
  group('VerdictHeader identificación de la cotización', () {
    testWidgets(
      'muestra la bolsa, el ISIN y "Cotización principal" (criterio 80)',
      (tester) async {
        await _pump(
          tester,
          _result(isin: 'ES0144580Y14', exchange: 'BME', isPrimary: true),
        );

        expect(find.text('BME · ISIN ES0144580Y14'), findsOneWidget);
        expect(find.text('Cotización principal'), findsOneWidget);
      },
    );

    testWidgets('en otra cotización lo dice', (tester) async {
      await _pump(
        tester,
        _result(isin: 'JP3756600007', exchange: 'GETTEX', isPrimary: false),
      );

      expect(find.text('GETTEX · ISIN JP3756600007'), findsOneWidget);
      expect(find.text('Otra cotización'), findsOneWidget);
      expect(find.text('Cotización principal'), findsNothing);
    });

    testWidgets(
      'un análisis antiguo, sin esos datos, no muestra la línea (criterio 81)',
      (tester) async {
        await _pump(tester, _result());

        expect(find.textContaining('ISIN'), findsNothing);
        expect(find.text('Cotización principal'), findsNothing);
        expect(find.text('Otra cotización'), findsNothing);
        expect(find.text('Calidad S.A.'), findsOneWidget);
      },
    );

    testWidgets('solo con la bolsa muestra solo la bolsa', (tester) async {
      await _pump(tester, _result(exchange: 'BME'));

      expect(find.text('BME'), findsOneWidget);
      expect(find.textContaining('ISIN'), findsNothing);
    });
  });

  group('VerdictHeader precio en euros', () {
    testWidgets('sin controlador de moneda enseña la divisa original', (
      tester,
    ) async {
      final result = _result();
      await _pump(tester, result);

      expect(find.textContaining(result.currency ?? 'USD'), findsWidgets);
      expect(find.byType(SegmentedButton<bool>), findsNothing);
    });

    testWidgets('con tipos enseña el precio en euros y vuelve al original', (
      tester,
    ) async {
      final result = _result();
      final currency = result.currency!;
      final price = result.price!;
      final day = result.lastCloseDate ?? referenceDate;
      final display = DisplayCurrencyController(
        getExchangeRates: GetExchangeRatesUseCase(
          FakeExchangeRates(
            byCurrency: {
              currency: ExchangeRateSeries(
                currency: currency,
                points: [RatePoint(DateTime.utc(2000), 2)],
              ),
            },
          ),
        ),
        now: () => day,
      );
      addTearDown(display.dispose);
      await display.configure(currency);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerdictHeader(result: result, display: display),
          ),
        ),
      );

      expect(find.textContaining('EUR'), findsWidgets);
      expect(
        find.textContaining('${price / 2}'.split('.').first),
        findsWidgets,
      );
      display.showOriginal(original: true);
      await tester.pump();
      expect(find.textContaining(currency), findsWidgets);
    });
  });
}
