import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/load_history_use_case.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/search_symbol_use_case.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/history_entry.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/symbol_match.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/stock_analyzer.dart';
import 'package:stock_app/features/analisis_accion/presentation/controllers/home_controller.dart';

import '../../application/fake_ports.dart';
import '../../domain/motor/synthetic_companies.dart';

const _tesco = SymbolMatch(
  symbol: 'TSCO.LON',
  name: 'Tesco PLC',
  region: 'United Kingdom',
  currency: 'GBX',
  matchScore: 0.73,
);

HomeController _controller(
  FakeMarketData marketData, {
  FakeHistory? history,
  bool isApiKeyConfigured = true,
}) => HomeController(
  searchSymbol: SearchSymbolUseCase(marketData),
  loadHistory: LoadHistoryUseCase(history ?? FakeHistory()),
  isApiKeyConfigured: isApiKeyConfigured,
);

void main() {
  group('HomeController.search', () {
    test('muestra las coincidencias encontradas', () async {
      final controller = _controller(FakeMarketData(matches: [_tesco]));

      await controller.search('tesco');

      expect(controller.matches, [_tesco]);
      expect(controller.hasNoResults, isFalse);
      expect(controller.searchError, isNull);
    });

    test('antes de buscar no hay resultados ni mensaje de "sin '
        'resultados"', () {
      final controller = _controller(FakeMarketData());

      expect(controller.matches, isNull);
      expect(controller.hasNoResults, isFalse);
    });

    test('sin coincidencias indica que no hay resultados', () async {
      final controller = _controller(FakeMarketData());

      await controller.search('zzqx');

      expect(controller.hasNoResults, isTrue);
    });

    test('está buscando mientras la petición está en curso', () async {
      final marketData = FakeMarketData(matches: [_tesco])
        ..gate = Completer<void>();
      final controller = _controller(marketData);

      final search = controller.search('tesco');

      expect(controller.isSearching, isTrue);
      expect(controller.canSearch, isFalse);
      marketData.gate!.complete();
      await search;
      expect(controller.isSearching, isFalse);
    });

    test('un error se guarda para mostrarlo y termina la búsqueda', () async {
      final marketData = FakeMarketData()..error = const RateLimitException();
      final controller = _controller(marketData);

      await controller.search('tesco');

      expect(controller.searchError, isA<RateLimitException>());
      expect(controller.isSearching, isFalse);
    });

    test('sin clave no busca (criterio 27)', () async {
      final marketData = FakeMarketData(matches: [_tesco]);
      final controller = _controller(marketData, isApiKeyConfigured: false);

      await controller.search('tesco');

      expect(controller.canSearch, isFalse);
      expect(marketData.searchQueries, isEmpty);
    });

    test('un texto vacío no busca ni cambia el estado', () async {
      final marketData = FakeMarketData();
      final controller = _controller(marketData);

      await controller.search('   ');

      expect(marketData.searchQueries, isEmpty);
      expect(controller.matches, isNull);
    });
  });

  group('HomeController.refreshHistory', () {
    test('carga el historial, también sin clave', () async {
      final entry = HistoryEntry(
        result: const StockAnalyzer().analyze(
          qualityCompany(),
          referenceDate: referenceDate,
        ),
        analyzedAt: referenceDate,
      );
      final controller = _controller(
        FakeMarketData(),
        history: FakeHistory([entry]),
        isApiKeyConfigured: false,
      );
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.refreshHistory();

      expect(controller.history, [entry]);
      expect(notifications, 1);
    });
  });

  test(
    'no notifica después de dispose (búsqueda en curso al cerrar)',
    () async {
      final marketData = FakeMarketData()..gate = Completer<void>();
      final controller = _controller(marketData);
      final search = controller.search('tesco');

      controller.dispose();
      marketData.gate!.complete();

      await expectLater(search, completes);
    },
  );
}
