// Agrupa las coincidencias de la búsqueda por empresa. Funciones puras: lo que
// se muestra en la lista (una fila por empresa, la principal marcada) es regla
// de presentación de resultados, no de ningún proveedor.
//
// La relevancia es el ORDEN de la lista de entrada: el puesto en que aparece
// cada coincidencia. No se usa ninguna puntuación, porque las de dos
// búsquedas distintas (por nombre y por ISIN) no son comparables entre sí.

import 'package:stock_app/features/analisis_accion/domain/entities/company_listings.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/symbol_match.dart';

/// Divisa que se prefiere al ordenar "otras cotizaciones".
const _preferredCurrency = 'EUR';

/// Agrupa [matches], ya ordenadas por relevancia, por ISIN (criterios 72-76 y
/// 79 de la spec).
///
/// - Las coincidencias sin ISIN se descartan (instrumentos sintéticos).
/// - Dentro de cada empresa, la cotización principal va primera y el resto
///   quedan en `others`, con las de euros delante.
/// - Las empresas van en el orden en que aparece su primera coincidencia, y
///   los certificados ADR, que tienen otro ISIN, al final.
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
  return [
    for (final company in companies)
      if (!company.isDepositaryReceipt) company,
    for (final company in companies)
      if (company.isDepositaryReceipt) company,
  ];
}

/// ISIN de las empresas (sin contar ADR) cuyas coincidencias no incluyen la
/// cotización principal, en orden de relevancia. Hay que completarlas con una
/// búsqueda por ISIN (criterio 77).
List<String> isinsMissingPrimary(List<SymbolMatch> matches) => [
  for (final company in groupListings(matches))
    if (!company.isDepositaryReceipt && !company.hasConfirmedPrimary)
      company.isin,
];

/// Los miembros llegan en orden de aparición, así que el primero es el más
/// relevante y los puestos no se repiten entre empresas: sin empates.
CompanyListings _company(String isin, List<_Indexed> members) {
  final isReceipt = members.every((m) => m.match.isDepositaryReceipt);
  // Un certificado nunca es "la cotización principal" de una acción.
  final primary = isReceipt
      ? null
      : members.where((m) => m.match.isPrimaryListing).firstOrNull;
  final defaultMember = primary ?? members.first;
  final others = [
    for (final member in members)
      if (member != defaultMember) member,
  ]..sort(_euroFirst);
  return CompanyListings(
    isin: isin,
    defaultListing: defaultMember.match,
    hasConfirmedPrimary: primary != null,
    others: [for (final member in others) member.match],
    isDepositaryReceipt: isReceipt,
    rank: members.first.index,
  );
}

/// Las que cotizan en euros primero; el resto, por orden de aparición. Los
/// puestos son únicos, así que el orden es total.
int _euroFirst(_Indexed a, _Indexed b) {
  final aIsEuro = a.match.currency == _preferredCurrency;
  final bIsEuro = b.match.currency == _preferredCurrency;
  if (aIsEuro != bIsEuro) return aIsEuro ? -1 : 1;
  return a.index.compareTo(b.index);
}

class _Indexed {
  const _Indexed(this.index, this.match);

  final int index;
  final SymbolMatch match;
}
