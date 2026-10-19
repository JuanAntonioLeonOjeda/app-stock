import 'package:flutter/material.dart';
import 'package:stock_app/features/contenido_educativo/domain/content/formula_evaluation.dart';
import 'package:stock_app/features/contenido_educativo/domain/content/scale_bands.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/formula_diagram.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/learning_activity.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/reading_scale.dart';
import 'package:stock_app/features/contenido_educativo/presentation/scale_formatting.dart';
import 'package:stock_app/features/contenido_educativo/presentation/tone_style.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/formula_diagram_view.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/scale_bar.dart';

/// Mover las piezas de la fórmula y ver dónde cae el resultado (criterio 81).
///
/// No da nota ni veredicto: solo dice en qué tramo de la escala cae.
class SimulatorActivityView extends StatelessWidget {
  const SimulatorActivityView({
    super.key,
    required this.activity,
    required this.diagram,
    required this.scale,
    required this.values,
    required this.onChanged,
    required this.onReset,
  });

  final SimulatorActivity activity;
  final FormulaDiagram diagram;
  final ReadingScale? scale;

  /// Valores puestos por el usuario, por `key` de pieza.
  final Map<String, double> values;
  final void Function(String key, double value) onChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = evaluateFormula(diagram, values);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(activity.prompt, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 12),
        for (final piece in diagram.pieces.where((p) => p.isAdjustable))
          _PieceSlider(
            piece: piece,
            value: values[piece.key] ?? piece.exampleValue,
            onChanged: (value) => onChanged(piece.key, value),
          ),
        const SizedBox(height: 12),
        FormulaDiagramView(diagram: diagram, values: values),
        const SizedBox(height: 12),
        if (scale case final scale? when result != null) ...[
          ScaleBar(scale: scale, markerValue: result),
          _ToneCaption(tone: toneAt(scale, result)),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.restart_alt),
            label: const Text('Volver al ejemplo'),
          ),
        ),
      ],
    );
  }
}

class _PieceSlider extends StatelessWidget {
  const _PieceSlider({
    required this.piece,
    required this.value,
    required this.onChanged,
  });

  final FormulaPiece piece;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final min = piece.min!;
    final max = piece.max!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${piece.name}: ${formatPieceValue(value, piece.unit)}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: 100,
          label: formatPieceValue(value, piece.unit),
          semanticFormatterCallback: (v) => formatPieceValue(v, piece.unit),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ToneCaption extends StatelessWidget {
  const _ToneCaption({required this.tone});

  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(toneIcon(tone), size: 18, color: toneColor(context, tone)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${toneLabel(tone)} según el motor. Es una orientación: '
              'depende del sector.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
