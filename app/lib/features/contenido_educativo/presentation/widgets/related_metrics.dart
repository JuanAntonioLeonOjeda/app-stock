import 'package:flutter/material.dart';

/// "Con qué se combina": una etiqueta por métrica relacionada; al pulsarla
/// se abre su ficha (criterio 3).
class RelatedMetrics extends StatelessWidget {
  const RelatedMetrics({
    super.key,
    required this.titlesById,
    required this.onOpen,
  });

  /// Título de cada métrica relacionada, por id.
  final Map<String, String> titlesById;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 4,
    children: [
      for (final MapEntry(key: id, value: title) in titlesById.entries)
        ActionChip(label: Text(title), onPressed: () => onOpen(id)),
    ],
  );
}
