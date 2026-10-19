import 'package:flutter/material.dart';
import 'package:stock_app/features/contenido_educativo/presentation/illustrations/illustration_canvas.dart';
import 'package:stock_app/features/contenido_educativo/presentation/illustrations/illustration_drawing.dart';

/// Ilustraciones del bloque de crecimiento y rentabilidad (criterio 75).
final Map<String, IllustrationBuilder> growthIllustrations = {
  'ingresos_cagr3': () => const PaintedIllustration(
    label: 'Una panadería cuyas ventas suben año tras año durante tres años',
    painter: _RevenueTrendPainter.new,
  ),
  'ingresos_yoy': () => const PaintedIllustration(
    label: 'Dos barras: las ventas del año pasado y las de este año',
    painter: _RevenueYearPainter.new,
  ),
  'beneficio_cagr3': () => const PaintedIllustration(
    label: 'Pilas de monedas cada vez más altas: lo que queda al dueño',
    painter: _ProfitTrendPainter.new,
  ),
  'margen_operativo': () => const PaintedIllustration(
    label: 'Una pizza de 10 euros de la que quedan 2 euros tras los costes',
    painter: _OperatingMarginPainter.new,
  ),
  'margen_tendencia': () => const PaintedIllustration(
    label: 'Una línea que sube: el margen mejora de un 12 % a un 15 %',
    painter: _MarginTrendPainter.new,
  ),
  'margen_bruto': () => const PaintedIllustration(
    label: 'Una barra con el coste directo del producto y lo que sobra',
    painter: _GrossMarginPainter.new,
  ),
  'roic': () => const PaintedIllustration(
    label: 'Cien euros invertidos en un negocio que devuelven quince cada año',
    painter: _RoicPainter.new,
  ),
  'roe': () => const PaintedIllustration(
    label: 'Una libreta con el dinero de los dueños y lo que rinde cada año',
    painter: _RoePainter.new,
  ),
  'dilucion': () => const PaintedIllustration(
    label: 'Una tarta: al repartir más trozos, tu parte se hace más pequeña',
    painter: _DilutionPainter.new,
  ),
};

/// Cuatro barras de ventas crecientes con una flecha de tendencia.
class _RevenueTrendPainter extends ThemedPainter {
  const _RevenueTrendPainter(super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final baseY = size.height * 0.8;
    final heights = [0.22, 0.3, 0.4, 0.52];
    const captions = ['hace 3', 'hace 2', 'hace 1', 'hoy'];
    for (var i = 0; i < heights.length; i++) {
      final left = size.width * (0.12 + i * 0.2);
      paintBar(
        canvas,
        size,
        palette.accent,
        left,
        size.width * 0.14,
        size.height * heights[i],
        baseY,
      );
      paintCaption(
        canvas,
        size,
        captions[i],
        Offset(left + size.width * 0.07, size.height * 0.9),
        palette.line,
        scale: 0.065,
      );
    }
    paintArrow(
      canvas,
      size,
      palette.favorable,
      rel(size, 0.14, 0.5),
      rel(size, 0.84, 0.2),
    );
    paintCaption(
      canvas,
      size,
      '+10 % al año',
      rel(size, 0.3, 0.2),
      palette.favorable,
      scale: 0.075,
    );
  }
}

/// Dos barras, el año pasado y este, con el salto entre ambas.
class _RevenueYearPainter extends ThemedPainter {
  const _RevenueYearPainter(super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final baseY = size.height * 0.8;
    paintBar(
      canvas,
      size,
      palette.line,
      size.width * 0.25,
      size.width * 0.2,
      size.height * 0.38,
      baseY,
    );
    paintBar(
      canvas,
      size,
      palette.accent,
      size.width * 0.55,
      size.width * 0.2,
      size.height * 0.46,
      baseY,
    );
    paintCaption(
      canvas,
      size,
      'año pasado',
      rel(size, 0.35, 0.9),
      palette.line,
      scale: 0.07,
    );
    paintCaption(
      canvas,
      size,
      'este año',
      rel(size, 0.65, 0.9),
      palette.line,
      scale: 0.07,
    );
    paintArrow(
      canvas,
      size,
      palette.favorable,
      rel(size, 0.8, 0.5),
      rel(size, 0.8, 0.26),
    );
    paintCaption(
      canvas,
      size,
      '+10 %',
      rel(size, 0.88, 0.2),
      palette.favorable,
      scale: 0.08,
    );
  }
}

