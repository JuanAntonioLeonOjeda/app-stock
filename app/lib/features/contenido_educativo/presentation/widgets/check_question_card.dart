import 'package:flutter/material.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/check_question.dart';

/// La pregunta de comprobación (criterio 5).
///
/// Al elegir una opción se ve si acierta y siempre la explicación; se puede
/// cambiar de opción. No se puntúa ni se guarda nada, y el tono nunca es
/// burlón.
class CheckQuestionCard extends StatelessWidget {
  const CheckQuestionCard({
    super.key,
    required this.question,
    required this.selectedIndex,
    required this.onSelect,
  });

  final CheckQuestion question;

  /// Opción elegida, o `null` si aún no se ha respondido.
  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = selectedIndex;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question.text, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            for (var i = 0; i < question.options.length; i++)
              _OptionTile(
                text: question.options[i],
                state: _stateOf(i, selected),
                onTap: () => onSelect(i),
              ),
            if (selected != null) ...[
              const SizedBox(height: 8),
              Text(
                selected == question.correctIndex
                    ? '¡Correcto!'
                    : 'No exactamente.',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(question.explanation, style: theme.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }

  _OptionState _stateOf(int index, int? selected) {
    if (selected == null) return _OptionState.unanswered;
    if (index == selected) {
      return index == question.correctIndex
          ? _OptionState.correct
          : _OptionState.incorrect;
    }
    return _OptionState.unanswered;
  }
}

enum _OptionState { unanswered, correct, incorrect }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.text,
    required this.state,
    required this.onTap,
  });

  final String text;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (icon, color) = switch (state) {
      _OptionState.unanswered => (Icons.radio_button_unchecked, colors.outline),
      _OptionState.correct => (Icons.check_circle, colors.primary),
      _OptionState.incorrect => (Icons.cancel_outlined, colors.error),
    };
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(text),
      onTap: onTap,
    );
  }
}
