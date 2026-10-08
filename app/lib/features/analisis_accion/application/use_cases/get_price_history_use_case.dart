import 'package:stock_app/features/analisis_accion/domain/entities/daily_bar.dart';
import 'package:stock_app/features/analisis_accion/domain/ports/price_history_port.dart';

/// Obtiene el histórico diario de precios para la gráfica del resumen.
class GetPriceHistoryUseCase {
  const GetPriceHistoryUseCase(this._priceHistory);

  final PriceHistoryPort _priceHistory;

  /// Velas ascendentes. Lanza `MarketDataException` si no se puede obtener.
  Future<List<DailyBar>> call(String symbol, {bool forceRefresh = false}) =>
      _priceHistory.fetchPriceHistory(symbol, forceRefresh: forceRefresh);
}
