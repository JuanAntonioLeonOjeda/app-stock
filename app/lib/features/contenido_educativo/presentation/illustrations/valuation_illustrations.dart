import 'package:flutter/material.dart';
import 'package:stock_app/features/contenido_educativo/presentation/illustrations/illustration_canvas.dart';
import 'package:stock_app/features/contenido_educativo/presentation/illustrations/illustration_drawing.dart';

/// Ilustraciones del bloque de valoración (criterio 75): una analogía por
/// métrica, dibujada con los colores del tema.
final Map<String, IllustrationBuilder> valuationIllustrations = {
  'per': () => const PaintedIllustration(
    label: 'Una tienda de barrio que cuesta 15 veces lo que gana en un año',
    painter: _PerPainter.new,
  ),
  'peg': () => const PaintedIllustration(
    label: 'Dos negocios con el mismo precio: uno crece poco y el otro mucho',
    painter: _PegPainter.new,
  ),
  'ev_ebitda': () => const PaintedIllustration(
    label: 'El precio de una casa entera: lo que pagas más la hipoteca, menos lo ahorrado',
    painter: _EvEbitdaPainter.new,
  ),
  'p_fcf': () => const PaintedIllustration(
    label: 'Un cajón con el dinero que queda después de pagar gastos e inversiones',
    painter: _PFcfPainter.new,
  ),
  'p_ventas': () => const PaintedIllustration(
    label: 'Un negocio recién abierto: su precio frente a lo que vende',
    painter: _PVentasPainter.new,
  ),
  'p_vc': () => const PaintedIllustration(
    label: 'Una balanza que compara el precio de una casa con lo que valdría por partes',
    painter: _PVcPainter.new,
  ),
};

/// Tienda → años: «15 años para recuperar lo que pagas».
class _PerPainter extends ThemedPainter {
  const _PerPainter(super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    paintShop(canvas, size, palette, relRect(size, 0.08, 0.2, 0.28, 0.6));
    paintCaption(canvas, size, '150.000 €', rel(size, 0.22, 0.1), palette.line);
    paintArrow(
      canvas,
      size,
      palette.line,
      rel(size, 0.42, 0.5),
      rel(size, 0.58, 0.5),
    );
    _drawCalendar(canvas, size, relRect(size, 0.62, 0.22, 0.3, 0.52));
    paintCaption(
      canvas,
      size,
      '10.000 € al año',
      rel(size, 0.5, 0.88),
      palette.line,
      scale: 0.075,
    );
  }

  void _drawCalendar(Canvas canvas, Size size, Rect box) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, Radius.circular(size.height * 0.04)),
      fillPaint(palette.soft),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, Radius.circular(size.height * 0.04)),
      strokePaint(palette.line, size),
    );
    canvas.drawRect(
      Rect.fromLTWH(box.left, box.top, box.width, box.height * 0.28),
      fillPaint(palette.accent),
    );
    paintCaption(
      canvas,
      size,
      '15',
      box.center + Offset(0, box.height * 0.12),
      palette.line,
      scale: 0.18,
    );
    paintCaption(
      canvas,
      size,
      'años',
      box.center + Offset(0, box.height * 0.36),
      palette.line,
      scale: 0.07,
    );
  }
}

/// Dos curvas de crecimiento con la misma base: una casi plana y otra empinada.
class _PegPainter extends ThemedPainter {
  const _PegPainter(super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final axis = strokePaint(palette.line, size);
    canvas
      ..drawLine(rel(size, 0.1, 0.82), rel(size, 0.92, 0.82), axis)
      ..drawLine(rel(size, 0.1, 0.82), rel(size, 0.1, 0.14), axis);
    final slow = strokePaint(palette.unfavorable, size, width: 0.02)
      ..strokeWidth = size.height * 0.02;
    final fast = strokePaint(palette.favorable, size, width: 0.02);
    canvas
      ..drawLine(rel(size, 0.12, 0.7), rel(size, 0.9, 0.6), slow)
      ..drawPath(_curve(size), fast);
    paintCaption(
      canvas,
      size,
      'crece un 5 %',
      rel(size, 0.7, 0.72),
      palette.unfavorable,
      scale: 0.07,
    );
    paintCaption(
      canvas,
      size,
      'crece un 20 %',
      rel(size, 0.4, 0.32),
      palette.favorable,
      scale: 0.07,
    );
    paintCaption(
      canvas,
      size,
      'mismo PER',
      rel(size, 0.78, 0.92),
      palette.line,
      scale: 0.07,
    );
  }

  Path _curve(Size size) => Path()
    ..moveTo(size.width * 0.12, size.height * 0.7)
    ..quadraticBezierTo(
      size.width * 0.55,
      size.height * 0.68,
      size.width * 0.9,
      size.height * 0.2,
    );
}

/// Casa con tres barras: lo que vale, la hipoteca y lo ahorrado.
class _EvEbitdaPainter extends ThemedPainter {
  const _EvEbitdaPainter(super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    _bar(canvas, size, 0.06, 0.45, palette.accent, 'En bolsa');
    _bar(canvas, size, 0.27, 0.3, palette.unfavorable, '+ Deuda');
    _bar(canvas, size, 0.48, 0.2, palette.favorable, '− Caja');
    paintCaption(
      canvas,
      size,
      '=',
      rel(size, 0.78, 0.5),
      palette.line,
      scale: 0.16,
    );
    _bar(canvas, size, 0.76, 0.55, palette.line, 'EV');
  }

