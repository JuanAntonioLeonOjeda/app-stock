import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/stock_analyzer.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/verdict_header.dart';

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
}
