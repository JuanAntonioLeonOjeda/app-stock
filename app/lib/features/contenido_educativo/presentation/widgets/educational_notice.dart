import 'package:flutter/material.dart';

/// Mismo texto que el aviso de `analisis_accion`: duplicarlo cuesta menos que
/// una dependencia entre features.
const educationalNoticeText =
    'Análisis con fin educativo. No es una recomendación de inversión.';

/// Aviso de que el contenido enseña y no recomienda (criterio 10).
class EducationalNotice extends StatelessWidget {
  const EducationalNotice({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Text(
      educationalNoticeText,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall,
    ),
  );
}
