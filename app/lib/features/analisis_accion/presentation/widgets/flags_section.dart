import 'package:flutter/material.dart';

/// Avisos del análisis. No ocupa espacio si no hay ninguno.
class FlagsSection extends StatelessWidget {
  const FlagsSection({super.key, required this.flags});

  final List<String> flags;

  @override
  Widget build(BuildContext context) {
    if (flags.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Avisos', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final flag in flags)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(flag)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
