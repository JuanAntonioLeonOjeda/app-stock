import 'package:flutter/material.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/fetch_step.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/labels.dart';

/// Progreso del análisis: "Obteniendo balance, 3 de 6" (criterio 5).
class AnalysisProgress extends StatelessWidget {
  const AnalysisProgress({super.key, required this.step});

  /// Paso en curso; `null` antes del primero.
  final FetchStep? step;

  @override
  Widget build(BuildContext context) {
    final currentStep = step;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LinearProgressIndicator(),
          const SizedBox(height: 12),
          Text(
            currentStep == null
                ? 'Preparando el análisis…'
                : fetchProgressLabel(currentStep),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
