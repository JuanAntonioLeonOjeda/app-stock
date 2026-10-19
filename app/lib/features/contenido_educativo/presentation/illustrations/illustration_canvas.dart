import 'package:flutter/material.dart';
import 'package:stock_app/core/theme/signal_colors.dart';

/// Construye la ilustración de una métrica o concepto.
typedef IllustrationBuilder = Widget Function();

/// Colores de las ilustraciones, del tema para que sigan el modo claro y el
/// oscuro (criterio 75).
class IllustrationPalette {
  const IllustrationPalette({
    required this.line,
    required this.accent,
    required this.soft,
    required this.favorable,
    required this.unfavorable,
  });

  factory IllustrationPalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final signals = theme.extension<SignalColors>() ?? SignalColors.light;
    return IllustrationPalette(
      line: theme.colorScheme.onSurface,
      accent: theme.colorScheme.primary,
      soft: theme.colorScheme.primaryContainer,
      favorable: signals.favorable,
      unfavorable: signals.unfavorable,
    );
  }

  /// Trazo principal.
  final Color line;

  /// Elemento destacado.
  final Color accent;

  /// Relleno suave.
  final Color soft;
  final Color favorable;
  final Color unfavorable;
}

/// Caja de proporción fija donde se dibuja una ilustración. [paint] recibe la
/// paleta del tema y devuelve el `CustomPainter`; [semanticLabel] describe el
/// dibujo para un lector de pantalla.
class IllustrationCanvas extends StatelessWidget {
  const IllustrationCanvas({
    super.key,
    required this.semanticLabel,
    required this.paint,
  });

  /// Proporción (ancho / alto) común a todas las ilustraciones.
  static const aspectRatio = 16 / 9;

  final String semanticLabel;
  final CustomPainter Function(IllustrationPalette palette) paint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      image: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ColoredBox(
            color: theme.colorScheme.surfaceContainerHighest,
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: CustomPaint(
                painter: paint(IllustrationPalette.of(context)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
