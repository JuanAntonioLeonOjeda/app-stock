import 'package:flutter/material.dart';
import 'package:stock_app/features/contenido_educativo/presentation/illustrations/illustration_canvas.dart';
import 'package:stock_app/features/contenido_educativo/presentation/illustrations/illustration_drawing.dart';

/// Ilustraciones de los conceptos de la gráfica de precio (criterio 75): las
/// medias y cómo leer la gráfica. No son métricas del motor.
final Map<String, IllustrationBuilder> chartConceptIllustrations = {
  'media_50': () => const PaintedIllustration(
    label: 'Una línea de precio irregular y su media de 50 sesiones, que la suaviza',
    painter: _ShortAveragePainter.new,
  ),
  'media_200': () => const PaintedIllustration(
    label:
        'La misma línea de precio y su media de 200 sesiones, mucho más lenta',
    painter: _LongAveragePainter.new,
  ),
  'grafico_precio': () => const PaintedIllustration(
    label: 'Una gráfica de precio con su máximo y su mínimo marcados y los periodos',
    painter: _PriceChartPainter.new,
  ),
};

/// Serie de precios (altura relativa) reutilizada por las dos medias.
const _prices = [0.55, 0.42, 0.52, 0.36, 0.48, 0.3, 0.44, 0.26, 0.38, 0.22];

Path _pricePath(Size size) {
  final path = Path()..moveTo(size.width * 0.1, size.height * _prices.first);
  for (var i = 1; i < _prices.length; i++) {
    path.lineTo(size.width * (0.1 + i * 0.088), size.height * _prices[i]);
  }
  return path;
}

void _axes(Canvas canvas, Size size, IllustrationPalette palette) {
  final axis = strokePaint(palette.line, size);
  canvas
    ..drawLine(rel(size, 0.08, 0.84), rel(size, 0.94, 0.84), axis)
    ..drawLine(rel(size, 0.08, 0.84), rel(size, 0.08, 0.1), axis);
}

/// Precio y una media que lo sigue de cerca, con la ventana de 50 sesiones.
class _ShortAveragePainter extends ThemedPainter {
  const _ShortAveragePainter(super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    _axes(canvas, size, palette);
    canvas.drawPath(
      _pricePath(size),
      strokePaint(palette.line, size, width: 0.012),
    );
    final average = Path()..moveTo(size.width * 0.1, size.height * 0.5);
    const ys = [0.47, 0.44, 0.42, 0.4, 0.38, 0.36, 0.34, 0.31, 0.3];
    for (var i = 0; i < ys.length; i++) {
      average.lineTo(size.width * (0.18 + i * 0.088), size.height * ys[i]);
    }
    canvas.drawPath(average, strokePaint(palette.accent, size, width: 0.022));
    final window = relRect(size, 0.62, 0.7, 0.28, 0.07);
    canvas.drawRect(window, fillPaint(palette.accent.withValues(alpha: 0.3)));
    canvas.drawRect(window, strokePaint(palette.accent, size, width: 0.01));
    paintCaption(
      canvas,
      size,
      '50 sesiones',
      window.center,
      palette.line,
      scale: 0.06,
    );
    paintCaption(
      canvas,
      size,
      'precio',
      rel(size, 0.22, 0.16),
      palette.line,
      scale: 0.065,
    );
    paintCaption(
      canvas,
      size,
      'media de 50',
      rel(size, 0.7, 0.14),
      palette.accent,
      scale: 0.065,
    );
  }
}

/// El mismo precio con una media casi recta: la ventana abarca todo el año.
class _LongAveragePainter extends ThemedPainter {
  const _LongAveragePainter(super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    _axes(canvas, size, palette);
    canvas.drawPath(
      _pricePath(size),
      strokePaint(palette.line, size, width: 0.012),
    );
    canvas.drawLine(
      rel(size, 0.1, 0.5),
      rel(size, 0.92, 0.36),
      strokePaint(palette.favorable, size, width: 0.022),
    );
    final window = relRect(size, 0.1, 0.7, 0.82, 0.07);
    canvas.drawRect(
      window,
      fillPaint(palette.favorable.withValues(alpha: 0.3)),
    );
    canvas.drawRect(window, strokePaint(palette.favorable, size, width: 0.01));
    paintCaption(
      canvas,
      size,
      '200 sesiones: casi un año',
      window.center,
      palette.line,
      scale: 0.06,
    );
    paintCaption(
      canvas,
      size,
      'precio',
      rel(size, 0.22, 0.16),
      palette.line,
      scale: 0.065,
    );
    paintCaption(
      canvas,
      size,
      'media de 200',
      rel(size, 0.72, 0.14),
      palette.favorable,
      scale: 0.065,
    );
  }
}

/// Gráfica con el máximo y el mínimo señalados y los chips de periodo.
class _PriceChartPainter extends ThemedPainter {
  const _PriceChartPainter(super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    const periods = ['1D', '1S', '1M', '1A', '5A'];
    for (var i = 0; i < periods.length; i++) {
      final chip = relRect(size, 0.1 + i * 0.12, 0.06, 0.1, 0.12);
      final selected = i == 3;
      canvas.drawRRect(
        RRect.fromRectAndRadius(chip, Radius.circular(size.height * 0.04)),
        fillPaint(selected ? palette.accent : palette.soft),
      );
      paintCaption(
        canvas,
        size,
        periods[i],
        chip.center,
        palette.line,
        scale: 0.06,
      );
    }
    final axis = strokePaint(palette.line, size);
    canvas
      ..drawLine(rel(size, 0.08, 0.88), rel(size, 0.94, 0.88), axis)
      ..drawLine(rel(size, 0.08, 0.88), rel(size, 0.08, 0.26), axis);
    final points = [
      rel(size, 0.1, 0.6),
      rel(size, 0.26, 0.4),
      rel(size, 0.4, 0.3),
      rel(size, 0.56, 0.74),
      rel(size, 0.74, 0.5),
      rel(size, 0.92, 0.42),
    ];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, strokePaint(palette.accent, size, width: 0.02));
    canvas
      ..drawCircle(points[2], size.height * 0.03, fillPaint(palette.favorable))
      ..drawCircle(
        points[3],
        size.height * 0.03,
        fillPaint(palette.unfavorable),
      );
    paintCaption(
      canvas,
      size,
      'máximo',
      points[2] + Offset(size.width * 0.1, -size.height * 0.04),
      palette.favorable,
      scale: 0.06,
    );
    paintCaption(
      canvas,
      size,
      'mínimo',
      points[3] + Offset(0, size.height * 0.1),
      palette.unfavorable,
      scale: 0.06,
    );
  }
}
