import 'package:flutter/widgets.dart';
import 'package:stock_app/features/contenido_educativo/presentation/illustrations/growth_illustrations.dart';
import 'package:stock_app/features/contenido_educativo/presentation/illustrations/health_illustrations.dart';
import 'package:stock_app/features/contenido_educativo/presentation/illustrations/illustration_canvas.dart';
import 'package:stock_app/features/contenido_educativo/presentation/illustrations/valuation_illustrations.dart';

/// Ilustraciones por id de métrica o concepto. Cada bloque del motor añade las
/// suyas aquí; un id sin ilustración simplemente no la muestra.
final Map<String, IllustrationBuilder> _illustrations = {
  ...valuationIllustrations,
  ...healthIllustrations,
  ...growthIllustrations,
};

/// La ilustración de la analogía de [id] (criterio 75), o `null` si aún no
/// tiene.
Widget? illustrationFor(String id) => _illustrations[id]?.call();
