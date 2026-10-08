import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/load_history_use_case.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/search_symbol_use_case.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/history_entry.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/stock_analyzer.dart';
import 'package:stock_app/features/analisis_accion/presentation/controllers/home_controller.dart';

import '../../application/fake_ports.dart';
import '../../domain/motor/synthetic_companies.dart';
import '../../search_samples.dart';

HomeController _controller(FakeMarketData marketData, {FakeHistory? history}) =>
    HomeController(
      searchSymbol: SearchSymbolUseCase(marketData),
      loadHistory: LoadHistoryUseCase(history ?? FakeHistory()),
    );

void main() {
  group('HomeController.search', () {
    test('muestra las coincidencias encontradas', () async {
      final controller = _controller(FakeMarketData(matches: [tescoLondon]));

      await controller.search('tesco');

      expect(controller.companies, hasLength(1));
      expect(controller.companies!.single.defaultListing, tescoLondon);
      expect(controller.hasNoResults, isFalse);
      expect(controller.searchError, isNull);
    });

    test('antes de buscar no hay resultados ni mensaje de "sin '
        'resultados"', () {
      final controller = _controller(FakeMarketData());

      expect(controller.companies, isNull);
      expect(controller.hasNoResults, isFalse);
    });

    test('sin coincidencias indica que no hay resultados', () async {
      final controller = _controller(FakeMarketData());

      await controller.search('zzqx');

      expect(controller.hasNoResults, isTrue);
    });

    test('está buscando mientras la petición está en curso', () async {
      final marketData = FakeMarketData(matches: [tescoLondon])
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

    test('un texto vacío no busca ni cambia el estado', () async {
      final marketData = FakeMarketData();
      final controller = _controller(marketData);

      await controller.search('   ');

      expect(marketData.searchQueries, isEmpty);
      expect(controller.companies, isNull);
    });
  });

  group('HomeController.refreshHistory', () {
    test('carga el historial', () async {
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

  group('HomeController certificados ADR', () {
    HomeController withReceipts({bool onlyReceipts = false}) => _controller(
      FakeMarketData(
        matches: onlyReceipts
            ? [tescoReceipt]
            : [tescoLondon, tescoFrankfurt, tescoReceipt],
      ),
    );

    test('no se ven por defecto y se cuentan (criterio 75)', () async {
      final controller = withReceipts();

      await controller.search('tesco');

      expect(controller.companies!.map((c) => c.isDepositaryReceipt), [false]);
      expect(controller.receiptCount, 1);
      expect(controller.canToggleReceipts, isTrue);
      expect(controller.showReceipts, isFalse);
    });

    test('mostrarlos los añade al final', () async {
      final controller = withReceipts();
      await controller.search('tesco');

      controller.setShowReceipts(isVisible: true);

      expect(controller.companies!.map((c) => c.isDepositaryReceipt), [
        false,
        true,
      ]);
      expect(controller.showReceipts, isTrue);
    });

    test('se pueden volver a ocultar', () async {
      final controller = withReceipts();
      await controller.search('tesco');
      controller.setShowReceipts(isVisible: true);

      controller.setShowReceipts(isVisible: false);

      expect(controller.companies, hasLength(1));
    });

    test('una nueva búsqueda vuelve a ocultarlos', () async {
      final controller = withReceipts();
      await controller.search('tesco');
      controller.setShowReceipts(isVisible: true);

      await controller.search('tesco otra vez');

      expect(controller.showReceipts, isFalse);
    });

    test('si solo hay certificados, se muestran sin pedirlo', () async {
      final controller = withReceipts(onlyReceipts: true);

      await controller.search('tesco');

      expect(controller.companies, hasLength(1));
      expect(controller.companies!.single.isDepositaryReceipt, isTrue);
      expect(controller.canToggleReceipts, isFalse);
      expect(controller.hasNoResults, isFalse);
    });

    test('sin certificados no se ofrece el botón', () async {
      final controller = _controller(FakeMarketData(matches: [tescoLondon]));

      await controller.search('tesco');

      expect(controller.receiptCount, 0);
      expect(controller.canToggleReceipts, isFalse);
    });
  });
}
