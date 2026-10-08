import 'package:stock_app/features/analisis_accion/domain/chart/intraday_resolution.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/intraday_series.dart';
import 'package:stock_app/features/analisis_accion/domain/ports/intraday_history_port.dart';

/// Obtiene las velas del día o de la semana para la gráfica del resumen.
class GetIntradayHistoryUseCase {
  const GetIntradayHistoryUseCase(this._intradayHistory);

  final IntradayHistoryPort _intradayHistory;

  /// Lanza `MarketDataException` si no se pueden obtener.
  Future<IntradaySeries> call(
    String symbol,
    IntradayResolution resolution, {
    bool forceRefresh = false,
  }) => _intradayHistory.fetchIntraday(
    symbol,
    resolution,
    forceRefresh: forceRefresh,
  );
}
