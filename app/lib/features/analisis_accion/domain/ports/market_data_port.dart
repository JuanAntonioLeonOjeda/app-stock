import 'package:stock_app/features/analisis_accion/domain/entities/fetch_step.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/stock_data.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/symbol_match.dart';

/// Acceso a datos de mercado, independiente del proveedor.
///
/// Todos los métodos lanzan solo subtipos de `MarketDataException`.
abstract interface class MarketDataPort {
  /// Coincidencias para un nombre o ticker, de más a menos relevante.
  /// Lista vacía si no hay ninguna.
  Future<List<SymbolMatch>> searchSymbol(String query);

  /// Todos los datos de [symbol], normalizados.
  ///
  /// Con [forceRefresh] se ignoran los datos guardados y se vuelve a pedir
  /// todo al proveedor. [onProgress] se llama al empezar cada paso, en el
  /// orden de `FetchStep.values`.
  Future<StockData> fetchStockData(
    String symbol, {
    bool forceRefresh = false,
    void Function(FetchStep step)? onProgress,
  });
}
