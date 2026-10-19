import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:stock_app/features/contenido_educativo/presentation/illustrations/illustration_canvas.dart';
import 'package:stock_app/features/contenido_educativo/presentation/illustrations/illustration_drawing.dart';

/// Ilustraciones del bloque de salud financiera (criterio 75).
final Map<String, IllustrationBuilder> healthIllustrations = {
  'deuda_ebitda': () => const PaintedIllustration(
    label: 'Una deuda cubierta año a año con el beneficio del negocio',
    painter: _DebtYearsPainter.new,
  ),
  'deuda_patrimonio': () => const PaintedIllustration(
    label: 'Una casa pagada con mucha hipoteca y poco dinero propio',
    painter: _DebtEquityPainter.new,
  ),
  'liquidez': () => const PaintedIllustration(
    label: 'Un vaso de agua: el nivel frente a lo que hay que pagar este año',
    painter: _LiquidityPainter.new,
  ),
  'cobertura_intereses': () => const PaintedIllustration(
    label: 'Un sueldo que cubre tres veces la cuota de la hipoteca',
    painter: _InterestCoveragePainter.new,
  ),
  'fcf_positivo': () => const PaintedIllustration(
    label: 'Cinco años de caja: cuatro positivos y uno negativo',
    painter: _PositiveYearsPainter.new,
  ),
  'payout_fcf': () => const PaintedIllustration(
    label: 'Un círculo de caja libre del que casi todo se va en dividendos',
    painter: _PayoutPainter.new,
  ),
};

/// Una barra de deuda y los años de beneficio que hacen falta para taparla.
class _DebtYearsPainter extends ThemedPainter {
  const _DebtYearsPainter(super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final debt = relRect(size, 0.1, 0.2, 0.8, 0.16);
    canvas.drawRect(
      debt,
      fillPaint(palette.unfavorable.withValues(alpha: 0.3)),
    );
    canvas.drawRect(debt, strokePaint(palette.unfavorable, size, width: 0.016));
    paintCaption(canvas, size, 'deuda', debt.center, palette.line, scale: 0.08);
    for (var i = 0; i < 2; i++) {
      final year = relRect(size, 0.1 + i * 0.4, 0.5, 0.4, 0.16);
      canvas.drawRect(
        year,
        fillPaint(palette.favorable.withValues(alpha: 0.3)),
      );
      canvas.drawRect(year, strokePaint(palette.favorable, size, width: 0.016));
      paintCaption(
        canvas,
        size,
        'año ${i + 1}',
        year.center,
        palette.line,
        scale: 0.075,
      );
    }
    paintArrow(
      canvas,
      size,
      palette.line,
      rel(size, 0.5, 0.4),
      rel(size, 0.5, 0.48),
    );
    paintCaption(
      canvas,
      size,
      'beneficio operativo',
      rel(size, 0.5, 0.78),
      palette.line,
      scale: 0.07,
    );
  }
}

/// Una casa partida: mucha hipoteca arriba y poco dinero propio debajo.
class _DebtEquityPainter extends ThemedPainter {
  const _DebtEquityPainter(super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final roof = Path()
      ..moveTo(size.width * 0.28, size.height * 0.32)
      ..lineTo(size.width * 0.5, size.height * 0.12)
      ..lineTo(size.width * 0.72, size.height * 0.32)
      ..close();
    canvas
      ..drawPath(roof, fillPaint(palette.accent))
      ..drawPath(roof, strokePaint(palette.line, size));
    final debt = relRect(size, 0.3, 0.32, 0.4, 0.38);
    final own = relRect(size, 0.3, 0.7, 0.4, 0.16);
    canvas
      ..drawRect(debt, fillPaint(palette.unfavorable.withValues(alpha: 0.3)))
      ..drawRect(own, fillPaint(palette.favorable.withValues(alpha: 0.3)))
      ..drawRect(debt, strokePaint(palette.line, size))
      ..drawRect(own, strokePaint(palette.line, size));
    paintCaption(
      canvas,
      size,
      'hipoteca',
      debt.center,
      palette.line,
      scale: 0.08,
    );
    paintCaption(
      canvas,
      size,
      'lo tuyo',
      own.center,
      palette.line,
      scale: 0.07,
    );
    paintCaption(
      canvas,
      size,
      '70 %',
      rel(size, 0.85, 0.51),
      palette.unfavorable,
      scale: 0.08,
    );
    paintCaption(
      canvas,
      size,
      '30 %',
      rel(size, 0.85, 0.78),
      palette.favorable,
      scale: 0.08,
    );
  }
}

