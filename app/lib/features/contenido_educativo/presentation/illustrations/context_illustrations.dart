import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:stock_app/features/contenido_educativo/presentation/illustrations/illustration_canvas.dart';
import 'package:stock_app/features/contenido_educativo/presentation/illustrations/illustration_drawing.dart';

/// Ilustraciones del bloque de contexto (criterio 75).
final Map<String, IllustrationBuilder> contextIllustrations = {
  'sorpresas_bpa': () => const PaintedIllustration(
    label: 'Cuatro trimestres frente a la estimación: dos la superan y dos no',
    painter: _EarningsSurprisePainter.new,
  ),
  'potencial_analistas': () => const PaintedIllustration(
    label: 'Varios analistas señalan un precio objetivo por encima del actual',
    painter: _AnalystTargetPainter.new,
  ),
  'beta': () => const PaintedIllustration(
    label: 'Dos olas: la del mercado y la de una acción que oscila más',
    painter: _BetaPainter.new,
  ),
  'caida_maxima': () => const PaintedIllustration(
    label: 'Una línea de precio que sube, cae con fuerza y se recupera',
    painter: _MaxDrawdownPainter.new,
  ),
};

/// Cuatro trimestres con la estimación como línea y el resultado real arriba o abajo.
class _EarningsSurprisePainter extends ThemedPainter {
  const _EarningsSurprisePainter(super.palette);

  /// Resultado real frente a la estimación: positivo, supera; negativo, no.
  static const _gaps = [0.2, 0.0, 0.14, -0.1];

  @override
  void paint(Canvas canvas, Size size) {
    final expected = size.height * 0.5;
    for (var i = 0; i < _gaps.length; i++) {
      final left = size.width * (0.12 + i * 0.2);
      final width = size.width * 0.14;
      final gap = _gaps[i];
      final real = expected - size.height * gap * 1.6;
      final isBeat = gap > 0;
      final color = isBeat ? palette.favorable : palette.accent;
      final bar = Rect.fromLTRB(
        left,
        math.min(real, expected + 1),
        left + width,
        size.height * 0.8,
      ).intersect(Rect.fromLTRB(left, 0, left + width, size.height * 0.8));
      canvas.drawRect(bar, fillPaint(color.withValues(alpha: 0.3)));
      canvas.drawRect(bar, strokePaint(color, size, width: 0.014));
      paintCaption(
        canvas,
        size,
        'T${i + 1}',
        Offset(left + width / 2, size.height * 0.9),
        palette.line,
        scale: 0.065,
      );
      paintCaption(
        canvas,
        size,
        isBeat ? 'bate' : (gap == 0 ? 'iguala' : 'no llega'),
        Offset(left + width / 2, size.height * 0.12),
        color,
        scale: 0.06,
      );
    }
    paintDashedLine(
      canvas,
      rel(size, 0.06, 0.5),
      rel(size, 0.94, 0.5),
      strokePaint(palette.line, size, width: 0.012),
    );
    paintCaption(
      canvas,
      size,
      'lo estimado',
      rel(size, 0.88, 0.44),
      palette.line,
      scale: 0.055,
    );
  }
}

