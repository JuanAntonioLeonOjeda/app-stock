import 'package:flutter/material.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/history_entry.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/history_list.dart';

/// "Últimas consultas": sección desplegable (cerrada al empezar) con el
/// historial y un botón para vaciarlo.
class RecentQueriesSection extends StatelessWidget {
  const RecentQueriesSection({
    super.key,
    required this.entries,
    required this.onTap,
    required this.onClear,
  });

  final List<HistoryEntry> entries;
  final ValueChanged<HistoryEntry> onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      title: Text(
        'Últimas consultas',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(entries.isEmpty ? 'Vacío' : '${entries.length}'),
      children: [
        HistoryList(entries: entries, onTap: onTap),
        if (entries.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 8),
              child: TextButton.icon(
                icon: const Icon(Icons.delete_outline),
                label: const Text('Limpiar lista'),
                onPressed: () => _confirmClear(context),
              ),
            ),
          ),
      ],
    ),
  );

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Limpiar las últimas consultas?'),
        content: const Text('Se borra la lista. Tus favoritas no se tocan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) onClear();
  }
}
