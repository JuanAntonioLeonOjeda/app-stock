import 'package:flutter/widgets.dart';

/// Abre la explicación educativa del tema [topicId]: el id de una métrica
/// (`per`, `roic`...), de un bloque o de la guía del diagnóstico.
///
/// La aporta el composition root: esta feature no sabe de dónde sale el
/// contenido (ninguna feature importa de otra). Si es `null`, no se muestra
/// ningún icono de información.
typedef ShowInfo = void Function(BuildContext context, String topicId);
