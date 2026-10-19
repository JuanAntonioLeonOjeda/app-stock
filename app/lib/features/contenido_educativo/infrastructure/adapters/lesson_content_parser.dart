// Campos visuales de una ficha (fórmula por piezas, leyenda y actividades) →
// entidades. Todos son opcionales aquí: el test de cobertura de `app/test/`
// es quien exige que las fichas reales los tengan. Lo que sí está presente se
// valida entero, con el archivo, el `id` y el campo en el mensaje.

import 'package:stock_app/features/contenido_educativo/domain/entities/formula_diagram.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/learning_activity.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/reading_scale.dart';
import 'package:stock_app/features/contenido_educativo/infrastructure/adapters/content_reader.dart';

/// Mínimo y máximo de filas de una tabla para comparar.
const minCompareRows = 4;
const maxCompareRows = 5;

/// Rango de datos de una empresa de "detectar la trampa".
const minTrapItems = 4;
const maxTrapItems = 6;

/// Rango de elementos de "ordenar".
const minOrderItems = 3;
const maxOrderItems = 5;

const _sources = {
  'mercado': DataSource.market,
  'cuenta_resultados': DataSource.incomeStatement,
  'balance': DataSource.balanceSheet,
  'flujo_caja': DataSource.cashFlow,
  'historico_precios': DataSource.priceHistory,
};

const _tones = {
  'positivo': Tone.positive,
  'neutro': Tone.neutral,
  'negativo': Tone.negative,
};

/// La fórmula por piezas de `formulaVisual`, o `null` si la ficha no la tiene.
FormulaDiagram? parseFormulaDiagram(ContentReader item) {
  final reader = item.optionalObject('formulaVisual');
  if (reader == null) return null;
  final result = _result(reader.object('resultado'));
  return switch (reader.text('tipo')) {
    'cociente' => RatioFormula(
      numerator: _piece(reader.object('numerador')),
      denominator: _piece(reader.object('denominador')),
      result: result,
    ),
    'crecimiento' => GrowthFormula(
      initial: _piece(reader.object('inicial')),
      finalValue: _piece(reader.object('final')),
      years: _piece(reader.object('anios')),
      result: result,
    ),
    'variacion' => VariationFormula(
      current: _piece(reader.object('actual')),
      reference: _piece(reader.object('referencia')),
      result: result,
    ),
    'pasos' => StepsFormula(steps: _steps(reader), result: result),
    final other => throw reader.fail('tipo', 'desconocido: "$other"'),
  };
}

FormulaResult _result(ContentReader reader) => FormulaResult(
  name: reader.text('nombre'),
  unit: reader.has('unidad') ? reader.text('unidad') : '',
  exampleValue: reader.number('ejemplo'),
);

FormulaPiece _piece(ContentReader reader) {
  final example = reader.number('ejemplo');
  final min = reader.optionalNumber('min');
  final max = reader.optionalNumber('max');
  if ((min == null) != (max == null)) {
    throw reader.fail('min', 'min y max van juntos');
  }
  if (min != null && max != null && !(min < example && example < max)) {
    throw reader.fail('ejemplo', 'debe estar entre min y max (sin tocarlos)');
  }
  final step = reader.optionalNumber('paso');
  if (step != null && (min == null || step <= 0 || step > max! - min)) {
    throw reader.fail('paso', 'debe ser positivo y caber entre min y max');
  }
  return FormulaPiece(
    key: reader.text('clave'),
    name: reader.text('nombre'),
    source: _source(reader),
    exampleValue: example,
    unit: reader.has('unidad') ? reader.text('unidad') : '',
    min: min,
    max: max,
    step: step,
  );
}

DataSource _source(ContentReader reader) {
  final name = reader.text('origen');
  final source = _sources[name];
  if (source == null) throw reader.fail('origen', 'desconocido: "$name"');
  return source;
}

List<FormulaStep> _steps(ContentReader reader) {
  final steps = reader.list('pasos');
  if (steps.length < 2 || steps.length > 4) {
    throw reader.fail('pasos', 'se esperaban 2-4, hay ${steps.length}');
  }
  return [
    for (final step in steps)
      FormulaStep(
        name: step.text('nombre'),
        description: step.text('descripcion'),
      ),
  ];
}

/// La leyenda de una métrica sin escala; vacía si no la tiene.
List<LegendRow> parseLegend(ContentReader item) {
  final rows = item.optionalList('leyenda');
  if (rows.isEmpty) return const [];
  if (rows.length < 2 || rows.length > 4) {
    throw item.fail('leyenda', 'se esperaban 2-4 filas, hay ${rows.length}');
  }
  return [
    for (final row in rows)
      LegendRow(
        condition: row.text('condicion'),
        meaning: row.text('significado'),
        tone: _tone(row),
      ),
  ];
}

