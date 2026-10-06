import 'dart:convert';

import 'package:stock_app/features/contenido_educativo/domain/entities/educational_content.dart';
import 'package:stock_app/features/contenido_educativo/infrastructure/adapters/educational_content_parser.dart';

/// JSON de una ficha de métrica válida; los tests rompen un campo a la vez.
Map<String, Object?> metricJson(
  String id, {
  String title = 'Título',
  String summary = 'Resumen de la métrica.',
  List<String> combinaCon = const [],
}) => {
  'id': id,
  'titulo': title,
  'resumen': summary,
  'intuicion': 'Una analogía cotidiana.',
  'formula': 'Precio entre beneficio, del balance y la cuenta de resultados.',
  'ejemplo': 'Ejemplo inventado con cifras redondas.',
  'comoLeerla': 'Orientación sobre valores altos y bajos.',
  'cuandoEngana': 'Una trampa típica.',
  'combinaCon': combinaCon,
  'pregunta': {
    'texto': '¿Qué mide?',
    'opciones': ['Una cosa', 'Otra cosa', 'Una tercera'],
    'correcta': 1,
    'explicacion': 'Porque sí mide otra cosa.',
  },
};

Map<String, Object?> blockJson(String id, List<String> metricIds) => {
  'id': id,
  'titulo': 'Bloque $id',
  'resumen': 'Resumen del bloque.',
  'responde': '¿Una pregunta?',
  'metricas': metricIds,
  'comoUsarlo': 'Cómo usarlo.',
};

Map<String, Object?> guideJson() => {
  'secciones': [
    {'titulo': 'Veredicto', 'texto': 'Qué significa el veredicto.'},
    {'titulo': 'Confianza', 'texto': 'Qué significa la confianza.'},
  ],
  'queMirar': {
    'titulo': 'Qué mirar antes de invertir',
    'introduccion': 'Preguntas para hacerse.',
    'preguntas': ['¿Entiendo el negocio?', '¿Es dinero que no necesitaré?'],
  },
};

/// Contenido válido: `per` y `peg` en valoración, `rsi` en técnico.
({String metrics, String blocks, String guide}) sampleFiles() => (
  metrics: jsonEncode({
    'metricas': [
      metricJson(
        'per',
        title: 'PER 12 meses',
        summary: 'Cuántos años de beneficio pagas.',
        combinaCon: ['peg'],
      ),
      metricJson(
        'peg',
        title: 'PEG',
        summary: 'El PER ajustado por crecimiento.',
        combinaCon: ['per'],
      ),
      metricJson(
        'rsi',
        title: 'RSI',
        summary: 'Si el precio ha subido o bajado muy rápido.',
      ),
    ],
  }),
  blocks: jsonEncode({
    'bloques': [
      blockJson('bloque_valoracion', ['per', 'peg']),
      blockJson('bloque_tecnico', ['rsi']),
    ],
  }),
  guide: jsonEncode(guideJson()),
);

EducationalContent sampleContent() {
  final files = sampleFiles();
  return parseEducationalContent(
    metrics: files.metrics,
    blocks: files.blocks,
    guide: files.guide,
  );
}
