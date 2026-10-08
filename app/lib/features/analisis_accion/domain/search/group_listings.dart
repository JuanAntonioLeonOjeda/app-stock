// Agrupa las coincidencias de la búsqueda por empresa. Funciones puras: lo que
// se muestra en la lista (una fila por empresa, la principal marcada) es regla
// de presentación de resultados, no de ningún proveedor.

import 'package:stock_app/features/analisis_accion/domain/entities/company_listings.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/symbol_match.dart';

/// Divisa que se prefiere al ordenar "otras cotizaciones".
const _preferredCurrency = 'EUR';

/// Agrupa [matches] por ISIN (criterios 72-76 y 79 de la spec).
///
/// - Las coincidencias sin ISIN se descartan (instrumentos sintéticos).
/// - Dentro de cada empresa, la cotización principal va primera y el resto
///   quedan en `others`, con las de euros delante.
/// - Las empresas van por la relevancia de su mejor coincidencia, y los
///   certificados ADR, que tienen otro ISIN, al final.
List<CompanyListings> groupListings(List<SymbolMatch> matches) {
  final groups = <String, List<_Indexed>>{};
  for (var i = 0; i < matches.length; i++) {
    final isin = matches[i].isin;
    if (isin == null || isin.isEmpty) continue;
    groups.putIfAbsent(isin, () => []).add(_Indexed(i, matches[i]));
  }
  final companies = [
    for (final MapEntry(key: isin, value: members) in groups.entries)
      _company(isin, members),
  ];
  return _ordered(companies);
}

/// ISIN de las empresas (sin contar ADR) cuyas coincidencias no incluyen la
/// cotización principal, en orden de relevancia. Hay que completarlas con una
/// búsqueda por ISIN (criterio 77).
List<String> isinsMissingPrimary(List<SymbolMatch> matches) => [
  for (final company in groupListings(matches))
    if (!company.isDepositaryReceipt && !company.hasConfirmedPrimary)
      company.isin,
];

CompanyListings _company(String isin, List<_Indexed> members) {
  final byRelevance = [...members]..sort(_byRelevance);
  final primary = byRelevance
      .where((m) => m.match.isPrimaryListing)
      .firstOrNull;
  final defaultListing = (primary ?? byRelevance.first).match;
  final others = [
    for (final member in byRelevance)
      if (member.match != defaultListing) member,
  ]..sort(_euroFirst);
  return CompanyListings(
    isin: isin,
    defaultListing: defaultListing,
    hasConfirmedPrimary: primary != null,
    others: [for (final member in others) member.match],
    isDepositaryReceipt: members.every((m) => m.match.isDepositaryReceipt),
    relevance: byRelevance.first.match.matchScore,
  );
}

List<CompanyListings> _ordered(List<CompanyListings> companies) {
  int byRelevance(CompanyListings a, CompanyListings b) =>
      b.relevance.compareTo(a.relevance);
  final stocks = [
    for (final company in companies)
      if (!company.isDepositaryReceipt) company,
  ]..sort(byRelevance);
  final receipts = [
    for (final company in companies)
      if (company.isDepositaryReceipt) company,
  ]..sort(byRelevance);
  return [...stocks, ...receipts];
}

/// Mayor relevancia primero; con empate, el orden original del proveedor.
int _byRelevance(_Indexed a, _Indexed b) {
  final byScore = b.match.matchScore.compareTo(a.match.matchScore);
  return byScore != 0 ? byScore : a.index.compareTo(b.index);
}

/// Las que cotizan en euros primero; el resto conserva el orden de relevancia.
int _euroFirst(_Indexed a, _Indexed b) {
  final aIsEuro = a.match.currency == _preferredCurrency;
  final bIsEuro = b.match.currency == _preferredCurrency;
  if (aIsEuro != bIsEuro) return aIsEuro ? -1 : 1;
  return _byRelevance(a, b);
}

class _Indexed {
  const _Indexed(this.index, this.match);

  final int index;
  final SymbolMatch match;
}
