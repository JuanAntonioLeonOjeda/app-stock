import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/contenido_educativo/domain/exceptions/educational_content_exception.dart';
import 'package:stock_app/features/contenido_educativo/infrastructure/adapters/educational_content_parser.dart';

import '../../sample_content.dart';

/// Las tres piezas del contenido de muestra como objetos, para romper una.
typedef _Parts = ({
  Map<String, Object?> metrics,
  Map<String, Object?> concepts,
  Map<String, Object?> blocks,
  Map<String, Object?> guide,
});

_Parts _parts() {
  final files = sampleFiles();
  return (
    metrics: jsonDecode(files.metrics) as Map<String, Object?>,
    concepts: jsonDecode(files.concepts) as Map<String, Object?>,
    blocks: jsonDecode(files.blocks) as Map<String, Object?>,
    guide: jsonDecode(files.guide) as Map<String, Object?>,
  );
}

Map<String, Object?> _metric(_Parts parts, int index) =>
    (parts.metrics['metricas']! as List<Object?>)[index]!
        as Map<String, Object?>;

Matcher _failsWith(String fragment) => throwsA(
  isA<InvalidContentException>().having(
    (e) => e.details,
    'details',
    contains(fragment),
  ),
);

void _parse(_Parts parts) => parseEducationalContent(
  metrics: jsonEncode(parts.metrics),
  concepts: jsonEncode(parts.concepts),
  blocks: jsonEncode(parts.blocks),
  guide: jsonEncode(parts.guide),
);

