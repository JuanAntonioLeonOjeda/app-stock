import 'package:flutter/widgets.dart';

typedef IllustrationBuilder = Widget Function();

/// Ilustraciones por id de métrica o concepto. Cada bloque del motor añade las
/// suyas aquí; un id sin ilustración simplemente no la muestra.
final Map<String, IllustrationBuilder> _illustrations = {};

/// La ilustración de la analogía de [id] (criterio 75), o `null` si aún no
/// tiene.
Widget? illustrationFor(String id) => _illustrations[id]?.call();
