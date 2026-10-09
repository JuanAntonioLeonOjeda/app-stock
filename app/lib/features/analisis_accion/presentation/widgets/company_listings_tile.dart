import 'package:flutter/material.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/company_listings.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/symbol_match.dart';

/// Etiqueta de la cotización principal (criterio 72).
const primaryListingLabel = 'Principal';

/// Etiqueta de un certificado de depósito (criterio 75).
const depositaryReceiptLabel = 'ADR';

/// Una empresa de la búsqueda: su cotización principal marcada y, plegadas,
/// las demás (criterios 72-74). Pulsar la empresa analiza su cotización por
/// defecto; pulsar otra del desplegable, esa.
class CompanyListingsTile extends StatelessWidget {
  const CompanyListingsTile({
    super.key,
    required this.company,
    required this.onSelect,
  });

  final CompanyListings company;

  /// Se llama con el símbolo de la cotización elegida.
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final listing = company.defaultListing;
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(company.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (company.hasConfirmedPrimary)
                      const _Tag(primaryListingLabel),
                    if (company.isDepositaryReceipt)
                      const _Tag(depositaryReceiptLabel),
                    Text(_describe(listing)),
                  ],
                ),
                Text('ISIN ${company.isin}'),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onSelect(listing.symbol),
          ),
          if (company.others.isNotEmpty) _others(context),
        ],
      ),
    );
  }

  Widget _others(BuildContext context) => ExpansionTile(
    title: Text('Otras cotizaciones (${company.others.length})'),
    dense: true,
    children: [
      for (final other in company.others)
        ListTile(
          dense: true,
          title: Text(_describe(other)),
          subtitle: Text(other.symbol),
          onTap: () => onSelect(other.symbol),
        ),
    ],
  );

  /// "Tokyo Stock Exchange · JP · JPY".
  static String _describe(SymbolMatch match) {
    final place = match.exchangeName.isEmpty
        ? match.exchange
        : match.exchangeName;
    return [
      place,
      match.region,
      match.currency,
    ].where((part) => part.isNotEmpty).join(' · ');
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: colors.onPrimaryContainer),
        ),
      ),
    );
  }
}
