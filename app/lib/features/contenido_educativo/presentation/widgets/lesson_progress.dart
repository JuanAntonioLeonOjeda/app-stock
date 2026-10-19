import 'package:flutter/material.dart';

/// Indicador de en qué paso del recorrido estás (criterio 72). Cada punto se
/// puede pulsar para saltar a ese paso sin pasar por los anteriores
/// (criterio 73).
class LessonProgress extends StatelessWidget {
  const LessonProgress({
    super.key,
    required this.labels,
    required this.current,
    required this.onSelect,
  });

  final List<String> labels;
  final int current;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < labels.length; i++)
              Semantics(
                button: true,
                selected: i == current,
                label: 'Paso ${i + 1} de ${labels.length}: ${labels[i]}',
                child: InkWell(
                  onTap: () => onSelect(i),
                  customBorder: const CircleBorder(),
                  child: Padding(
                    // Área de pulsación de 48 dp alrededor del punto.
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 18,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: i == current ? 24 : 10,
                      height: 10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: i == current
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        Text(
          'Paso ${current + 1} de ${labels.length} · ${labels[current]}',
          style: theme.textTheme.labelLarge,
        ),
      ],
    );
  }
}
