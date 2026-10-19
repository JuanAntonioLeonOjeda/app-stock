import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:stock_app/features/contenido_educativo/presentation/illustrations/illustration_canvas.dart';
import 'package:stock_app/features/contenido_educativo/presentation/illustrations/illustration_drawing.dart';

/// Ilustraciones del bloque técnico (criterio 75). Hablan de tendencia e
/// impulso del precio, no de si algo es buena o mala compra.
final Map<String, IllustrationBuilder> technicalIllustrations = {
  'precio_sma200': () => const PaintedIllustration(
    label: 'Un precio que oscila y su media del último año, más suave',
    painter: _PriceVsAveragePainter.new,
  ),
  'pendiente_sma200': () => const PaintedIllustration(
    label: 'Una línea suave que sube un poco cada 20 sesiones',
    painter: _AverageSlopePainter.new,
  ),
  'rsi': () => const PaintedIllustration(
    label: 'Un medidor de 0 a 100 con la aguja en la zona alta',
    painter: _RsiGaugePainter.new,
  ),
  'macd': () => const PaintedIllustration(
    label: 'Barras sobre una línea que crecen y luego se encogen: el impulso se frena',
    painter: _MacdPainter.new,
  ),
  'dist_maximo': () => const PaintedIllustration(
    label: 'Una montaña con su cima marcada y un punto más abajo en la ladera',
    painter: _DistanceToHighPainter.new,
  ),
};

/// Línea de precio irregular sobre/alrededor de una media suave.
class _PriceVsAveragePainter extends ThemedPainter {
  const _PriceVsAveragePainter(super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final axis = strokePaint(palette.line, size);
    canvas
      ..drawLine(rel(size, 0.08, 0.84), rel(size, 0.94, 0.84), axis)
      ..drawLine(rel(size, 0.08, 0.84), rel(size, 0.08, 0.12), axis);
    final average = Path()
      ..moveTo(size.width * 0.1, size.height * 0.62)
      ..lineTo(size.width * 0.92, size.height * 0.44);
    canvas.drawPath(average, strokePaint(palette.accent, size, width: 0.02));
    final price = Path()..moveTo(size.width * 0.1, size.height * 0.66);
    const ys = [0.54, 0.64, 0.46, 0.56, 0.36, 0.46, 0.3];
    for (var i = 0; i < ys.length; i++) {
      price.lineTo(size.width * (0.18 + i * 0.12), size.height * ys[i]);
    }
    canvas.drawPath(price, strokePaint(palette.line, size, width: 0.014));
    paintCaption(
      canvas,
      size,
      'precio',
      rel(size, 0.8, 0.22),
      palette.line,
      scale: 0.07,
    );
    paintCaption(
      canvas,
      size,
      'media de 200 sesiones',
      rel(size, 0.5, 0.93),
      palette.accent,
      scale: 0.065,
    );
  }
}

/// Una media creciente con el triángulo de su pendiente.
class _AverageSlopePainter extends ThemedPainter {
  const _AverageSlopePainter(super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      rel(size, 0.1, 0.7),
      rel(size, 0.92, 0.28),
      strokePaint(palette.accent, size, width: 0.022),
    );
    final guide = strokePaint(palette.line, size, width: 0.01);
    paintDashedLine(canvas, rel(size, 0.34, 0.58), rel(size, 0.7, 0.58), guide);
    paintDashedLine(canvas, rel(size, 0.7, 0.58), rel(size, 0.7, 0.4), guide);
    paintCaption(
      canvas,
      size,
      '20 sesiones',
      rel(size, 0.52, 0.68),
      palette.line,
      scale: 0.07,
    );
    paintCaption(
      canvas,
      size,
      '+2 %',
      rel(size, 0.84, 0.5),
      palette.favorable,
      scale: 0.085,
    );
    paintCaption(
      canvas,
      size,
      'muy lenta: avisa tarde',
      rel(size, 0.5, 0.9),
      palette.line,
      scale: 0.065,
    );
  }
}

