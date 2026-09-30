import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/analyze_stock_use_case.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/fetch_step.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';

import '../../domain/motor/synthetic_companies.dart';
import '../fake_ports.dart';

AnalyzeStockUseCase _useCase(
  FakeMarketData marketData,
  FakeHistory history, {
  DateTime? now,
}) => AnalyzeStockUseCase(
  marketData: marketData,
  history: history,
  now: () => now ?? referenceDate,
);

void main() {
  group('AnalyzeStockUseCase', () {
    test('analiza los datos obtenidos y devuelve la entrada', () async {
      final marketData = FakeMarketData(stockData: qualityCompany());

      final entry = await _useCase(marketData, FakeHistory())('CALI');

      expect(entry.result.symbol, 'CALI');
      expect(entry.result.verdict, Verdict.favorable);
      expect(entry.analyzedAt, referenceDate);
    });

    test('guarda la entrada en el historial', () async {
      final history = FakeHistory();

      final entry = await _useCase(
        FakeMarketData(stockData: qualityCompany()),
        history,
      )('CALI');

      expect(history.entries, [entry]);
    });

    test('usa el reloj inyectado como fecha de referencia del motor', () async {
      final muchLater = referenceDate.add(const Duration(days: 30));

      final entry = await _useCase(
        FakeMarketData(stockData: qualityCompany()),
        FakeHistory(),
        now: muchLater,
      )('CALI');

      // Con 30 días de antigüedad en los precios, la confianza es baja.
      expect(entry.result.confidence, Confidence.low);
      expect(entry.analyzedAt, muchLater);
    });

    test('pasa el símbolo y forceRefresh al proveedor', () async {
      final marketData = FakeMarketData(stockData: qualityCompany());

      await _useCase(marketData, FakeHistory())('CALI', forceRefresh: true);

      expect(marketData.fetchCalls, [(symbol: 'CALI', forceRefresh: true)]);
    });

    test('reenvía el progreso de la obtención de datos', () async {
      final steps = <FetchStep>[];

      await _useCase(
        FakeMarketData(stockData: qualityCompany()),
        FakeHistory(),
      )('CALI', onProgress: steps.add);

      expect(steps, FetchStep.values);
    });

    test('si la obtención falla, propaga el error y no guarda nada', () async {
      final marketData = FakeMarketData()..error = const NetworkException();
      final history = FakeHistory();

      await expectLater(
        _useCase(marketData, history)('CALI'),
        throwsA(isA<NetworkException>()),
      );
      expect(history.saveCount, 0);
    });
  });
}
