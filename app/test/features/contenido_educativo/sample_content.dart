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

/// Contenido válido: `per` y `peg` en valoración, `rsi` en técnico, y los
/// conceptos `media_50` y `grafico_precio`.
({String metrics, String concepts, String blocks, String guide})
sampleFiles() => (
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
  concepts: jsonEncode({
    'conceptos': [
      metricJson(
        'media_50',
        title: 'Media de 50 sesiones',
        summary: 'El precio medio de los últimos 50 días.',
        combinaCon: ['per'],
      ),
      metricJson(
        'grafico_precio',
        title: 'Cómo leer la gráfica',
        summary: 'La evolución del precio de cierre.',
        combinaCon: ['media_50', 'rsi'],
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
    concepts: files.concepts,
    blocks: files.blocks,
    guide: files.guide,
  );
}

/// Pieza de fórmula válida; `min` y `max` hacen que el simulador pueda moverla.
Map<String, Object?> pieceJson(
  String key,
  num example, {
  num? min,
  num? max,
  String source = 'mercado',
}) => {
  'clave': key,
  'nombre': 'Pieza $key',
  'origen': source,
  'ejemplo': example,
  'min': ?min,
  'max': ?max,
};

/// `formulaVisual` de un cociente: 30 ÷ 2 = 15, con las dos piezas movibles.
Map<String, Object?> ratioFormulaJson() => {
  'tipo': 'cociente',
  'numerador': pieceJson('precio', 30, min: 5, max: 100),
  'denominador': pieceJson(
    'beneficio',
    2,
    min: 0.5,
    max: 10,
    source: 'cuenta_resultados',
  ),
  'resultado': {'nombre': 'PER', 'unidad': 'x', 'ejemplo': 15},
};

Map<String, Object?> trapActivityJson() => {
  'tipo': 'trampa',
  'empresa': 'Muebles Norte (inventada)',
  'enunciado': '¿Qué dato engaña?',
  'datos': [
    for (var i = 0; i < 4; i++)
      {
        'etiqueta': 'Dato $i',
        'valor': '$i',
        'esTrampa': i == 2,
        'explicacion': 'Explicación del dato $i.',
      },
  ],
};

Map<String, Object?> compareActivityJson() => {
  'tipo': 'comparar',
  'sector': 'Muebles',
  'empresas': ['Norte', 'Sur'],
  'filas': [
    for (var i = 0; i < 4; i++) {'etiqueta': 'Fila $i', 'a': '1', 'b': '2'},
  ],
  'pregunta': {
    'texto': '¿Cuál aguanta mejor su deuda?',
    'correcta': 1,
    'explicacion': 'Porque debe menos años de beneficio.',
  },
};

Map<String, Object?> predictActivityJson() => {
  'tipo': 'predecir',
  'texto': '¿Margen alto o bajo?',
  'opciones': ['Alto', 'Bajo'],
  'correcta': 1,
  'explicacion': 'Vende mucho con poco margen.',
  'revelacion': 'Suelen quedar en torno al 3 %.',
};

Map<String, Object?> orderActivityJson() => {
  'tipo': 'ordenar',
  'enunciado': 'Ordénalas de menor a mayor PER.',
  'elementos': [
    {'nombre': 'A', 'valor': 8, 'mostrar': '8x'},
    {'nombre': 'B', 'valor': 15, 'mostrar': '15x'},
    {'nombre': 'C', 'valor': 30, 'mostrar': '30x'},
  ],
  'explicacion': 'El PER mide años de beneficio.',
};
