import 'package:flutter/material.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/labels.dart';

/// Veredicto como etiqueta de color.
class VerdictBadge extends StatelessWidget {
  const VerdictBadge({super.key, required this.verdict});

  final Verdict verdict;

  @override
  Widget build(BuildContext context) {
    final color = verdictColor(verdict, Theme.of(context).colorScheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        verdictLabel(verdict),
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Color de cada veredicto. Neutral y sin datos usan colores del tema para
/// no sugerir una opinión.
Color verdictColor(Verdict verdict, ColorScheme colors) => switch (verdict) {
  Verdict.favorable => Colors.green.shade700,
  Verdict.neutral => colors.primary,
  Verdict.unfavorable => colors.error,
  Verdict.insufficientData => colors.outline,
};
