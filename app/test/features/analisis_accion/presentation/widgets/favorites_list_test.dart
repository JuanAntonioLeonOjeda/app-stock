import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/favorite.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/history_entry.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/stock_analyzer.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/favorites_list.dart';

import '../../domain/motor/synthetic_companies.dart';

AnalysisResult _result() => const StockAnalyzer().analyze(
  qualityCompany(),
  referenceDate: referenceDate,
);

Future<void> _pump(
  WidgetTester tester,
  List<Favorite> favorites, {
  List<HistoryEntry> history = const [],
  List<Favorite>? opened,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: FavoritesList(
          favorites: favorites,
          history: history,
          onOpen: (favorite) => opened?.add(favorite),
          onRemove: (_) {},
        ),
      ),
    ),
  ),
);

void main() {
  group('FavoritesList', () {
    testWidgets('sin favoritas explica cómo añadirlas', (tester) async {
      await _pump(tester, const []);

      expect(find.textContaining('Aún no tienes favoritas'), findsOneWidget);
    });

    testWidgets(
      'cada favorita es una tarjeta con nombre, símbolo e iniciales',
      (tester) async {
        await _pump(tester, const [
          Favorite(symbol: 'NASDAQ:AAPL', name: 'Apple Inc'),
        ]);

        expect(find.text('Apple Inc'), findsOneWidget);
        expect(find.text('NASDAQ:AAPL'), findsOneWidget);
        expect(find.text('AI'), findsOneWidget);
      },
    );

    testWidgets('con análisis guardado enseña veredicto y nota', (
      tester,
    ) async {
      final result = _result();
      final favorite = Favorite(symbol: result.symbol, name: result.name);
      await _pump(
        tester,
        [favorite],
        history: [HistoryEntry(result: result, analyzedAt: referenceDate)],
      );

      expect(find.textContaining('/ 10'), findsOneWidget);
    });

    testWidgets('sin análisis guardado no enseña veredicto', (tester) async {
      await _pump(tester, const [Favorite(symbol: 'X:Y', name: 'Sin datos')]);

      expect(find.textContaining('/ 10'), findsNothing);
    });

    testWidgets('pulsar la tarjeta abre la favorita', (tester) async {
      final opened = <Favorite>[];
      const favorite = Favorite(symbol: 'NASDAQ:AAPL', name: 'Apple Inc');
      await _pump(tester, const [favorite], opened: opened);

      await tester.tap(find.text('Apple Inc'));

      expect(opened, [favorite]);
    });
  });
}
