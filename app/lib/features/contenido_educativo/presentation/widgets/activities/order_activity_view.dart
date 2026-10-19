import 'package:flutter/material.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/learning_activity.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/activities/activity_feedback.dart';

/// Ordenar empresas inventadas de menor a mayor valor de una métrica
/// (criterio 84), arrastrando.
class OrderActivityView extends StatelessWidget {
  const OrderActivityView({
    super.key,
    required this.activity,
    required this.order,
    required this.isChecked,
    required this.isCorrect,
    required this.onReorder,
    required this.onCheck,
    required this.onRetry,
  });

  final OrderActivity activity;

  /// Posiciones (en `activity.items`) en el orden mostrado.
  final List<int> order;
  final bool isChecked;
  final bool isCorrect;
  final void Function(int oldIndex, int newIndex) onReorder;
  final VoidCallback onCheck;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(activity.prompt, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 4),
        Text(
          'Arrastra desde el icono de la derecha: de menor a mayor.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorderItem: onReorder,
          children: [
            for (var position = 0; position < order.length; position++)
              _tile(position, activity.items[order[position]]),
          ],
        ),
        const SizedBox(height: 8),
        if (!isChecked)
          FilledButton(onPressed: onCheck, child: const Text('Comprobar'))
        else ...[
          ActivityFeedback(
            title: isCorrect ? '¡Bien ordenado!' : 'Casi: prueba otra vez.',
            text: activity.explanation,
            isPositive: isCorrect,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Repetir'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _tile(int position, OrderItem item) => Card(
    key: ValueKey(item.name),
    margin: const EdgeInsets.symmetric(vertical: 4),
    child: ListTile(
      leading: CircleAvatar(radius: 12, child: Text('${position + 1}')),
      title: Text(item.name),
      subtitle: isChecked ? Text(item.shown) : null,
      trailing: ReorderableDragStartListener(
        index: position,
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Icon(Icons.drag_handle, semanticLabel: 'Arrastrar'),
        ),
      ),
    ),
  );
}
