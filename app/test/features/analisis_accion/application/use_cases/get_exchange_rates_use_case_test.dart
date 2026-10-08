import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/get_exchange_rates_use_case.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/exchange_rate_series.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';

import '../fake_ports.dart';

void main() {
  final yen = ExchangeRateSeries(
    currency: 'JPY',
    points: [RatePoint(DateTime.utc(2026, 10, 8), 177.05)],
  );

  group('GetExchangeRatesUseCase', () {
    test('devuelve la serie de la moneda pedida', () async {
      final port = FakeExchangeRates(byCurrency: {'JPY': yen});

      final series = await GetExchangeRatesUseCase(port)('JPY');

      expect(series, same(yen));
      expect(port.calls.single.currency, 'JPY');
      expect(port.calls.single.forceRefresh, isFalse);
    });

    test('reenvía forceRefresh', () async {
      final port = FakeExchangeRates(byCurrency: {'JPY': yen});

      await GetExchangeRatesUseCase(port)('JPY', forceRefresh: true);

      expect(port.calls.single.forceRefresh, isTrue);
    });

    test('una moneda sin tipo es NotFound', () async {
      await expectLater(
        GetExchangeRatesUseCase(FakeExchangeRates())('SAR'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('deja pasar el error del proveedor', () async {
      final port = FakeExchangeRates(error: const NetworkException());

      await expectLater(
        GetExchangeRatesUseCase(port)('JPY'),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
