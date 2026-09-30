import 'package:flutter/material.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/labels.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/metric_value_formatter.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/verdict_badge.dart';

/// Cabecera del resultado (criterio 9): empresa, precio, veredicto, nota,
/// confianza, perfil y versión del motor.
class VerdictHeader extends StatelessWidget {
  const VerdictHeader({super.key, required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final lastClose = result.lastCloseDate;
    final score = result.globalScore;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.name, style: text.titleLarge),
            Text(result.symbol, style: text.bodyMedium),
            const SizedBox(height: 8),
            Text(
              [
                formatPrice(result.price, result.currency),
                if (lastClose != null) 'cierre del ${formatDate(lastClose)}',
              ].join(' · '),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                VerdictBadge(verdict: result.verdict),
                const Spacer(),
                if (score != null)
                  Text('${formatScore(score)} / 10', style: text.headlineSmall),
              ],
            ),
            const SizedBox(height: 12),
            Text('Confianza: ${confidenceLabel(result.confidence)}'),
            Text('Perfil: ${profileLabel(result.profile)}'),
            const SizedBox(height: 8),
            Text('Motor v${result.motorVersion}', style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}
