import 'package:flutter/material.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/learning_activity.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/activities/activity_feedback.dart';

/// Pulsar el dato que engaña de una empresa inventada (criterio 82). Se
/// puede seguir probando: cada dato pulsado explica por qué lo es o no.
class SpotTrapActivityView extends StatelessWidget {
  const SpotTrapActivityView({
    super.key,
    required this.activity,
    required this.tapped,
    required this.onTap,
  });

  final SpotTrapActivity activity;

  /// Posiciones de los datos ya pulsados.
  final Set<int> tapped;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = activity.items;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(activity.company, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(activity.prompt, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 8),
        for (var i = 0; i < items.length; i++) ...[
          _ItemTile(
            item: items[i],
            isTapped: tapped.contains(i),
            onTap: () => onTap(i),
          ),
          if (tapped.contains(i))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ActivityFeedback(
                title: items[i].isTrap
                    ? '¡Ahí está la trampa!'
                    : 'Este dato no es la trampa',
                text: items[i].explanation,
                isPositive: items[i].isTrap,
              ),
            ),
        ],
      ],
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.item,
    required this.isTapped,
    required this.onTap,
  });

  final TrapItem item;
  final bool isTapped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(vertical: 4),
    child: ListTile(
      title: Text(item.label),
      // Debajo y no en `trailing`: hay valores de más de 40 caracteres y un
      // `trailing` sin límite de ancho deja al título casi sin sitio, con el
      // texto partido letra a letra.
      subtitle: Text(
        item.value,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      leading: Icon(
        isTapped ? Icons.touch_app : Icons.touch_app_outlined,
        semanticLabel: isTapped ? 'Ya probado' : 'Pulsar para probar',
      ),
      onTap: onTap,
    ),
  );
}