void main() {
  group('parseEducationalContent', () {
    test('convierte el contenido válido a entidades', () {
      final content = sampleContent();

      expect(content.metrics.map((m) => m.id), ['per', 'peg', 'rsi']);
      expect(content.metricById('per')?.title, 'PER 12 meses');
      expect(content.metricById('per')?.combinesWith, ['peg']);
      expect(content.blockById('bloque_tecnico')?.metricIds, ['rsi']);
      expect(content.guide.sections, hasLength(2));
      expect(content.guide.checklist, hasLength(2));
    });

    test('convierte la pregunta de comprobación', () {
      final question = sampleContent().metricById('per')!.question;

      expect(question.options, hasLength(3));
      expect(question.correctIndex, 1);
      expect(question.explanation, isNotEmpty);
    });

    test('un id que no existe devuelve null', () {
      expect(sampleContent().metricById('no_existe'), isNull);
      expect(sampleContent().blockById('no_existe'), isNull);
    });

    test('los archivos vacíos de partida son válidos', () {
      final content = parseEducationalContent(
        metrics: '{"metricas": []}',
        concepts: '{"conceptos": []}',
        blocks: '{"bloques": []}',
        guide: '{"secciones": [], "queMirar": {"titulo": "t", "introduccion": "i", "preguntas": []}}',
      );

      expect(content.metrics, isEmpty);
    });

    test('un archivo que no es JSON es inválido y nombra el archivo', () {
      expect(
        () => parseEducationalContent(
          metrics: 'no json',
          concepts: '{"conceptos": []}',
          blocks: '{"bloques": []}',
          guide: '{}',
        ),
        _failsWith('metricas.es.json'),
      );
    });

    test('un campo de texto ausente nombra la métrica y el campo', () {
      final parts = _parts();
      _metric(parts, 0).remove('intuicion');

      expect(() => _parse(parts), _failsWith('per › intuicion'));
    });

    test('un campo de texto vacío es inválido', () {
      final parts = _parts();
      _metric(parts, 1)['comoLeerla'] = '   ';

      expect(() => _parse(parts), _failsWith('peg › comoLeerla'));
    });

    test('una pregunta con menos de 3 opciones es inválida', () {
      final parts = _parts();
      (_metric(parts, 0)['pregunta']! as Map<String, Object?>)['opciones'] = [
        'a',
        'b',
      ];

      expect(() => _parse(parts), _failsWith('al menos 3'));
    });

    test('un índice correcto fuera de rango es inválido', () {
      final parts = _parts();
      (_metric(parts, 0)['pregunta']! as Map<String, Object?>)['correcta'] = 3;

      expect(() => _parse(parts), _failsWith('correcta'));
    });

    test('un índice correcto que no es entero es inválido', () {
      final parts = _parts();
      (_metric(parts, 0)['pregunta']! as Map<String, Object?>)['correcta'] =
          '1';

      expect(() => _parse(parts), _failsWith('correcta'));
    });

    test('un id de métrica repetido es inválido', () {
      final parts = _parts();
      _metric(parts, 1)['id'] = 'per';

      expect(() => _parse(parts), _failsWith('id repetido: per'));
    });

    test('combinaCon con una métrica desconocida es inválido', () {
      final parts = _parts();
      _metric(parts, 0)['combinaCon'] = ['inventada'];

      expect(() => _parse(parts), _failsWith('"inventada"'));
    });

    test('una métrica no puede combinarse consigo misma', () {
      final parts = _parts();
      _metric(parts, 0)['combinaCon'] = ['per'];

      expect(() => _parse(parts), _failsWith('combinaCon'));
    });

    test('un bloque con una métrica desconocida es inválido', () {
      final parts = _parts();
      final block =
          (parts.blocks['bloques']! as List<Object?>).first!
              as Map<String, Object?>;
      block['metricas'] = ['per', 'peg', 'fantasma'];

      expect(() => _parse(parts), _failsWith('"fantasma" no existe'));
    });

    test('una métrica en dos bloques es inválida', () {
      final parts = _parts();
      final block =
          (parts.blocks['bloques']! as List<Object?>).last!
              as Map<String, Object?>;
      block['metricas'] = ['rsi', 'per'];

      expect(() => _parse(parts), _failsWith('en dos bloques'));
    });

    test('una métrica sin bloque es inválida', () {
      final parts = _parts();
      final block =
          (parts.blocks['bloques']! as List<Object?>).last!
              as Map<String, Object?>;
      block['metricas'] = <String>[];

      expect(() => _parse(parts), _failsWith('sin bloque: rsi'));
    });

    test('la guía sin la lista de preguntas es inválida', () {
      final parts = _parts();
      (parts.guide['queMirar']! as Map<String, Object?>).remove('preguntas');

      expect(() => _parse(parts), _failsWith('guia.es.json'));
    });

    test('convierte los conceptos de la gráfica', () {
      final content = sampleContent();

      expect(content.concepts.map((c) => c.id), ['media_50', 'grafico_precio']);
      expect(
        content.explanationById('media_50')?.title,
        'Media de 50 sesiones',
      );
      expect(content.explanationById('grafico_precio')?.combinesWith, [
        'media_50',
        'rsi',
      ]);
    });

    test('un concepto no es una métrica del motor', () {
      final content = sampleContent();

      expect(content.metricById('media_50'), isNull);
      expect(content.explanationById('per')?.id, 'per');
      expect(content.explanationById('no_existe'), isNull);
    });

    test('una métrica puede combinarse con un concepto', () {
      final parts = _parts();
      _metric(parts, 0)['combinaCon'] = ['media_50'];

      expect(() => _parse(parts), returnsNormally);
    });

    test('un concepto no puede tener el id de una métrica', () {
      final parts = _parts();
      final concept =
          (parts.concepts['conceptos']! as List<Object?>).first!
              as Map<String, Object?>;
      concept['id'] = 'per';

      expect(() => _parse(parts), _failsWith('ids que ya son métricas'));
    });

    test('un concepto con combinaCon desconocido es inválido', () {
      final parts = _parts();
      final concept =
          (parts.concepts['conceptos']! as List<Object?>).first!
              as Map<String, Object?>;
      concept['combinaCon'] = ['inventada'];

      expect(() => _parse(parts), _failsWith('conceptos.es.json › media_50'));
    });

    test('un concepto incompleto nombra su archivo y el campo', () {
      final parts = _parts();
      final concept =
          (parts.concepts['conceptos']! as List<Object?>).first!
              as Map<String, Object?>;
      concept.remove('formula');

      expect(() => _parse(parts), _failsWith('conceptos.es.json'));
      expect(() => _parse(parts), _failsWith('media_50 › formula'));
    });

    test('un id de concepto repetido es inválido', () {
      final parts = _parts();
      final list = parts.concepts['conceptos']! as List<Object?>;
      (list.last! as Map<String, Object?>)['id'] = 'media_50';

      expect(() => _parse(parts), _failsWith('conceptos.es.json › conceptos'));
      expect(() => _parse(parts), _failsWith('id repetido: media_50'));
    });
  });
}
