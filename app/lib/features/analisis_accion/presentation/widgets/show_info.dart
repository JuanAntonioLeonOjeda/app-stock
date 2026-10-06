import 'package:flutter/widgets.dart';

/// Abre aparte la explicación educativa del tema [topicId]: la guía del
/// diagnóstico (pantalla completa) o una métrica (hoja inferior).
///
/// La explicación de una métrica o un bloque en su propia fila no usa esto:
/// se construye con `InfoBuilder`.
///
/// La aporta el composition root: esta feature no sabe de dónde sale el
/// contenido (ninguna feature importa de otra). Si es `null`, no se muestra el
/// botón de la guía.
typedef ShowInfo = void Function(BuildContext context, String topicId);
