import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/analyze_stock_use_case.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/get_exchange_rates_use_case.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/open_news_use_case.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/exchange_rate_series.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/history_entry.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/stock_analyzer.dart';
import 'package:stock_app/features/analisis_accion/presentation/controllers/analysis_controller.dart';
import 'package:stock_app/features/analisis_accion/presentation/controllers/display_currency_controller.dart';
import 'package:stock_app/features/analisis_accion/presentation/screens/analysis_screen.dart';

import '../../application/fake_ports.dart';
import '../../domain/motor/synthetic_companies.dart';

void main() {
  testWidgets('la pantalla configura la moneda y enseña el selector', (
    tester,
  ) async {
    final result = const StockAnalyzer().analyze(
      buildCompany(companyOverview: overview(currency: 'JPY')),
      referenceDate: referenceDate,
    );
    final display = DisplayCurrencyController(
      getExchangeRates: GetExchangeRatesUseCase(
        FakeExchangeRates(
          byCurrency: {
            'JPY': ExchangeRateSeries(
              currency: 'JPY',
              points: [RatePoint(DateTime.utc(2000), 170)],
            ),
          },
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AnalysisScreen(
          displayCurrency: display,
          controller: AnalysisController(
            openNews: OpenNewsUseCase(FakeLinkOpener()),
            analyzeStock: AnalyzeStockUseCase(
              marketData: FakeMarketData(),
              history: FakeHistory(),
              now: () => referenceDate,
            ),
            symbol: 'CALI',
            initialEntry: HistoryEntry(
              result: result,
              analyzedAt: referenceDate,
            ),
            now: () => referenceDate,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(display.status, CurrencyStatus.ready);
    expect(find.byType(SegmentedButton<bool>), findsOneWidget);
  });

  testWidgets('tras analizar desde cero también enseña el selector', (
    tester,
  ) async {
    final display = DisplayCurrencyController(
      getExchangeRates: GetExchangeRatesUseCase(
        FakeExchangeRates(
          byCurrency: {
            'JPY': ExchangeRateSeries(
              currency: 'JPY',
              points: [RatePoint(DateTime.utc(2000), 170)],
            ),
          },
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AnalysisScreen(
          displayCurrency: display,
          controller: AnalysisController(
            openNews: OpenNewsUseCase(FakeLinkOpener()),
            analyzeStock: AnalyzeStockUseCase(
              marketData: FakeMarketData(
                stockData: buildCompany(
                  companyOverview: overview(currency: 'JPY'),
                ),
              ),
              history: FakeHistory(),
              now: () => referenceDate,
            ),
            symbol: 'CALI',
            now: () => referenceDate,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(display.status, CurrencyStatus.ready);
    expect(find.byType(SegmentedButton<bool>), findsOneWidget);
  });
}
