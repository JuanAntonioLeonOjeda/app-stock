import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/load_history_use_case.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/search_symbol_use_case.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/history_entry.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/stock_analyzer.dart';
import 'package:stock_app/features/analisis_accion/presentation/controllers/home_controller.dart';
import 'package:stock_app/features/analisis_accion/presentation/screens/home_screen.dart';

import '../../application/fake_ports.dart';
import '../../domain/motor/synthetic_companies.dart';
import '../../search_samples.dart';

/// Pantalla de resultado de mentira: solo muestra qué se abrió.
Widget _fakeAnalysisScreen(String symbol, {HistoryEntry? entry}) => Scaffold(
  body: Text('Análisis de $symbol${entry == null ? '' : ' (historial)'}'),
);

Future<void> _pumpHome(
  WidgetTester tester,
  FakeMarketData marketData, {
  FakeHistory? history,
  void Function(BuildContext context)? onOpenLearn,
}) async {
  final controller = HomeController(
    searchSymbol: SearchSymbolUseCase(marketData),
    loadHistory: LoadHistoryUseCase(history ?? FakeHistory()),
  );
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: HomeScreen(
        controller: controller,
        buildAnalysisScreen: _fakeAnalysisScreen,
        onOpenLearn: onOpenLearn,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _search(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.tap(find.byTooltip('Buscar'));
  await tester.pumpAndSettle();
}

void main() {
  group('HomeScreen resultados agrupados', () {
    testWidgets(
      'una empresa con varias cotizaciones es una sola fila con la principal marcada (criterio 72)',
      (tester) async {
        final marketData = FakeMarketData(
          matches: [tescoFrankfurt, tescoLondon, tescoReceipt],
        );
        await _pumpHome(tester, marketData);

        await _search(tester, 'tesco');

        expect(find.text('Tesco PLC'), findsOneWidget);
        expect(find.text('Principal'), findsOneWidget);
        expect(find.text('Otras cotizaciones (1)'), findsOneWidget);
      },
    );

    testWidgets('los certificados ADR no se ven hasta pedirlos (criterio 75)', (
      tester,
    ) async {
      final marketData = FakeMarketData(matches: [tescoLondon, tescoReceipt]);
      await _pumpHome(tester, marketData);

      await _search(tester, 'tesco');

      expect(find.text('Tesco PLC ADR'), findsNothing);
      expect(find.text('Mostrar certificados ADR (1)'), findsOneWidget);
      await tester.tap(find.text('Mostrar certificados ADR (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Tesco PLC ADR'), findsOneWidget);
      expect(find.text('Ocultar certificados ADR'), findsOneWidget);
    });

    testWidgets('ocultarlos otra vez quita sus filas', (tester) async {
      final marketData = FakeMarketData(matches: [tescoLondon, tescoReceipt]);
      await _pumpHome(tester, marketData);
      await _search(tester, 'tesco');
      await tester.tap(find.text('Mostrar certificados ADR (1)'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ocultar certificados ADR'));
      await tester.pumpAndSettle();

      expect(find.text('Tesco PLC ADR'), findsNothing);
    });

    testWidgets('sin certificados no hay botón de ADR', (tester) async {
      await _pumpHome(tester, FakeMarketData(matches: [tescoLondon]));

      await _search(tester, 'tesco');

      expect(find.textContaining('certificados ADR'), findsNothing);
    });

    testWidgets(
      'elegir otra cotización del desplegable analiza esa (criterio 74)',
      (tester) async {
        final marketData = FakeMarketData(
          matches: [tescoLondon, tescoFrankfurt],
        );
        await _pumpHome(tester, marketData);
        await _search(tester, 'tesco');

        await tester.tap(find.text('Otras cotizaciones (1)'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Gettex · DE · EUR'));
        await tester.pumpAndSettle();

        expect(find.text('Análisis de GETTEX:TCO'), findsOneWidget);
      },
    );
  });

  group('HomeScreen aprender', () {
    testWidgets('con onOpenLearn muestra "Aprender" y lo abre', (tester) async {
      var opened = 0;
      await _pumpHome(tester, FakeMarketData(), onOpenLearn: (_) => opened++);

      await tester.tap(find.text('Aprender'));

      expect(opened, 1);
    });

    testWidgets('sin onOpenLearn no hay acceso "Aprender"', (tester) async {
      await _pumpHome(tester, FakeMarketData());

      expect(find.text('Aprender'), findsNothing);
    });
  });

  group('HomeScreen', () {
    testWidgets('busca al confirmar y muestra las coincidencias', (
      tester,
    ) async {
      final marketData = FakeMarketData(matches: [tescoLondon]);
      await _pumpHome(tester, marketData);

      await tester.enterText(find.byType(TextField), 'tesco');
      await tester.pump();
      expect(marketData.searchQueries, isEmpty);

      await tester.tap(find.byTooltip('Buscar'));
      await tester.pumpAndSettle();

      expect(marketData.searchQueries, ['tesco']);
      expect(find.text('Tesco PLC'), findsOneWidget);
      expect(find.text('London Stock Exchange · GB · GBX'), findsOneWidget);
      expect(find.text('ISIN GB0008847096'), findsOneWidget);
    });

    testWidgets('también busca al pulsar intro (criterio 2)', (tester) async {
      final marketData = FakeMarketData(matches: [tescoLondon]);
      await _pumpHome(tester, marketData);

      await tester.enterText(find.byType(TextField), 'tesco');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(marketData.searchQueries, ['tesco']);
      expect(find.text('Tesco PLC'), findsOneWidget);
    });

    testWidgets('sin coincidencias lo indica', (tester) async {
      await _pumpHome(tester, FakeMarketData());

      await _search(tester, 'zzqx');

      expect(find.text('No se ha encontrado ninguna acción.'), findsOneWidget);
    });

    testWidgets('al elegir una coincidencia abre su análisis', (tester) async {
      await _pumpHome(tester, FakeMarketData(matches: [tescoLondon]));
      await _search(tester, 'tesco');

      await tester.tap(find.text('Tesco PLC'));
      await tester.pumpAndSettle();

      expect(find.text('Análisis de LSE:TSCO'), findsOneWidget);
    });

    testWidgets('muestra el historial y abre el análisis guardado', (
      tester,
    ) async {
      final entry = HistoryEntry(
        result: const StockAnalyzer().analyze(
          qualityCompany(),
          referenceDate: referenceDate,
        ),
        analyzedAt: referenceDate,
      );
      await _pumpHome(tester, FakeMarketData(), history: FakeHistory([entry]));

      expect(find.text('Calidad S.A.'), findsOneWidget);
      expect(find.text('Favorable'), findsOneWidget);

      await tester.tap(find.text('Calidad S.A.'));
      await tester.pumpAndSettle();

      expect(find.text('Análisis de CALI (historial)'), findsOneWidget);
    });

    testWidgets('con historial vacío lo indica', (tester) async {
      await _pumpHome(tester, FakeMarketData());

      expect(find.text('Aún no has analizado ninguna acción.'), findsOneWidget);
    });
  });
}