/// Tres analistas que apuntan a una bandera de objetivo más alta que el precio.
class _AnalystTargetPainter extends ThemedPainter {
  const _AnalystTargetPainter(super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 3; i++) {
      final center = rel(size, 0.14 + i * 0.12, 0.7);
      canvas.drawCircle(
        center - Offset(0, size.height * 0.06),
        size.height * 0.05,
        fillPaint(palette.soft),
      );
      canvas.drawCircle(
        center - Offset(0, size.height * 0.06),
        size.height * 0.05,
        strokePaint(palette.line, size),
      );
      canvas.drawArc(
        Rect.fromCenter(
          center: center + Offset(0, size.height * 0.06),
          width: size.height * 0.16,
          height: size.height * 0.14,
        ),
        math.pi,
        math.pi,
        false,
        strokePaint(palette.line, size),
      );
    }
    paintCaption(
      canvas,
      size,
      'analistas',
      rel(size, 0.26, 0.92),
      palette.line,
      scale: 0.065,
    );
    paintArrow(
      canvas,
      size,
      palette.line,
      rel(size, 0.46, 0.6),
      rel(size, 0.64, 0.34),
    );
    final pole = strokePaint(palette.line, size, width: 0.016);
    canvas.drawLine(rel(size, 0.7, 0.12), rel(size, 0.7, 0.42), pole);
    final flag = Path()
      ..moveTo(size.width * 0.7, size.height * 0.12)
      ..lineTo(size.width * 0.9, size.height * 0.2)
      ..lineTo(size.width * 0.7, size.height * 0.28)
      ..close();
    canvas
      ..drawPath(flag, fillPaint(palette.favorable.withValues(alpha: 0.4)))
      ..drawPath(flag, strokePaint(palette.favorable, size));
    paintCaption(
      canvas,
      size,
      'objetivo',
      rel(size, 0.8, 0.07),
      palette.favorable,
      scale: 0.065,
    );
    final price = relRect(size, 0.62, 0.62, 0.26, 0.16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(price, Radius.circular(size.height * 0.03)),
      fillPaint(palette.accent.withValues(alpha: 0.35)),
    );
    paintCaption(
      canvas,
      size,
      'precio hoy',
      price.center,
      palette.line,
      scale: 0.065,
    );
  }
}

/// Una ola de mercado y otra, la de la acción, con más amplitud.
class _BetaPainter extends ThemedPainter {
  const _BetaPainter(super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    paintDashedLine(
      canvas,
      rel(size, 0.06, 0.5),
      rel(size, 0.94, 0.5),
      strokePaint(palette.line, size, width: 0.01),
    );
    canvas
      ..drawPath(
        _wave(size, 0.12),
        strokePaint(palette.accent, size, width: 0.02),
      )
      ..drawPath(
        _wave(size, 0.18),
        strokePaint(palette.unfavorable, size, width: 0.02),
      );
    paintCaption(
      canvas,
      size,
      'mercado',
      rel(size, 0.18, 0.88),
      palette.accent,
      scale: 0.07,
    );
    paintCaption(
      canvas,
      size,
      'acción con beta 1,5',
      rel(size, 0.7, 0.88),
      palette.unfavorable,
      scale: 0.07,
    );
  }

  Path _wave(Size size, double amplitude) {
    final path = Path()..moveTo(size.width * 0.06, size.height * 0.5);
    const steps = 60;
    for (var i = 1; i <= steps; i++) {
      final t = i / steps;
      path.lineTo(
        size.width * (0.06 + 0.88 * t),
        size.height * (0.5 - amplitude * math.sin(t * 4 * math.pi)),
      );
    }
    return path;
  }
}

/// Un precio que sube, cae con fuerza y se recupera; la caída está acotada.
class _MaxDrawdownPainter extends ThemedPainter {
  const _MaxDrawdownPainter(super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final axis = strokePaint(palette.line, size);
    canvas
      ..drawLine(rel(size, 0.08, 0.84), rel(size, 0.94, 0.84), axis)
      ..drawLine(rel(size, 0.08, 0.84), rel(size, 0.08, 0.1), axis);
    final points = [
      rel(size, 0.1, 0.62),
      rel(size, 0.3, 0.2),
      rel(size, 0.55, 0.66),
      rel(size, 0.9, 0.3),
    ];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, strokePaint(palette.accent, size, width: 0.02));
    canvas
      ..drawCircle(points[1], size.height * 0.03, fillPaint(palette.favorable))
      ..drawCircle(
        points[2],
        size.height * 0.03,
        fillPaint(palette.unfavorable),
      );
    paintArrow(
      canvas,
      size,
      palette.unfavorable,
      rel(size, 0.4, 0.22),
      rel(size, 0.4, 0.62),
    );
    paintCaption(
      canvas,
      size,
      '−30 %',
      rel(size, 0.5, 0.42),
      palette.unfavorable,
      scale: 0.09,
    );
    paintCaption(
      canvas,
      size,
      'máximo',
      rel(size, 0.3, 0.1),
      palette.favorable,
      scale: 0.065,
    );
    paintCaption(
      canvas,
      size,
      'mínimo',
      rel(size, 0.55, 0.76),
      palette.unfavorable,
      scale: 0.065,
    );
  }
}
