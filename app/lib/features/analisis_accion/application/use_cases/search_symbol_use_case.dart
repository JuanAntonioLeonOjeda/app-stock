import 'package:stock_app/features/analisis_accion/domain/entities/company_listings.dart';
import 'package:stock_app/features/analisis_accion/domain/ports/market_data_port.dart';
import 'package:stock_app/features/analisis_accion/domain/search/group_listings.dart';

/// Longitud máxima del texto buscado: ningún nombre o ticker la necesita, y
/// evita claves de caché desmesuradas.
const maxSearchQueryLength = 60;

/// Busca empresas por nombre, ticker o ISIN y las agrupa por ISIN, con su
/// cotización principal marcada (spec, criterios 72-79).
class SearchSymbolUseCase {
  const SearchSymbolUseCase(this._marketData);

  final MarketDataPort _marketData;

  /// Empresas que coinciden con [query], de más a menos relevante, y los
  /// certificados ADR al final. Un texto vacío no hace ninguna petición y
  /// devuelve una lista vacía.
  ///
  /// Lanza los `MarketDataException` del port.
  Future<List<CompanyListings>> call(String query) async {
    final text = query.trim();
    if (text.isEmpty) return const [];
    final bounded = text.length > maxSearchQueryLength
        ? text.substring(0, maxSearchQueryLength)
        : text;
    return groupListings(await _marketData.searchSymbol(bounded));
  }
}
