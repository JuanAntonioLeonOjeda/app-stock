import 'package:stock_app/features/analisis_accion/domain/entities/daily_bar.dart';

/// Histórico diario de precios de una acción, independiente del proveedor.
abstract interface class PriceHistoryPort {
  /// Velas diarias de [symbol], de la más antigua a la más reciente.
  ///
  /// Con [forceRefresh] se ignoran los datos guardados y se vuelve a pedir.
  /// Lanza solo subtipos de `MarketDataException`.
  Future<List<DailyBar>> fetchPriceHistory(
    String symbol, {
    bool forceRefresh = false,
  });
}
