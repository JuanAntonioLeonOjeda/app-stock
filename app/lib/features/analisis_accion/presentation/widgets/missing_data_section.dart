import 'package:flutter/material.dart';

/// "Datos que faltan" (criterio 13). No ocupa espacio si no falta ninguno.
class MissingDataSection extends StatelessWidget {
  const MissingDataSection({super.key, required this.missingData});

  final List<String> missingData;

  @override
  Widget build(BuildContext context) {
    if (missingData.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Datos que faltan',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final label in missingData) Text('• $label'),
          ],
        ),
      ),
    );
  }
}
