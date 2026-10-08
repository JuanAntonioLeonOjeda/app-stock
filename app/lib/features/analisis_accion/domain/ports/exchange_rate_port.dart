import 'package:stock_app/features/analisis_accion/domain/entities/exchange_rate_series.dart';

/// Tipos de cambio frente al euro, independientes del proveedor.
abstract interface class ExchangeRatePort {
  /// Los tipos de cambio diarios de [isoCode] (`JPY`, `USD`...) frente al euro,
  /// del más antiguo al más reciente.
  ///
  /// Con [forceRefresh] se ignoran los datos guardados y se vuelven a pedir.
  /// Lanza solo subtipos de `MarketDataException`; `NotFoundException` si no
  /// hay tipo para esa moneda.
  Future<ExchangeRateSeries> fetchRates(
    String isoCode, {
    bool forceRefresh = false,
  });
}
