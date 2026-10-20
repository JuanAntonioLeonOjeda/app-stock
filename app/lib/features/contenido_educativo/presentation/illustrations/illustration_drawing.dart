import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:stock_app/features/contenido_educativo/presentation/illustrations/illustration_canvas.dart';

/// Trazo común a todas las ilustraciones: línea redondeada y sin relleno.
Paint strokePaint(Color color, Size size, {double width = 0.012}) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = size.height * width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

Paint fillPaint(Color color) => Paint()..color = color;

/// Rectángulo en coordenadas relativas (0-1) al tamaño del lienzo.
Rect relRect(Size size, double left, double top, double width, double height) =>
    Rect.fromLTWH(
      size.width * left,
      size.height * top,
      size.width * width,
      size.height * height,
    );

Offset rel(Size size, double x, double y) =>
    Offset(size.width * x, size.height * y);

/// Texto corto centrado en [center]; las ilustraciones solo rotulan cifras.
void paintCaption(
  Canvas canvas,
  Size size,
  String text,
  Offset center,
  Color color, {
  double scale = 0.09,
  FontWeight weight = FontWeight.w600,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: size.height * scale,
        fontWeight: weight,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
}

/// Un edificio con toldo, para «un negocio».
void paintShop(Canvas canvas, Size size, IllustrationPalette p, Rect box) {
  final body = Rect.fromLTWH(
    box.left,
    box.top + box.height * 0.35,
    box.width,
    box.height * 0.65,
  );
  canvas.drawRect(body, fillPaint(p.soft));
  canvas.drawRect(body, strokePaint(p.line, size));
  final awning = Path()
    ..moveTo(box.left - box.width * 0.08, body.top)
    ..lineTo(box.left + box.width * 0.1, box.top)
    ..lineTo(box.right - box.width * 0.1, box.top)
    ..lineTo(box.right + box.width * 0.08, body.top)
    ..close();
  canvas.drawPath(awning, fillPaint(p.accent));
  canvas.drawPath(awning, strokePaint(p.line, size));
  final door = Rect.fromLTWH(
    box.center.dx - box.width * 0.12,
    body.top + body.height * 0.35,
    box.width * 0.24,
    body.height * 0.65,
  );
  canvas.drawRect(door, strokePaint(p.line, size));
}

/// Pila de monedas.
void paintCoins(
  Canvas canvas,
  Size size,
  IllustrationPalette p,
  Offset base,
  int count,
) {
  final radius = size.height * 0.06;
  for (var i = 0; i < count; i++) {
    final center = base - Offset(0, i * radius * 0.7);
    final coin = Rect.fromCenter(
      center: center,
      width: radius * 2.2,
      height: radius * 0.9,
    );
    canvas.drawOval(coin, fillPaint(p.accent));
    canvas.drawOval(coin, strokePaint(p.line, size, width: 0.008));
  }
}

/// Flecha de [from] a [to].
void paintArrow(Canvas canvas, Size size, Color color, Offset from, Offset to) {
  final paint = strokePaint(color, size, width: 0.014);
  canvas.drawLine(from, to, paint);
  final direction = (to - from) / (to - from).distance;
  final normal = Offset(-direction.dy, direction.dx);
  final head = size.height * 0.05;
  canvas
    ..drawLine(to, to - direction * head + normal * head * 0.6, paint)
    ..drawLine(to, to - direction * head - normal * head * 0.6, paint);
}

/// Tarta de [slices] porciones iguales con [highlighted] resaltadas; sirve
/// para «tu parte» de un negocio.
void paintPie(
  Canvas canvas,
  Size size,
  IllustrationPalette p,
  Offset center,
  double radius, {
  required int slices,
  int highlighted = 1,
}) {
  final circle = Rect.fromCircle(center: center, radius: radius);
  final sweep = 2 * math.pi / slices;
  for (var i = 0; i < slices; i++) {
    final color = i < highlighted ? p.accent : p.soft;
    canvas.drawArc(
      circle,
      -math.pi / 2 + i * sweep,
      sweep,
      true,
      fillPaint(color),
    );
  }
  final line = strokePaint(p.line, size);
  canvas.drawCircle(center, radius, line);
  for (var i = 0; i < slices; i++) {
    final angle = -math.pi / 2 + i * sweep;
    canvas.drawLine(
      center,
      center + Offset(math.cos(angle), math.sin(angle)) * radius,
      line,
    );
  }
}

/// Barra vertical rellena con su contorno, anclada por abajo en [baseY].
void paintBar(
  Canvas canvas,
  Size size,
  Color color,
  double left,
  double width,
  double height,
  double baseY,
) {
  final bar = Rect.fromLTWH(left, baseY - height, width, height);
  canvas.drawRect(bar, fillPaint(color.withValues(alpha: 0.3)));
  canvas.drawRect(bar, strokePaint(color, size, width: 0.014));
}

/// Línea discontinua de [from] a [to].
void paintDashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
  const dashes = 14;
  final step = (to - from) / dashes.toDouble();
  for (var i = 0; i < dashes; i += 2) {
    canvas.drawLine(
      from + step * i.toDouble(),
      from + step * (i + 1).toDouble(),
      paint,
    );
  }
}
