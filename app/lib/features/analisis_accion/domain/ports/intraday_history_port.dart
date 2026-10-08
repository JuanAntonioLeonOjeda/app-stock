import 'package:stock_app/features/analisis_accion/domain/chart/intraday_resolution.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/intraday_series.dart';

/// Velas intradía de una acción, independiente del proveedor.
abstract interface class IntradayHistoryPort {
  /// Velas recientes de [symbol] con la [resolution] pedida, de la más antigua
  /// a la más reciente.
  ///
  /// Con [forceRefresh] se ignoran los datos guardados y se vuelve a pedir.
  /// Lanza solo subtipos de `MarketDataException`.
  Future<IntradaySeries> fetchIntraday(
    String symbol,
    IntradayResolution resolution, {
    bool forceRefresh = false,
  });
}
