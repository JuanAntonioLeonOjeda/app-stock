import 'package:flutter/material.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/history_entry.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/metric_value_formatter.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/verdict_badge.dart';

/// Últimos análisis: símbolo, nombre, veredicto y fecha (criterio 15).
class HistoryList extends StatelessWidget {
  const HistoryList({super.key, required this.entries, required this.onTap});

  final List<HistoryEntry> entries;
  final ValueChanged<HistoryEntry> onTap;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('Aún no has analizado ninguna acción.'),
      );
    }
    return Column(
      children: [
        for (final entry in entries)
          ListTile(
            title: Text(entry.result.name),
            subtitle: Text(
              '${entry.result.symbol} · ${formatDate(entry.analyzedAt)}',
            ),
            trailing: VerdictBadge(verdict: entry.result.verdict),
            onTap: () => onTap(entry),
          ),
      ],
    );
  }
}
