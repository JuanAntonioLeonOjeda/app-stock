// JSON de contenido → entidades del dominio. Las claves del JSON van en
// español (`titulo`, `comoLeerla`...) porque son datos de contenido, como
// pide la skill contenido-educativo; aquí se convierten a campos en inglés.
// Cualquier incumplimiento del formato es un `InvalidContentException` con
// el archivo y el campo, para que un error de contenido salte en los tests y
// nunca llegue a la pantalla a medias.

import 'package:stock_app/features/contenido_educativo/domain/entities/block_content.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/check_question.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/diagnosis_guide.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/educational_content.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/metric_content.dart';
import 'package:stock_app/features/contenido_educativo/domain/exceptions/educational_content_exception.dart';
import 'package:stock_app/features/contenido_educativo/infrastructure/adapters/content_reader.dart';
import 'package:stock_app/features/contenido_educativo/infrastructure/adapters/lesson_content_parser.dart';

/// Mínimo de opciones de una pregunta de comprobación.
const minQuestionOptions = 3;

const _metricsFile = 'metricas.es.json';
const _conceptsFile = 'conceptos.es.json';
const _blocksFile = 'bloques.es.json';
const _guideFile = 'guia.es.json';

/// Todo el contenido a partir del texto de los tres archivos.
EducationalContent parseEducationalContent({
  required String metrics,
  required String concepts,
  required String blocks,
  required String guide,
}) {
  final parsedMetrics = _metrics(ContentReader.root(_metricsFile, metrics));
  final parsedConcepts = _concepts(ContentReader.root(_conceptsFile, concepts));
  final parsedBlocks = _blocks(ContentReader.root(_blocksFile, blocks));
  final parsedGuide = _guide(ContentReader.root(_guideFile, guide));
  _checkReferences(parsedMetrics, parsedConcepts, parsedBlocks);
  return EducationalContent(
    metrics: parsedMetrics,
    concepts: parsedConcepts,
    blocks: parsedBlocks,
    guide: parsedGuide,
  );
}

/// Los conceptos de la gráfica: misma estructura que una métrica, otro archivo.
List<MetricContent> _concepts(ContentReader root) {
  final items = root.list('conceptos');
  final seen = <String>{};
  return [for (final item in items) _metric(root, item, seen, 'conceptos')];
}

List<MetricContent> _metrics(ContentReader root) {
  final items = root.list('metricas');
  final seen = <String>{};
  return [for (final item in items) _metric(root, item, seen, 'metricas')];
}

MetricContent _metric(
  ContentReader root,
  ContentReader item,
  Set<String> seen,
  String listName,
) {
  final id = item.text('id');
  if (!seen.add(id)) throw root.fail(listName, 'id repetido: $id');
  final reader = item.under(id);
  final diagram = parseFormulaDiagram(reader);
  return MetricContent(
    id: id,
    title: reader.text('titulo'),
    summary: reader.text('resumen'),
    intuition: reader.text('intuicion'),
    formula: reader.text('formula'),
    example: reader.text('ejemplo'),
    howToRead: reader.text('comoLeerla'),
    whenItMisleads: reader.textOrList('cuandoEngana'),
    combinesWith: reader.textList('combinaCon'),
    question: _question(reader.object('pregunta')),
    formulaDiagram: diagram,
    legend: parseLegend(reader),
    activities: parseActivities(reader, diagram),
  );
}

CheckQuestion _question(ContentReader reader) {
  final options = reader.textList('opciones');
  if (options.length < minQuestionOptions) {
    throw reader.fail(
      'opciones',
      'se esperaban al menos $minQuestionOptions, hay ${options.length}',
    );
  }
  final correct = reader.integer('correcta');
  if (correct < 0 || correct >= options.length) {
    throw reader.fail('correcta', 'fuera de rango: $correct');
  }
  return CheckQuestion(
    text: reader.text('texto'),
    options: options,
    correctIndex: correct,
    explanation: reader.text('explicacion'),
  );
}

List<BlockContent> _blocks(ContentReader root) {
  final items = root.list('bloques');
  final seen = <String>{};
  return [for (final item in items) _block(root, item, seen)];
}

BlockContent _block(ContentReader root, ContentReader item, Set<String> seen) {
  final id = item.text('id');
  if (!seen.add(id)) throw root.fail('bloques', 'id repetido: $id');
  final reader = item.under(id);
  return BlockContent(
    id: id,
    title: reader.text('titulo'),
    summary: reader.text('resumen'),
    answers: reader.text('responde'),
    metricIds: reader.textList('metricas'),
    howToUse: reader.text('comoUsarlo'),
  );
}

DiagnosisGuide _guide(ContentReader root) {
  final checklist = root.object('queMirar');
  return DiagnosisGuide(
    sections: [
      for (final section in root.list('secciones'))
        GuideSection(
          title: section.text('titulo'),
          body: section.text('texto'),
        ),
    ],
    checklistTitle: checklist.text('titulo'),
    checklistIntro: checklist.text('introduccion'),
    checklist: checklist.textList('preguntas'),
  );
}

/// Referencias entre archivos: `combinaCon` y las métricas de cada bloque deben
/// existir, y toda métrica debe estar en un bloque (si no, el glosario la
/// ocultaría).
void _checkReferences(
  List<MetricContent> metrics,
  List<MetricContent> concepts,
  List<BlockContent> blocks,
) {
  final ids = {for (final metric in metrics) metric.id};
  final conceptIds = {for (final concept in concepts) concept.id};
  final clash = ids.intersection(conceptIds);
  if (clash.isNotEmpty) {
    throw InvalidContentException(
      '$_conceptsFile: ids que ya son métricas del motor: ${clash.join(', ')}',
    );
  }
  // `combinaCon` puede apuntar a una métrica o a un concepto.
  final explainable = {...ids, ...conceptIds};
  for (final entry in [
    for (final metric in metrics) (_metricsFile, metric),
    for (final concept in concepts) (_conceptsFile, concept),
  ]) {
    final (file, item) = entry;
    for (final related in item.combinesWith) {
      if (related == item.id || !explainable.contains(related)) {
        throw InvalidContentException(
          '$file › ${item.id} › combinaCon: "$related" no es otra '
          'explicación existente',
        );
      }
    }
  }
  final inBlocks = <String>{};
  for (final block in blocks) {
    for (final id in block.metricIds) {
      if (!ids.contains(id)) {
        throw InvalidContentException(
          '$_blocksFile › ${block.id} › metricas: "$id" no existe',
        );
      }
      if (!inBlocks.add(id)) {
        throw InvalidContentException(
          '$_blocksFile › ${block.id} › metricas: "$id" está en dos bloques',
        );
      }
    }
  }
  final orphans = ids.difference(inBlocks);
  if (orphans.isNotEmpty) {
    throw InvalidContentException(
      '$_blocksFile: métricas sin bloque: ${orphans.join(', ')}',
    );
  }
}