/// Un vaso con agua y una raya que marca lo que hay que pagar este año.
class _LiquidityPainter extends ThemedPainter {
  const _LiquidityPainter(super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final glass = Path()
      ..moveTo(size.width * 0.34, size.height * 0.14)
      ..lineTo(size.width * 0.66, size.height * 0.14)
      ..lineTo(size.width * 0.6, size.height * 0.86)
      ..lineTo(size.width * 0.4, size.height * 0.86)
      ..close();
    final water = Path()
      ..moveTo(size.width * 0.3 + size.width * 0.045, size.height * 0.38)
      ..lineTo(size.width * 0.66 - size.width * 0.045, size.height * 0.38)
      ..lineTo(size.width * 0.6, size.height * 0.86)
      ..lineTo(size.width * 0.4, size.height * 0.86)
      ..close();
    canvas
      ..drawPath(water, fillPaint(palette.accent.withValues(alpha: 0.45)))
      ..drawPath(glass, strokePaint(palette.line, size, width: 0.016));
    final mark = strokePaint(palette.unfavorable, size, width: 0.012);
    paintDashedLine(canvas, rel(size, 0.22, 0.58), rel(size, 0.78, 0.58), mark);
    paintCaption(
      canvas,
      size,
      'pagos del año',
      rel(size, 0.88, 0.5),
      palette.unfavorable,
      scale: 0.07,
    );
    paintCaption(
      canvas,
      size,
      'lo que tienes',
      rel(size, 0.14, 0.3),
      palette.line,
      scale: 0.07,
    );
  }
}

/// Un sueldo en tres partes y una sola, la cuota, tiene color de deuda.
class _InterestCoveragePainter extends ThemedPainter {
  const _InterestCoveragePainter(super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    paintCaption(
      canvas,
      size,
      'lo que ganas',
      rel(size, 0.5, 0.14),
      palette.line,
      scale: 0.075,
    );
    for (var i = 0; i < 3; i++) {
      final slot = relRect(size, 0.1 + i * 0.27, 0.24, 0.26, 0.2);
      canvas.drawRect(
        slot,
        fillPaint(palette.favorable.withValues(alpha: 0.3)),
      );
      canvas.drawRect(slot, strokePaint(palette.favorable, size, width: 0.014));
    }
    paintCaption(
      canvas,
      size,
      'cuota',
      rel(size, 0.5, 0.58),
      palette.unfavorable,
      scale: 0.075,
    );
    final fee = relRect(size, 0.1, 0.66, 0.26, 0.2);
    canvas.drawRect(fee, fillPaint(palette.unfavorable.withValues(alpha: 0.3)));
    canvas.drawRect(fee, strokePaint(palette.unfavorable, size, width: 0.014));
    paintCaption(
      canvas,
      size,
      '× 3',
      rel(size, 0.62, 0.76),
      palette.line,
      scale: 0.16,
    );
  }
}

/// Cinco barras de caja anual sobre una línea: arriba, positivas; abajo, negativas.
class _PositiveYearsPainter extends ThemedPainter {
  const _PositiveYearsPainter(super.palette);

  static const _years = [0.22, 0.14, -0.1, 0.18, 0.26];

  @override
  void paint(Canvas canvas, Size size) {
    final baseline = size.height * 0.56;
    canvas.drawLine(
      rel(size, 0.08, 0.56),
      rel(size, 0.92, 0.56),
      strokePaint(palette.line, size),
    );
    for (var i = 0; i < _years.length; i++) {
      final value = _years[i];
      final left = size.width * (0.14 + i * 0.16);
      final height = size.height * value.abs() * 1.4;
      final top = value >= 0 ? baseline - height : baseline;
      final bar = Rect.fromLTWH(left, top, size.width * 0.11, height);
      final color = value >= 0 ? palette.favorable : palette.unfavorable;
      canvas.drawRect(bar, fillPaint(color.withValues(alpha: 0.35)));
      canvas.drawRect(bar, strokePaint(color, size, width: 0.014));
      paintCaption(
        canvas,
        size,
        'año ${i + 1}',
        Offset(left + size.width * 0.055, size.height * 0.92),
        palette.line,
        scale: 0.06,
      );
    }
    paintCaption(
      canvas,
      size,
      '4 de 5',
      rel(size, 0.5, 0.1),
      palette.line,
      scale: 0.1,
    );
  }
}

/// Un círculo de caja libre con un gran trozo ya repartido en dividendos.
class _PayoutPainter extends ThemedPainter {
  const _PayoutPainter(super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final center = rel(size, 0.4, 0.5);
    final radius = size.height * 0.34;
    final circle = Rect.fromCircle(center: center, radius: radius);
    const share = 0.8;
    canvas
      ..drawArc(
        circle,
        -math.pi / 2,
        2 * math.pi * share,
        true,
        fillPaint(palette.unfavorable.withValues(alpha: 0.35)),
      )
      ..drawArc(
        circle,
        -math.pi / 2 + 2 * math.pi * share,
        2 * math.pi * (1 - share),
        true,
        fillPaint(palette.favorable.withValues(alpha: 0.35)),
      )
      ..drawCircle(center, radius, strokePaint(palette.line, size));
    paintCaption(
      canvas,
      size,
      'caja libre',
      rel(size, 0.4, 0.1),
      palette.line,
      scale: 0.075,
    );
    paintCaption(
      canvas,
      size,
      'dividendo',
      rel(size, 0.8, 0.4),
      palette.unfavorable,
      scale: 0.075,
    );
    paintCaption(
      canvas,
      size,
      'lo que queda',
      rel(size, 0.8, 0.7),
      palette.favorable,
      scale: 0.07,
    );
  }
}
