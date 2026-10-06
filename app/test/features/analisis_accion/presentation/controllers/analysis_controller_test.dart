import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/analyze_stock_use_case.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/open_news_use_case.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/fetch_step.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/history_entry.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/stock_analyzer.dart';
import 'package:stock_app/features/analisis_accion/presentation/controllers/analysis_controller.dart';

import '../../application/fake_ports.dart';
import '../../domain/motor/synthetic_companies.dart';

HistoryEntry _savedEntry({DateTime? analyzedAt}) => HistoryEntry(
  result: const StockAnalyzer().analyze(
    fragileCompany(),
    referenceDate: referenceDate,
  ),
  analyzedAt: analyzedAt ?? referenceDate,
);

AnalysisController _controller(
  FakeMarketData marketData, {
  HistoryEntry? initialEntry,
  DateTime? now,
  FakeLinkOpener? linkOpener,
}) => AnalysisController(
  openNews: OpenNewsUseCase(linkOpener ?? FakeLinkOpener()),
  analyzeStock: AnalyzeStockUseCase(
    marketData: marketData,
    history: FakeHistory(),
    now: () => referenceDate,
  ),
  symbol: 'CALI',
  initialEntry: initialEntry,
  now: () => now ?? referenceDate,
);

void main() {
  group('AnalysisController.openNews', () {
    test('abre las noticias de la empresa analizada', () async {
      final linkOpener = FakeLinkOpener();
      final controller = _controller(
        FakeMarketData(),
        initialEntry: _savedEntry(),
        linkOpener: linkOpener,
      );

      final wasOpened = await controller.openNews();

      expect(wasOpened, isTrue);
      expect(linkOpener.opened, hasLength(1));
      expect(linkOpener.opened.single.queryParameters['tbm'], 'nws');
    });

    test('devuelve false si el dispositivo no puede abrir el enlace', () async {
      final controller = _controller(
        FakeMarketData(),
        initialEntry: _savedEntry(),
        linkOpener: FakeLinkOpener(canOpen: false),
      );

      expect(await controller.openNews(), isFalse);
    });

    test('sin resultado todavía no abre nada', () async {
      final linkOpener = FakeLinkOpener();
      final controller = _controller(FakeMarketData(), linkOpener: linkOpener);

      expect(await controller.openNews(), isFalse);
      expect(linkOpener.opened, isEmpty);
    });
  });

  group('AnalysisController.analyze', () {
    test('muestra el resultado al terminar', () async {
      final controller = _controller(
        FakeMarketData(stockData: qualityCompany()),
      );

      await controller.analyze();

      expect(controller.entry?.result.symbol, 'CALI');
      expect(controller.isLoading, isFalse);
      expect(controller.error, isNull);
    });

    test('mientras analiza informa del paso en curso', () async {
      final marketData = FakeMarketData(stockData: qualityCompany())
        ..gate = Completer<void>();
      final controller = _controller(marketData);

      final analysis = controller.analyze();

      expect(controller.isLoading, isTrue);
      expect(controller.currentStep, FetchStep.fetching);
      expect(controller.canRefresh, isFalse);
      marketData.gate!.complete();
      await analysis;
      expect(controller.currentStep, isNull);
    });

    test('ignora una segunda petición mientras hay una en curso', () async {
      final marketData = FakeMarketData(stockData: qualityCompany())
        ..gate = Completer<void>();
      final controller = _controller(marketData);

      final first = controller.analyze();
      await controller.analyze();
      marketData.gate!.complete();
      await first;

      expect(marketData.fetchCalls, hasLength(1));
    });

    test('un error sin resultado previo se guarda para mostrarlo', () async {
      final marketData = FakeMarketData()..error = const NotFoundException();
      final controller = _controller(marketData);

      await controller.analyze();

      expect(controller.entry, isNull);
      expect(controller.error, isA<NotFoundException>());
    });
  });

  group('AnalysisController.refresh', () {
    test('vuelve a pedir los datos ignorando la caché', () async {
      final marketData = FakeMarketData(stockData: qualityCompany());
      final controller = _controller(marketData, initialEntry: _savedEntry());

      await controller.refresh();

      expect(marketData.fetchCalls.single.forceRefresh, isTrue);
      expect(controller.entry?.result.symbol, 'CALI');
    });

    test('si falla, conserva el resultado anterior junto al error '
        '(criterio 21)', () async {
      final saved = _savedEntry();
      final marketData = FakeMarketData()..error = const RateLimitException();
      final controller = _controller(marketData, initialEntry: saved);

      await controller.refresh();

      expect(controller.entry, same(saved));
      expect(controller.error, isA<RateLimitException>());
    });

    test('reintentar repite el último intento (forzado)', () async {
      final marketData = FakeMarketData(stockData: qualityCompany())
        ..error = const NetworkException();
      final controller = _controller(marketData, initialEntry: _savedEntry());
      await controller.refresh();
      marketData.error = null;

      await controller.retry();

      expect(marketData.fetchCalls.map((c) => c.forceRefresh), [true, true]);
      expect(controller.error, isNull);
    });
  });

  group('AnalysisController: resultado guardado', () {
    test('desde el historial muestra el resultado sin pedir datos', () {
      final saved = _savedEntry();
      final marketData = FakeMarketData();

      final controller = _controller(marketData, initialEntry: saved);

      expect(controller.entry, same(saved));
      expect(marketData.fetchCalls, isEmpty);
    });

    test('con más de 6 horas está caducado y sabe su antigüedad', () {
      final controller = _controller(
        FakeMarketData(),
        initialEntry: _savedEntry(),
        now: referenceDate.add(const Duration(hours: 7)),
      );

      expect(controller.isStale, isTrue);
      expect(controller.age, const Duration(hours: 7));
    });

    test('con menos de 6 horas no está caducado', () {
      final controller = _controller(
        FakeMarketData(),
        initialEntry: _savedEntry(),
        now: referenceDate.add(const Duration(hours: 2)),
      );

      expect(controller.isStale, isFalse);
    });
  });
}