/// Pilas de monedas que crecen: lo que de verdad le queda al dueño.
class _ProfitTrendPainter extends ThemedPainter {
  const _ProfitTrendPainter(super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final counts = [1, 2, 3, 5];
    for (var i = 0; i < counts.length; i++) {
      paintCoins(
        canvas,
        size,
        palette,
        rel(size, 0.17 + i * 0.22, 0.8),
        counts[i],
      );
    }
    canvas.drawLine(
      rel(size, 0.06, 0.84),
      rel(size, 0.94, 0.84),
      strokePaint(palette.line, size),
    );
    paintCaption(
      canvas,
      size,
      'lo que te queda cada año',
      rel(size, 0.5, 0.94),
      palette.line,
      scale: 0.07,
    );
    paintArrow(
      canvas,
      size,
      palette.favorable,
      rel(size, 0.14, 0.3),
      rel(size, 0.8, 0.14),
    );
  }
}

/// Una pizza de la que sale una porción pequeña para el dueño.
class _OperatingMarginPainter extends ThemedPainter {
  const _OperatingMarginPainter(super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    paintPie(
      canvas,
      size,
      palette,
      rel(size, 0.35, 0.52),
      size.height * 0.34,
      slices: 5,
    );
    paintCaption(
      canvas,
      size,
      '10 € de venta',
      rel(size, 0.35, 0.1),
      palette.line,
      scale: 0.075,
    );
    paintCaption(
      canvas,
      size,
      '2 € para ti',
      rel(size, 0.78, 0.3),
      palette.accent,
      scale: 0.08,
    );
    paintCaption(
      canvas,
      size,
      '8 € de costes',
      rel(size, 0.78, 0.66),
      palette.unfavorable,
      scale: 0.08,
    );
    paintArrow(
      canvas,
      size,
      palette.accent,
      rel(size, 0.64, 0.32),
      rel(size, 0.6, 0.38),
    );
  }
}

/// Una línea ascendente que une dos márgenes: antes y ahora.
class _MarginTrendPainter extends ThemedPainter {
  const _MarginTrendPainter(super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final axis = strokePaint(palette.line, size);
    canvas
      ..drawLine(rel(size, 0.1, 0.8), rel(size, 0.92, 0.8), axis)
      ..drawLine(rel(size, 0.1, 0.8), rel(size, 0.1, 0.14), axis);
    final points = [
      rel(size, 0.2, 0.62),
      rel(size, 0.42, 0.56),
      rel(size, 0.66, 0.44),
      rel(size, 0.86, 0.3),
    ];
    final trend = strokePaint(palette.favorable, size, width: 0.02);
    for (var i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], trend);
    }
    for (final point in points) {
      canvas.drawCircle(
        point,
        size.height * 0.025,
        fillPaint(palette.favorable),
      );
    }
    paintCaption(
      canvas,
      size,
      '12 %',
      rel(size, 0.2, 0.72),
      palette.line,
      scale: 0.075,
    );
    paintCaption(
      canvas,
      size,
      '15 %',
      rel(size, 0.86, 0.2),
      palette.line,
      scale: 0.075,
    );
    paintCaption(
      canvas,
      size,
      '+3 puntos',
      rel(size, 0.52, 0.9),
      palette.favorable,
      scale: 0.075,
    );
  }
}

/// Una barra partida: el coste directo y lo que sobra del producto.
class _GrossMarginPainter extends ThemedPainter {
  const _GrossMarginPainter(super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    const barLeft = 0.3;
    const barWidth = 0.24;
    const top = 0.12;
    const total = 0.72;
    final cost = relRect(
      size,
      barLeft,
      top + total * 0.7,
      barWidth,
      total * 0.3,
    );
    final gross = relRect(size, barLeft, top, barWidth, total * 0.7);
    canvas
      ..drawRect(cost, fillPaint(palette.unfavorable.withValues(alpha: 0.3)))
      ..drawRect(gross, fillPaint(palette.favorable.withValues(alpha: 0.3)))
      ..drawRect(cost, strokePaint(palette.line, size))
      ..drawRect(gross, strokePaint(palette.line, size));
    paintCaption(
      canvas,
      size,
      'coste directo',
      rel(size, 0.76, top + total * 0.85),
      palette.unfavorable,
      scale: 0.07,
    );
    paintCaption(
      canvas,
      size,
      'lo que sobra',
      rel(size, 0.76, top + total * 0.35),
      palette.favorable,
      scale: 0.07,
    );
    paintCaption(
      canvas,
      size,
      '100 de venta',
      rel(size, 0.16, 0.5),
      palette.line,
      scale: 0.065,
    );
    paintCaption(
      canvas,
      size,
      'antes de gastos generales',
      rel(size, 0.42, 0.94),
      palette.line,
      scale: 0.06,
    );
  }
}

