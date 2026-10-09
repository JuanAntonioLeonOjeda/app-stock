import 'package:stock_app/features/analisis_accion/domain/entities/symbol_match.dart';

/// Una empresa con todas sus cotizaciones encontradas, agrupadas por ISIN.
class CompanyListings {
  CompanyListings({
    required this.isin,
    required this.defaultListing,
    required this.hasConfirmedPrimary,
    required List<SymbolMatch> others,
    required this.isDepositaryReceipt,
    required this.rank,
  }) : others = List.unmodifiable(others);

  final String isin;

  /// La cotización que se analiza al pulsar la empresa: la principal si el
  /// proveedor la marcó y, si no, la mejor coincidencia.
  final SymbolMatch defaultListing;

  /// El proveedor marcó [defaultListing] como la principal. Solo entonces se
  /// etiqueta "Principal".
  final bool hasConfirmedPrimary;

  /// El resto de cotizaciones: primero las que cotizan en euros y, después,
  /// por relevancia.
  final List<SymbolMatch> others;

  /// Son certificados (ADR/DR) y no la acción ordinaria.
  final bool isDepositaryReceipt;

  /// Puesto de su primera coincidencia en los resultados (0 = la más
  /// relevante). No se repite entre empresas.
  final int rank;

  String get name => defaultListing.name;

  String get region => defaultListing.region;
}