  void _bar(
    Canvas canvas,
    Size size,
    double left,
    double heightFraction,
    Color color,
    String caption,
  ) {
    final bottom = 0.78;
    final box = relRect(
      size,
      left,
      bottom - heightFraction,
      0.16,
      heightFraction,
    );
    canvas.drawRect(box, fillPaint(color.withValues(alpha: 0.28)));
    canvas.drawRect(box, strokePaint(color, size, width: 0.016));
    paintCaption(
      canvas,
      size,
      caption,
      rel(size, left + 0.08, 0.89),
      palette.line,
      scale: 0.07,
    );
  }
}

/// Cajón de caja con monedas y una salida para las inversiones.
class _PFcfPainter extends ThemedPainter {
  const _PFcfPainter(super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final drawer = relRect(size, 0.3, 0.42, 0.4, 0.38);
    canvas.drawRect(drawer, fillPaint(palette.soft));
    canvas.drawRect(drawer, strokePaint(palette.line, size));
    paintCoins(canvas, size, palette, rel(size, 0.4, 0.75), 3);
    paintCoins(canvas, size, palette, rel(size, 0.58, 0.75), 2);
    canvas.drawLine(
      rel(size, 0.3, 0.52),
      rel(size, 0.7, 0.52),
      strokePaint(palette.line, size),
    );
    paintArrow(
      canvas,
      size,
      palette.favorable,
      rel(size, 0.12, 0.3),
      rel(size, 0.4, 0.42),
    );
    paintCaption(
      canvas,
      size,
      'caja',
      rel(size, 0.12, 0.2),
      palette.favorable,
      scale: 0.07,
    );
    paintArrow(
      canvas,
      size,
      palette.unfavorable,
      rel(size, 0.7, 0.62),
      rel(size, 0.9, 0.62),
    );
    paintCaption(
      canvas,
      size,
      'inversión',
      rel(size, 0.82, 0.74),
      palette.unfavorable,
      scale: 0.07,
    );
    paintCaption(
      canvas,
      size,
      'lo que queda',
      rel(size, 0.5, 0.92),
      palette.line,
      scale: 0.075,
    );
  }
}

/// Un negocio nuevo con su etiqueta de precio frente a una pila de ventas.
class _PVentasPainter extends ThemedPainter {
  const _PVentasPainter(super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    paintShop(canvas, size, palette, relRect(size, 0.08, 0.28, 0.26, 0.52));
    paintCaption(
      canvas,
      size,
      'Abierto',
      rel(size, 0.21, 0.2),
      palette.line,
      scale: 0.07,
    );
    final tag = relRect(size, 0.44, 0.22, 0.22, 0.2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(tag, Radius.circular(size.height * 0.03)),
      fillPaint(palette.accent),
    );
    paintCaption(canvas, size, 'precio', tag.center, palette.line, scale: 0.08);
    paintCoins(canvas, size, palette, rel(size, 0.81, 0.78), 5);
    paintCaption(
      canvas,
      size,
      'ventas',
      rel(size, 0.81, 0.9),
      palette.line,
      scale: 0.07,
    );
    paintCaption(
      canvas,
      size,
      '÷',
      rel(size, 0.55, 0.62),
      palette.line,
      scale: 0.2,
    );
  }
}

/// Balanza: una casa en un platillo y su precio en el otro.
class _PVcPainter extends ThemedPainter {
  const _PVcPainter(super.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final line = strokePaint(palette.line, size, width: 0.016);
    canvas
      ..drawLine(rel(size, 0.5, 0.26), rel(size, 0.5, 0.8), line)
      ..drawLine(rel(size, 0.38, 0.8), rel(size, 0.62, 0.8), line)
      ..drawLine(rel(size, 0.18, 0.3), rel(size, 0.82, 0.3), line);
    _pan(canvas, size, 0.18);
    _pan(canvas, size, 0.82);
    paintCaption(
      canvas,
      size,
      'precio',
      rel(size, 0.18, 0.5),
      palette.line,
      scale: 0.075,
    );
    _house(canvas, size, rel(size, 0.82, 0.47));
    paintCaption(
      canvas,
      size,
      'patrimonio',
      rel(size, 0.82, 0.7),
      palette.line,
      scale: 0.07,
    );
  }

  void _pan(Canvas canvas, Size size, double x) {
    final line = strokePaint(palette.line, size);
    canvas
      ..drawLine(rel(size, x, 0.3), rel(size, x - 0.1, 0.56), line)
      ..drawLine(rel(size, x, 0.3), rel(size, x + 0.1, 0.56), line)
      ..drawLine(rel(size, x - 0.12, 0.56), rel(size, x + 0.12, 0.56), line);
  }

  void _house(Canvas canvas, Size size, Offset center) {
    final w = size.width * 0.1;
    final h = size.height * 0.14;
    final roof = Path()
      ..moveTo(center.dx - w, center.dy)
      ..lineTo(center.dx, center.dy - h)
      ..lineTo(center.dx + w, center.dy)
      ..close();
    canvas
      ..drawRect(
        Rect.fromLTWH(center.dx - w * 0.8, center.dy, w * 1.6, h * 0.7),
        fillPaint(palette.soft),
      )
      ..drawRect(
        Rect.fromLTWH(center.dx - w * 0.8, center.dy, w * 1.6, h * 0.7),
        strokePaint(palette.line, size),
      )
      ..drawPath(roof, fillPaint(palette.accent))
      ..drawPath(roof, strokePaint(palette.line, size));
  }
}