/// Un montón de monedas que se convierte en una pila pequeña cada año.
class _RoicPainter extends ThemedPainter {
  const _RoicPainter(super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    paintCoins(canvas, size, palette, rel(size, 0.2, 0.78), 7);
    paintCaption(
      canvas,
      size,
      '100 €',
      rel(size, 0.2, 0.92),
      palette.line,
      scale: 0.075,
    );
    paintCaption(
      canvas,
      size,
      'negocio',
      rel(size, 0.5, 0.3),
      palette.line,
      scale: 0.075,
    );
    paintArrow(
      canvas,
      size,
      palette.line,
      rel(size, 0.36, 0.5),
      rel(size, 0.64, 0.5),
    );
    paintCoins(canvas, size, palette, rel(size, 0.8, 0.78), 1);
    paintCaption(
      canvas,
      size,
      '15 € al año',
      rel(size, 0.8, 0.92),
      palette.favorable,
      scale: 0.075,
    );
    paintCaption(
      canvas,
      size,
      '15 %',
      rel(size, 0.5, 0.62),
      palette.favorable,
      scale: 0.12,
    );
  }
}

/// Una libreta de ahorro con el dinero de los dueños y su rendimiento.
class _RoePainter extends ThemedPainter {
  const _RoePainter(super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final book = relRect(size, 0.18, 0.2, 0.4, 0.62);
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(book, Radius.circular(size.height * 0.04)),
        fillPaint(palette.soft),
      )
      ..drawRRect(
        RRect.fromRectAndRadius(book, Radius.circular(size.height * 0.04)),
        strokePaint(palette.line, size),
      )
      ..drawLine(
        rel(size, 0.26, 0.2),
        rel(size, 0.26, 0.82),
        strokePaint(palette.line, size),
      );
    paintCaption(
      canvas,
      size,
      'dueños',
      rel(size, 0.42, 0.34),
      palette.line,
      scale: 0.075,
    );
    paintCaption(
      canvas,
      size,
      '100 €',
      rel(size, 0.42, 0.56),
      palette.line,
      scale: 0.11,
    );
    paintArrow(
      canvas,
      size,
      palette.favorable,
      rel(size, 0.62, 0.5),
      rel(size, 0.76, 0.34),
    );
    final tag = relRect(size, 0.68, 0.18, 0.24, 0.16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(tag, Radius.circular(size.height * 0.03)),
      fillPaint(palette.favorable.withValues(alpha: 0.3)),
    );
    paintCaption(
      canvas,
      size,
      '+12 €',
      tag.center,
      palette.favorable,
      scale: 0.09,
    );
    paintCaption(
      canvas,
      size,
      '12 % al año',
      rel(size, 0.8, 0.62),
      palette.line,
      scale: 0.075,
    );
  }
}

/// La misma tarta repartida en más trozos: tu porción es cada vez menor.
class _DilutionPainter extends ThemedPainter {
  const _DilutionPainter(super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    paintPie(
      canvas,
      size,
      palette,
      rel(size, 0.22, 0.5),
      size.height * 0.28,
      slices: 4,
    );
    paintCaption(
      canvas,
      size,
      'tu parte: 1/4',
      rel(size, 0.22, 0.14),
      palette.line,
      scale: 0.065,
    );
    paintArrow(
      canvas,
      size,
      palette.line,
      rel(size, 0.42, 0.5),
      rel(size, 0.56, 0.5),
    );
    paintPie(
      canvas,
      size,
      palette,
      rel(size, 0.78, 0.5),
      size.height * 0.28,
      slices: 8,
    );
    paintCaption(
      canvas,
      size,
      'tu parte: 1/8',
      rel(size, 0.78, 0.14),
      palette.unfavorable,
      scale: 0.065,
    );
    paintCaption(
      canvas,
      size,
      'acciones nuevas',
      rel(size, 0.5, 0.78),
      palette.unfavorable,
      scale: 0.065,
    );
  }
}
