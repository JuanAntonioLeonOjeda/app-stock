import 'package:stock_app/features/analisis_accion/domain/entities/exchange_rate_series.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';
import 'package:stock_app/features/analisis_accion/domain/ports/exchange_rate_port.dart';

/// [ExchangeRatePort] que prueba un respaldo cuando el principal falla
/// (criterio 93).
///
/// El respaldo solo entra por un fallo de red, de límite o de formato. Si el
/// principal dice que la moneda no existe (`NotFoundException`) no se pregunta
/// al respaldo, que tiene menos monedas y tardaría lo mismo en decir lo mismo.
/// Y si el respaldo no tiene la moneda, el error que se devuelve es el del
/// principal, que es el problema real.
class FallbackExchangeRateAdapter implements ExchangeRatePort {
  FallbackExchangeRateAdapter({
    required this._primary,
    required this._secondary,
  });

  final ExchangeRatePort _primary;
  final ExchangeRatePort _secondary;

  @override
  Future<ExchangeRateSeries> fetchRates(
    String isoCode, {
    bool forceRefresh = false,
  }) async {
    try {
      return await _primary.fetchRates(isoCode, forceRefresh: forceRefresh);
    } on NotFoundException {
      rethrow;
    } on MarketDataException catch (primaryError) {
      try {
        return await _secondary.fetchRates(isoCode, forceRefresh: forceRefresh);
      } on NotFoundException {
        throw primaryError;
      }
    }
  }
}
