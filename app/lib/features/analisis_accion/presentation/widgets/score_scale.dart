import 'package:flutter/material.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/metric_value_formatter.dart';

/// La nota de 0 a 10 como diez tramos, rellenos hasta donde llega. Es lo
/// único que no cambia de forma entre acciones: se lee de un vistazo sin
/// depender del color (el número va siempre al lado).
class ScoreScale extends StatelessWidget {
  const ScoreScale({super.key, required this.score, required this.color});

  final double score;
  final Color color;

  static const _segments = 10;

  @override
  Widget build(BuildContext context) {
    final track = Theme.of(context).colorScheme.outlineVariant;
    return Semantics(
      label: 'Nota ${formatScore(score)} de 10',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < _segments; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Expanded(child: _segment(i, track)),
          ],
        ],
      ),
    );
  }

  Widget _segment(int index, Color track) {
    final fill = (score - index).clamp(0.0, 1.0);
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(3),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: fill,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}
