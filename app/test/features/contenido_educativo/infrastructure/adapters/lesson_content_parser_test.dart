import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/formula_diagram.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/learning_activity.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/reading_scale.dart';
import 'package:stock_app/features/contenido_educativo/domain/exceptions/educational_content_exception.dart';
import 'package:stock_app/features/contenido_educativo/infrastructure/adapters/content_reader.dart';
import 'package:stock_app/features/contenido_educativo/infrastructure/adapters/lesson_content_parser.dart';

import '../../sample_content.dart';

ContentReader _item(Map<String, Object?> fields) =>
    ContentReader.root('metricas.es.json', jsonEncode(fields)).under('per');

Matcher _failsWith(String fragment) => throwsA(
  isA<InvalidContentException>().having(
    (e) => e.details,
    'details',
    contains(fragment),
  ),
);

FormulaDiagram? _diagram(Map<String, Object?> json) =>
    parseFormulaDiagram(_item({'formulaVisual': json}));

List<LearningActivity> _activities(
  List<Map<String, Object?>> json, {
  FormulaDiagram? diagram,
}) => parseActivities(_item({'actividades': json}), diagram);

void main() {
  group('parseFormulaDiagram', () {
    test('sin formulaVisual devuelve null', () {
      expect(parseFormulaDiagram(_item({})), isNull);
    });

    test('convierte un cociente con sus piezas y su origen', () {
      final diagram = _diagram(ratioFormulaJson());

      expect(diagram, isA<RatioFormula>());
      final ratio = diagram! as RatioFormula;
      expect(ratio.numerator.source, DataSource.market);
      expect(ratio.denominator.source, DataSource.incomeStatement);
      expect(ratio.numerator.isAdjustable, isTrue);
      expect(ratio.result.unit, 'x');
    });

    test('convierte un crecimiento con sus tres piezas', () {
      final diagram = _diagram({
        'tipo': 'crecimiento',
        'inicial': pieceJson('inicial', 100),
        'final': pieceJson('final', 121),
        'anios': pieceJson('anios', 2),
        'resultado': {'nombre': 'CAGR', 'unidad': '%', 'ejemplo': 0.1},
      });

      expect((diagram! as GrowthFormula).pieces, hasLength(3));
    });

    test('convierte una fórmula por pasos', () {
      final diagram = _diagram({
        'tipo': 'pasos',
        'pasos': [
          {'nombre': 'Subidas', 'descripcion': 'Media de subidas.'},
          {'nombre': 'Bajadas', 'descripcion': 'Media de bajadas.'},
        ],
        'resultado': {'nombre': 'RSI', 'ejemplo': 50},
      });

      expect((diagram! as StepsFormula).steps, hasLength(2));
    });

    test('un tipo desconocido falla indicando el campo', () {
      final json = ratioFormulaJson()..['tipo'] = 'raro';

      expect(() => _diagram(json), _failsWith('formulaVisual › tipo'));
    });

    test('un origen desconocido falla', () {
      final json = ratioFormulaJson();
      (json['numerador']! as Map<String, Object?>)['origen'] = 'rumores';

      expect(() => _diagram(json), _failsWith('origen'));
    });

    test('un ejemplo fuera de min y max falla', () {
      final json = ratioFormulaJson();
      (json['numerador']! as Map<String, Object?>)['ejemplo'] = 500;

      expect(() => _diagram(json), _failsWith('entre min y max'));
    });

    test('min sin max falla', () {
      final json = ratioFormulaJson();
      (json['numerador']! as Map<String, Object?>).remove('max');

      expect(() => _diagram(json), _failsWith('min y max van juntos'));
    });

    test('una fórmula por pasos con un solo paso falla', () {
      expect(
        () => _diagram({
          'tipo': 'pasos',
          'pasos': [
            {'nombre': 'a', 'descripcion': 'b'},
          ],
          'resultado': {'nombre': 'R', 'ejemplo': 1},
        }),
        _failsWith('2-4'),
      );
    });
  });

  group('parseLegend', () {
    Map<String, Object?> row(String tone) => {
      'condicion': 'Si el histograma es positivo',
      'significado': 'El impulso es alcista.',
      'tono': tone,
    };

    test('sin leyenda devuelve una lista vacía', () {
      expect(parseLegend(_item({})), isEmpty);
    });

    test('convierte las filas con su tono', () {
      final legend = parseLegend(
        _item({
          'leyenda': [row('positivo'), row('negativo')],
        }),
      );

      expect(legend.map((r) => r.tone), [Tone.positive, Tone.negative]);
    });

    test('una fila con tono desconocido falla', () {
      expect(
        () => parseLegend(
          _item({
            'leyenda': [row('positivo'), row('morado')],
          }),
        ),
        _failsWith('tono'),
      );
    });

    test('una leyenda de una sola fila falla', () {
      expect(
        () => parseLegend(
          _item({
            'leyenda': [row('positivo')],
          }),
        ),
        _failsWith('2-4 filas'),
      );
    });
  });

  group('parseActivities', () {
    test('sin actividades devuelve una lista vacía', () {
      expect(parseActivities(_item({}), null), isEmpty);
    });

    test('convierte cada uno de los cinco tipos', () {
      final diagram = _diagram(ratioFormulaJson());

      final activities = _activities([
        {'tipo': 'simulador', 'enunciado': 'Mueve el precio.'},
        trapActivityJson(),
        compareActivityJson(),
        predictActivityJson(),
        orderActivityJson(),
      ], diagram: diagram);

      expect(activities.map((a) => a.runtimeType), [
        SimulatorActivity,
        SpotTrapActivity,
        CompareActivity,
        PredictActivity,
        OrderActivity,
      ]);
    });

    test('un tipo de actividad desconocido falla', () {
      expect(
        () => _activities([
          {'tipo': 'baile'},
        ]),
        _failsWith('desconocido'),
      );
    });

    test('un simulador sin piezas movibles falla', () {
      expect(
        () => _activities([
          {'tipo': 'simulador', 'enunciado': 'Mueve.'},
        ]),
        _failsWith('simulador'),
      );
    });

    test('un simulador sobre una fórmula por pasos falla', () {
      final steps = _diagram({
        'tipo': 'pasos',
        'pasos': [
          {'nombre': 'a', 'descripcion': 'b'},
          {'nombre': 'c', 'descripcion': 'd'},
        ],
        'resultado': {'nombre': 'R', 'ejemplo': 1},
      });

      expect(
        () => _activities([
          {'tipo': 'simulador', 'enunciado': 'Mueve.'},
        ], diagram: steps),
        _failsWith('simulador'),
      );
    });

    test('detectar la trampa sin ningún dato trampa falla', () {
      final json = trapActivityJson();
      for (final item in json['datos']! as List<Object?>) {
        (item! as Map<String, Object?>)['esTrampa'] = false;
      }

      expect(() => _activities([json]), _failsWith('exactamente un dato'));
    });

    test('detectar la trampa con dos datos trampa falla', () {
      final json = trapActivityJson();
      final items = json['datos']! as List<Object?>;
      (items[0]! as Map<String, Object?>)['esTrampa'] = true;

      expect(() => _activities([json]), _failsWith('exactamente un dato'));
    });

    test('detectar la trampa con pocos datos falla', () {
      final json = trapActivityJson();
      (json['datos']! as List<Object?>).removeLast();

      expect(() => _activities([json]), _failsWith('datos'));
    });

    test('comparar con una respuesta que no es 0 ni 1 falla', () {
      final json = compareActivityJson();
      (json['pregunta']! as Map<String, Object?>)['correcta'] = 2;

      expect(() => _activities([json]), _failsWith('0 o 1'));
    });

    test('comparar con tres empresas falla', () {
      final json = compareActivityJson()..['empresas'] = ['A', 'B', 'C'];

      expect(() => _activities([json]), _failsWith('empresas'));
    });

    test('predecir con una opción correcta fuera de rango falla', () {
      final json = predictActivityJson()..['correcta'] = 5;

      expect(() => _activities([json]), _failsWith('fuera de rango'));
    });

    test('ordenar con valores repetidos falla', () {
      final json = orderActivityJson();
      final items = json['elementos']! as List<Object?>;
      (items[1]! as Map<String, Object?>)['valor'] = 8;

      expect(() => _activities([json]), _failsWith('distintos'));
    });

    test('ordenar con dos elementos falla', () {
      final json = orderActivityJson();
      (json['elementos']! as List<Object?>).removeLast();

      expect(() => _activities([json]), _failsWith('elementos'));
    });

    test('el mensaje de error incluye el archivo y el id de la ficha', () {
      final json = predictActivityJson()..['correcta'] = 5;

      expect(
        () => _activities([json]),
        _failsWith('metricas.es.json › per › actividades[0]'),
      );
    });
  });
}