Tone _tone(ContentReader reader) {
  final name = reader.text('tono');
  final tone = _tones[name];
  if (tone == null) throw reader.fail('tono', 'desconocido: "$name"');
  return tone;
}

/// Las actividades de la ficha; vacía si no tiene. [diagram] sirve para
/// comprobar que un simulador tiene piezas que mover.
List<LearningActivity> parseActivities(
  ContentReader item,
  FormulaDiagram? diagram,
) => [
  for (final reader in item.optionalList('actividades'))
    _activity(reader, diagram),
];

LearningActivity _activity(ContentReader reader, FormulaDiagram? diagram) =>
    switch (reader.text('tipo')) {
      'simulador' => _simulator(reader, diagram),
      'trampa' => _spotTrap(reader),
      'comparar' => _compare(reader),
      'predecir' => _predict(reader),
      'ordenar' => _order(reader),
      final other => throw reader.fail('tipo', 'desconocido: "$other"'),
    };

SimulatorActivity _simulator(ContentReader reader, FormulaDiagram? diagram) {
  final adjustable = diagram?.pieces.any((p) => p.isAdjustable) ?? false;
  if (!adjustable) {
    throw reader.fail(
      'tipo',
      'un simulador necesita formulaVisual con piezas con min y max',
    );
  }
  return SimulatorActivity(prompt: reader.text('enunciado'));
}

SpotTrapActivity _spotTrap(ContentReader reader) {
  final items = reader.list('datos');
  if (items.length < minTrapItems || items.length > maxTrapItems) {
    throw reader.fail(
      'datos',
      'se esperaban $minTrapItems-$maxTrapItems, hay ${items.length}',
    );
  }
  final parsed = [
    for (final item in items)
      TrapItem(
        label: item.text('etiqueta'),
        value: item.text('valor'),
        isTrap: item.boolean('esTrampa'),
        explanation: item.text('explicacion'),
      ),
  ];
  if (parsed.where((item) => item.isTrap).length != 1) {
    throw reader.fail('datos', 'debe haber exactamente un dato con esTrampa');
  }
  return SpotTrapActivity(
    company: reader.text('empresa'),
    prompt: reader.text('enunciado'),
    items: parsed,
  );
}

CompareActivity _compare(ContentReader reader) {
  final companies = reader.textList('empresas');
  if (companies.length != 2) {
    throw reader.fail('empresas', 'se esperaban 2, hay ${companies.length}');
  }
  final rows = reader.list('filas');
  if (rows.length < minCompareRows || rows.length > maxCompareRows) {
    throw reader.fail(
      'filas',
      'se esperaban $minCompareRows-$maxCompareRows, hay ${rows.length}',
    );
  }
  final question = reader.object('pregunta');
  final correct = question.integer('correcta');
  if (correct != 0 && correct != 1) {
    throw question.fail('correcta', 'debe ser 0 o 1: $correct');
  }
  return CompareActivity(
    sector: reader.text('sector'),
    companyA: companies[0],
    companyB: companies[1],
    rows: [
      for (final row in rows)
        CompareRow(
          label: row.text('etiqueta'),
          a: row.text('a'),
          b: row.text('b'),
        ),
    ],
    question: question.text('texto'),
    correctIsA: correct == 0,
    explanation: question.text('explicacion'),
  );
}

PredictActivity _predict(ContentReader reader) {
  final options = reader.textList('opciones');
  if (options.length < 2) {
    throw reader.fail('opciones', 'se esperaban al menos 2');
  }
  final correct = reader.integer('correcta');
  if (correct < 0 || correct >= options.length) {
    throw reader.fail('correcta', 'fuera de rango: $correct');
  }
  return PredictActivity(
    text: reader.text('texto'),
    options: options,
    correctIndex: correct,
    explanation: reader.text('explicacion'),
    reveal: reader.text('revelacion'),
  );
}

OrderActivity _order(ContentReader reader) {
  final items = reader.list('elementos');
  if (items.length < minOrderItems || items.length > maxOrderItems) {
    throw reader.fail(
      'elementos',
      'se esperaban $minOrderItems-$maxOrderItems, hay ${items.length}',
    );
  }
  final parsed = [
    for (final item in items)
      OrderItem(
        name: item.text('nombre'),
        value: item.number('valor'),
        shown: item.text('mostrar'),
      ),
  ];
  if (parsed.map((item) => item.value).toSet().length != parsed.length) {
    throw reader.fail('elementos', 'los valores deben ser todos distintos');
  }
  return OrderActivity(
    prompt: reader.text('enunciado'),
    items: parsed,
    explanation: reader.text('explicacion'),
  );
}
