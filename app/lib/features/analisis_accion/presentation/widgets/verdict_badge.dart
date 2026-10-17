import 'package:flutter/material.dart';
import 'package:stock_app/core/theme/signal_colors.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/labels.dart';

/// Veredicto como etiqueta de color.
class VerdictBadge extends StatelessWidget {
  const VerdictBadge({super.key, required this.verdict});

  final Verdict verdict;

  @override
  Widget build(BuildContext context) {
    final color = verdictColor(verdict, Theme.of(context));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        verdictLabel(verdict),
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Color de cada veredicto, del semáforo del tema. Sin el tema de la app
/// (p. ej. en un test) usa la paleta clara.
Color verdictColor(Verdict verdict, ThemeData theme) {
  final colors = theme.extension<SignalColors>() ?? SignalColors.light;
  return switch (verdict) {
    Verdict.favorable => colors.favorable,
    Verdict.neutral => colors.neutral,
    Verdict.unfavorable => colors.unfavorable,
    Verdict.insufficientData => colors.unknown,
  };
}
