import 'package:flutter/material.dart';
import 'package:stock_app/core/theme/signal_colors.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/reading_scale.dart';

/// Color de un tono, del semáforo del tema. Sin la extensión (tests con un
/// tema simple) cae en los colores claros.
Color toneColor(BuildContext context, Tone tone) {
  final colors =
      Theme.of(context).extension<SignalColors>() ?? SignalColors.light;
  return switch (tone) {
    Tone.positive => colors.favorable,
    Tone.neutral => colors.neutral,
    Tone.negative => colors.unfavorable,
  };
}

/// Icono de un tono: el color nunca es la única pista.
IconData toneIcon(Tone tone) => switch (tone) {
  Tone.positive => Icons.check_circle_outline,
  Tone.neutral => Icons.remove_circle_outline,
  Tone.negative => Icons.error_outline,
};

String toneLabel(Tone tone) => switch (tone) {
  Tone.positive => 'Tramo favorable',
  Tone.neutral => 'Tramo intermedio',
  Tone.negative => 'Tramo desfavorable',
};
