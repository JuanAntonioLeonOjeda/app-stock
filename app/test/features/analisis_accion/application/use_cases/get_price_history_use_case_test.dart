import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/get_price_history_use_case.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';

import '../../domain/motor/synthetic_companies.dart';
import '../fake_ports.dart';

void main() {
  group('GetPriceHistoryUseCase', () {
    test('devuelve el histórico del port', () async {
      final bars = priceHistory(sessions: 30);
      final port = FakePriceHistory(bars: bars);

      final result = await GetPriceHistoryUseCase(port)('TSE:7974');

      expect(result, bars);
      expect(port.calls.single.symbol, 'TSE:7974');
      expect(port.calls.single.forceRefresh, isFalse);
    });

    test('reenvía forceRefresh', () async {
      final port = FakePriceHistory();

      await GetPriceHistoryUseCase(port)('TSE:7974', forceRefresh: true);

      expect(port.calls.single.forceRefresh, isTrue);
    });

    test('deja pasar el error del proveedor', () async {
      final port = FakePriceHistory(error: const NetworkException());

      await expectLater(
        GetPriceHistoryUseCase(port)('TSE:7974'),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
