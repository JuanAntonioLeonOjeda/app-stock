import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/get_intraday_history_use_case.dart';
import 'package:stock_app/features/analisis_accion/domain/chart/intraday_resolution.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/intraday_bar.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/intraday_series.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';

import '../fake_ports.dart';

void main() {
  final series = IntradaySeries(
    bars: [IntradayBar(time: DateTime.utc(2026, 10, 8, 7), close: 21)],
    timezone: 'Europe/Madrid',
    delay: const Duration(minutes: 15),
  );

  group('GetIntradayHistoryUseCase', () {
    test('devuelve la serie del port para la resolución pedida', () async {
      final port = FakeIntradayHistory(
        byResolution: {IntradayResolution.minutes5: series},
      );

      final result = await GetIntradayHistoryUseCase(port)(
        'BME:IBE',
        IntradayResolution.minutes5,
      );

      expect(result, same(series));
      expect(port.calls.single.symbol, 'BME:IBE');
      expect(port.calls.single.resolution, IntradayResolution.minutes5);
      expect(port.calls.single.forceRefresh, isFalse);
    });

    test('reenvía forceRefresh', () async {
      final port = FakeIntradayHistory();

      await GetIntradayHistoryUseCase(port)(
        'BME:IBE',
        IntradayResolution.minutes30,
        forceRefresh: true,
      );

      expect(port.calls.single.forceRefresh, isTrue);
    });

    test('deja pasar el error del proveedor', () async {
      final port = FakeIntradayHistory(error: const NetworkException());

      await expectLater(
        GetIntradayHistoryUseCase(port)('BME:IBE', IntradayResolution.minutes5),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