/// Medidor semicircular de 0 a 100 con tres zonas y una aguja.
class _RsiGaugePainter extends ThemedPainter {
  const _RsiGaugePainter(super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final center = rel(size, 0.5, 0.8);
    final radius = size.height * 0.56;
    final arc = Rect.fromCircle(center: center, radius: radius);
    final width = size.height * 0.1;
    // Tramos 0-30, 30-70 y 70-100 sobre un semicírculo de 180°: son los cortes
    // convencionales del RSI («sobreventa» y «sobrecompra»), no los del motor.
    const zones = [(0.0, 0.3), (0.3, 0.7), (0.7, 1.0)];
    // El motor baja la nota en los dos extremos por igual: mismo color.
    final colors = [palette.accent, palette.favorable, palette.accent];
    for (var i = 0; i < zones.length; i++) {
      final paint = strokePaint(colors[i].withValues(alpha: 0.5), size)
        ..strokeWidth = width
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        arc,
        math.pi * (1 + zones[i].$1),
        math.pi * (zones[i].$2 - zones[i].$1),
        false,
        paint,
      );
    }
    final angle = math.pi * (1 + 0.67);
    final tip =
        center +
        Offset(
          radius * 0.92 * math.cos(angle),
          radius * 0.92 * math.sin(angle),
        );
    canvas
      ..drawLine(center, tip, strokePaint(palette.line, size, width: 0.02))
      ..drawCircle(center, size.height * 0.04, fillPaint(palette.line));
    paintCaption(
      canvas,
      size,
      '0',
      rel(size, 0.1, 0.9),
      palette.line,
      scale: 0.07,
    );
    paintCaption(
      canvas,
      size,
      '100',
      rel(size, 0.9, 0.9),
      palette.line,
      scale: 0.07,
    );
    paintCaption(
      canvas,
      size,
      '30',
      rel(size, 0.2, 0.34),
      palette.line,
      scale: 0.06,
    );
    paintCaption(
      canvas,
      size,
      '70',
      rel(size, 0.8, 0.34),
      palette.line,
      scale: 0.06,
    );
    paintCaption(
      canvas,
      size,
      'RSI',
      rel(size, 0.5, 0.95),
      palette.line,
      scale: 0.07,
    );
  }
}

/// Barras positivas que crecen y luego se encogen sobre una línea cero.
class _MacdPainter extends ThemedPainter {
  const _MacdPainter(super.palette);

  static const _bars = [0.04, 0.1, 0.18, 0.26, 0.2, 0.13, 0.07, 0.03];

  @override
  void paint(Canvas canvas, Size size) {
    final baseY = size.height * 0.62;
    canvas.drawLine(
      rel(size, 0.06, 0.62),
      rel(size, 0.94, 0.62),
      strokePaint(palette.line, size),
    );
    for (var i = 0; i < _bars.length; i++) {
      final isShrinking = i > 3;
      paintBar(
        canvas,
        size,
        isShrinking ? palette.accent : palette.favorable,
        size.width * (0.1 + i * 0.1),
        size.width * 0.07,
        size.height * _bars[i] * 1.8,
        baseY,
      );
    }
    paintCaption(
      canvas,
      size,
      'se acelera',
      rel(size, 0.3, 0.16),
      palette.favorable,
      scale: 0.07,
    );
    paintCaption(
      canvas,
      size,
      'se frena',
      rel(size, 0.74, 0.3),
      palette.accent,
      scale: 0.07,
    );
    paintCaption(
      canvas,
      size,
      'histograma del MACD',
      rel(size, 0.5, 0.88),
      palette.line,
      scale: 0.065,
    );
  }
}

/// Montaña con la cima marcada y un punto en la ladera, más abajo.
class _DistanceToHighPainter extends ThemedPainter {
  const _DistanceToHighPainter(super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final mountain = Path()
      ..moveTo(size.width * 0.1, size.height * 0.84)
      ..lineTo(size.width * 0.42, size.height * 0.18)
      ..lineTo(size.width * 0.9, size.height * 0.84)
      ..close();
    canvas
      ..drawPath(mountain, fillPaint(palette.soft))
      ..drawPath(mountain, strokePaint(palette.line, size));
    final peak = rel(size, 0.42, 0.18);
    final here = rel(size, 0.62, 0.5);
    canvas
      ..drawCircle(peak, size.height * 0.03, fillPaint(palette.favorable))
      ..drawCircle(here, size.height * 0.03, fillPaint(palette.accent));
    paintDashedLine(
      canvas,
      peak + Offset(size.width * 0.04, 0),
      Offset(size.width * 0.9, peak.dy),
      strokePaint(palette.favorable, size, width: 0.01),
    );
    paintArrow(
      canvas,
      size,
      palette.line,
      rel(size, 0.8, 0.2),
      rel(size, 0.8, 0.46),
    );
    paintCaption(
      canvas,
      size,
      'máximo',
      rel(size, 0.72, 0.1),
      palette.favorable,
      scale: 0.07,
    );
    paintCaption(
      canvas,
      size,
      'hoy',
      rel(size, 0.62, 0.6),
      palette.accent,
      scale: 0.07,
    );
    paintCaption(
      canvas,
      size,
      '−20 %',
      rel(size, 0.88, 0.34),
      palette.line,
      scale: 0.075,
    );
  }
}
