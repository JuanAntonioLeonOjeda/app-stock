import 'package:stock_app/features/analisis_accion/domain/entities/symbol_match.dart';
import 'package:stock_app/features/analisis_accion/domain/ports/market_data_port.dart';

/// Longitud máxima del texto buscado: ningún nombre o ticker la necesita, y
/// evita claves de caché desmesuradas.
const maxSearchQueryLength = 60;

/// Busca acciones por nombre o ticker (spec, criterios 1-4).
class SearchSymbolUseCase {
  const SearchSymbolUseCase(this._marketData);

  final MarketDataPort _marketData;

  /// Coincidencias para [query], de más a menos relevante. Un texto vacío no
  /// hace ninguna petición y devuelve una lista vacía.
  ///
  /// Lanza los `MarketDataException` del port.
  Future<List<SymbolMatch>> call(String query) async {
    final text = query.trim();
    if (text.isEmpty) return const [];
    final bounded = text.length > maxSearchQueryLength
        ? text.substring(0, maxSearchQueryLength)
        : text;
    return _marketData.searchSymbol(bounded);
  }
}
