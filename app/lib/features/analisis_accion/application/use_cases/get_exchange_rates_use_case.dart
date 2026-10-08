import 'package:stock_app/features/analisis_accion/domain/entities/exchange_rate_series.dart';
import 'package:stock_app/features/analisis_accion/domain/ports/exchange_rate_port.dart';

/// Obtiene los tipos de cambio diarios de una moneda frente al euro.
class GetExchangeRatesUseCase {
  const GetExchangeRatesUseCase(this._exchangeRates);

  final ExchangeRatePort _exchangeRates;

  /// Lanza `MarketDataException` si no se pueden obtener.
  Future<ExchangeRateSeries> call(
    String isoCode, {
    bool forceRefresh = false,
  }) => _exchangeRates.fetchRates(isoCode, forceRefresh: forceRefresh);
}
