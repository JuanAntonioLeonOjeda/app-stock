import 'package:flutter/material.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/symbol_match.dart';

/// Una coincidencia de la búsqueda: nombre, símbolo, región y divisa.
class SymbolMatchTile extends StatelessWidget {
  const SymbolMatchTile({super.key, required this.match, required this.onTap});

  final SymbolMatch match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(match.name),
    subtitle: Text('${match.symbol} · ${match.region} · ${match.currency}'),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}
