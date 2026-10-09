import 'package:flutter/widgets.dart';

/// Construye la explicación educativa del tema [topicId] (el id de una métrica
/// o de un bloque) para mostrarla en el sitio, debajo del dato.
///
/// La aporta el composition root: esta feature no sabe de dónde sale el
/// contenido (ninguna feature importa de otra). Si es `null`, no se muestra
/// ningún icono de información.
typedef InfoBuilder = Widget Function(BuildContext context, String topicId);
