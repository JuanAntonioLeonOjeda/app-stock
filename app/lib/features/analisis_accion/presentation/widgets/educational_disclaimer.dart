import 'package:flutter/material.dart';

/// Texto literal de la spec, criterio 14.
const educationalDisclaimerText =
    'Análisis con fin educativo. No es una recomendación de inversión.';

/// Aviso de que el análisis es educativo, siempre visible en el resultado.
class EducationalDisclaimer extends StatelessWidget {
  const EducationalDisclaimer({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Row(
      children: [
        const Icon(Icons.school_outlined, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            educationalDisclaimerText,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    ),
  );
}
