// Comprueba el contenido educativo REAL contra el motor de análisis. Importa
// de dos features, así que vive fuera de ambas (las features no se importan
// entre sí; ver .claude/rules/hexagonal-architecture.md).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/composition/motor_metric_scale_adapter.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/rules/metric_rules.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/labels.dart';
import 'package:stock_app/features/contenido_educativo/domain/content/formula_evaluation.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/educational_content.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/formula_diagram.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/learning_activity.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/metric_content.dart';
import 'package:stock_app/features/contenido_educativo/infrastructure/adapters/educational_content_parser.dart';
import 'package:stock_app/features/contenido_educativo/presentation/illustrations/illustration_for.dart';

/// Frases que convertirían una explicación en una recomendación (criterio 17).
const _recommendationPhrases = [
  'buena compra',
  'mala compra',
  'compra ya',
  'vende ya',
  'te recomendamos',
  'te recomiendo',
  'deberías comprar',
  'deberías vender',
  'debes comprar',
  'debes vender',
  'es el momento de comprar',
  'es el momento de vender',
];

/// Empresas reales que no deben aparecer en ejemplos estáticos (criterio 4):
/// sus cifras se quedarían desactualizadas.
const _realCompanies = [
  'apple',
  'nintendo',
  'inditex',
  'iberdrola',
  'fast retailing',
  'tesla',
  'amazon',
  'microsoft',
  'google',
  'santander',
  'bbva',
  'telefónica',
  'repsol',
  'nvidia',
  'meta ',
];

EducationalContent _realContent() {
  String read(String name) =>
      File('assets/contenido/$name.es.json').readAsStringSync();
  return parseEducationalContent(
    metrics: read('metricas'),
    concepts: read('conceptos'),
    blocks: read('bloques'),
    guide: read('guia'),
  );
}

/// Máximo de palabras de un texto que ocupa una tarjeta (criterio 74).
const _maxCardWords = 60;

int _words(String text) => text.trim().split(RegExp(r'\s+')).length;

/// Textos de una actividad, para las comprobaciones de estilo.
List<String> _activityTexts(LearningActivity activity) => switch (activity) {
  SimulatorActivity() => [activity.prompt],
  SpotTrapActivity() => [
    activity.company,
    activity.prompt,
    for (final item in activity.items) ...[
      item.label,
      item.value,
      item.explanation,
    ],
  ],
  CompareActivity() => [
    activity.sector,
    activity.companyA,
    activity.companyB,
    activity.question,
    activity.explanation,
    for (final row in activity.rows) ...[row.label, row.a, row.b],
  ],
  PredictActivity() => [
    activity.text,
    ...activity.options,
    activity.explanation,
    activity.reveal,
  ],
  OrderActivity() => [
    activity.prompt,
    activity.explanation,
    for (final item in activity.items) ...[item.name, item.shown],
  ],
};

/// Textos del formato visual de una ficha: fórmula por piezas, leyenda y
/// actividades.
List<String> _visualTexts(MetricContent metric) => [
  if (metric.formulaDiagram case final diagram?) ...[
    diagram.result.name,
    for (final piece in diagram.pieces) piece.name,
    if (diagram case StepsFormula(:final steps))
      for (final step in steps) ...[step.name, step.description],
  ],
  for (final row in metric.legend) ...[row.condition, row.meaning],
  for (final activity in metric.activities) ..._activityTexts(activity),
];

/// Todos los textos del contenido, para las comprobaciones de estilo.
List<String> _allTexts(EducationalContent content) => [
  for (final metric in [...content.metrics, ...content.concepts]) ...[
    metric.title,
    metric.summary,
    metric.intuition,
    metric.formula,
    metric.example,
    metric.howToRead,
    ...metric.whenItMisleads,
    metric.question.text,
    ...metric.question.options,
    metric.question.explanation,
    ..._visualTexts(metric),
  ],
  for (final block in content.blocks) ...[
    block.title,
    block.summary,
    block.answers,
    block.howToUse,
  ],
  for (final section in content.guide.sections) ...[
    section.title,
    section.body,
  ],
  content.guide.checklistTitle,
  content.guide.checklistIntro,
  ...content.guide.checklist,
];

void main() {
  final content = _realContent();

  group('contenido educativo real', () {
    test('hay una ficha por cada métrica del motor y ninguna de más', () {
      final motorIds = {for (final rule in metricRules) rule.id};
      final contentIds = {for (final metric in content.metrics) metric.id};

      expect(contentIds.difference(motorIds), isEmpty, reason: 'fichas de más');
      expect(motorIds.difference(contentIds), isEmpty, reason: 'faltan fichas');
    });

    test('cada bloque del motor tiene su ficha con sus métricas en orden', () {
      for (final block in Block.values) {
        final blockContent = content.blockById(blockTopicId(block));
        expect(blockContent, isNotNull, reason: '$block sin ficha de bloque');
        final motorIds = [
          for (final rule in metricRules)
            if (rule.block == block) rule.id,
        ];
        expect(blockContent!.metricIds, motorIds, reason: '$block');
      }
    });

    test('no hay fichas de bloque que el motor no tenga', () {
      expect(content.blocks, hasLength(Block.values.length));
    });

    test('la guía tiene secciones y la lista de preguntas', () {
      expect(content.guide.sections, isNotEmpty);
      expect(content.guide.checklist.length, greaterThanOrEqualTo(5));
    });

    test('cada pregunta tiene al menos 3 opciones y un índice válido', () {
      for (final metric in [...content.metrics, ...content.concepts]) {
        final question = metric.question;
        expect(
          question.options.length,
          greaterThanOrEqualTo(3),
          reason: metric.id,
        );
        expect(
          question.correctIndex,
          inInclusiveRange(0, question.options.length - 1),
          reason: metric.id,
        );
      }
    });

    test('la respuesta correcta no está siempre en la misma posición', () {
      final positions = {
        for (final metric in content.metrics) metric.question.correctIndex,
      };

      expect(positions.length, greaterThan(1));
    });

    test(
      'cada métrica y cada concepto se combina con al menos otra explicación',
      () {
        for (final metric in [...content.metrics, ...content.concepts]) {
          expect(metric.combinesWith, isNotEmpty, reason: metric.id);
        }
      },
    );

    test('ningún texto contiene frases de recomendación', () {
      for (final text in _allTexts(content)) {
        final lower = text.toLowerCase();
        for (final phrase in _recommendationPhrases) {
          expect(
            lower.contains(phrase),
            isFalse,
            reason: '"$phrase" en: $text',
          );
        }
      }
    });

    test('los ejemplos no usan empresas reales', () {
      for (final metric in [...content.metrics, ...content.concepts]) {
        final example = metric.example.toLowerCase();
        for (final company in _realCompanies) {
          expect(
            example.contains(company),
            isFalse,
            reason: '${metric.id}: $company',
          );
        }
      }
    });

    test('los textos de las fichas no están vacíos ni son enormes', () {
      for (final metric in [...content.metrics, ...content.concepts]) {
        for (final text in [
          metric.intuition,
          metric.formula,
          metric.howToRead,
          ...metric.whenItMisleads,
        ]) {
          expect(text.length, inInclusiveRange(30, 700), reason: metric.id);
        }
        expect(metric.summary.length, lessThan(160), reason: metric.id);
      }
    });

    test('existe la explicación de cada concepto que referencia la gráfica (criterio 71)', () {
      for (final id in [
        priceChartTopicId,
        shortAverageTopicId,
        longAverageTopicId,
      ]) {
        expect(content.explanationById(id), isNotNull, reason: id);
      }
    });

    test(
      'los conceptos de la gráfica no se confunden con métricas del motor',
      () {
        final motorIds = {for (final rule in metricRules) rule.id};

        for (final concept in content.concepts) {
          expect(motorIds, isNot(contains(concept.id)), reason: concept.id);
          expect(content.metricById(concept.id), isNull, reason: concept.id);
        }
      },
    );

    test('los ids de tema de bloque y guía son los acordados', () {
      expect(guideTopicId, diagnosisGuideTopicId);
    });
  });

  group('fichas visuales (revisión 2)', () {
    final all = [...content.metrics, ...content.concepts];
    const scales = MotorMetricScaleAdapter();

    test('cada tarjeta de texto cabe en unas 60 palabras (criterio 74)', () {
      for (final metric in all) {
        final cards = {
          'intuicion': metric.intuition,
          'formula': metric.formula,
          'ejemplo': metric.example,
          'comoLeerla': metric.howToRead,
          for (var i = 0; i < metric.whenItMisleads.length; i++)
            'cuandoEngana[$i]': metric.whenItMisleads[i],
        };
        for (final MapEntry(:key, :value) in cards.entries) {
          expect(
            _words(value),
            lessThanOrEqualTo(_maxCardWords),
            reason: '${metric.id} › $key',
          );
        }
      }
    });

    test('cada ficha tiene ilustración (criterio 75)', () {
      for (final metric in all) {
        expect(illustrationFor(metric.id), isNotNull, reason: metric.id);
      }
    });

    test('cada ficha tiene su fórmula por piezas (criterio 76)', () {
      for (final metric in all) {
        expect(metric.formulaDiagram, isNotNull, reason: metric.id);
      }
    });

    test('hay trampas: al menos una tarjeta por ficha', () {
      for (final metric in all) {
        expect(metric.whenItMisleads, isNotEmpty, reason: metric.id);
      }
    });

    test(
      'la leyenda existe si y solo si el motor no tiene escala (criterio 79)',
      () {
        for (final metric in content.metrics) {
          final hasScale = scales.scaleFor(metric.id) != null;
          expect(
            metric.legend.isNotEmpty,
            !hasScale,
            reason: '${metric.id}: escala del motor=$hasScale',
          );
        }
      },
    );

    test('los conceptos de la gráfica tienen leyenda (criterio 79)', () {
      for (final concept in content.concepts) {
        expect(concept.legend, isNotEmpty, reason: concept.id);
      }
    });

    test('cada ficha tiene al menos una actividad (criterio 80)', () {
      for (final metric in all) {
        expect(metric.activities, isNotEmpty, reason: metric.id);
      }
    });

    test('aparecen los cinco tipos de actividad (criterio 80)', () {
      final types = {
        for (final metric in all)
          for (final activity in metric.activities) activity.runtimeType,
      };

      expect(types, {
        SimulatorActivity,
        SpotTrapActivity,
        CompareActivity,
        PredictActivity,
        OrderActivity,
      });
    });

    test(
      'un simulador solo está en fichas con piezas que mover (criterio 86)',
      () {
        for (final metric in all) {
          if (metric.activities.any((a) => a is SimulatorActivity)) {
            final pieces =
                metric.formulaDiagram?.pieces ?? const <FormulaPiece>[];
            expect(
              pieces.any((piece) => piece.isAdjustable),
              isTrue,
              reason: metric.id,
            );
          }
        }
      },
    );

    test('el simulador con los valores iniciales da el resultado del ejemplo (criterio 87)', () {
      for (final metric in all) {
        final diagram = metric.formulaDiagram;
        if (diagram == null || diagram is StepsFormula) continue;

        expect(
          evaluateFormula(diagram),
          closeTo(diagram.result.exampleValue, 1e-9),
          reason: metric.id,
        );
      }
    });

    test('mover cualquier pieza a sus extremos nunca rompe la cuenta', () {
      for (final metric in all) {
        final diagram = metric.formulaDiagram;
        if (diagram == null || diagram is StepsFormula) continue;
        for (final piece in diagram.pieces.where((p) => p.isAdjustable)) {
          for (final extreme in [piece.min!, piece.max!]) {
            final value = evaluateFormula(diagram, {piece.key: extreme});

            expect(
              value,
              isNotNull,
              reason: '${metric.id}: ${piece.key}=$extreme',
            );
            expect(value!.isFinite, isTrue, reason: metric.id);
          }
        }
      }
    });

    test('las claves de las piezas de una fórmula no se repiten', () {
      for (final metric in all) {
        final keys = [
          for (final piece
              in metric.formulaDiagram?.pieces ?? const <FormulaPiece>[])
            piece.key,
        ];

        expect(keys.toSet(), hasLength(keys.length), reason: metric.id);
      }
    });

    test(
      'las actividades no usan empresas reales ni recomiendan (criterio 88)',
      () {
        for (final metric in all) {
          for (final text in _visualTexts(metric)) {
            final lower = text.toLowerCase();
            for (final company in _realCompanies) {
              expect(
                lower.contains(company),
                isFalse,
                reason: '${metric.id}: "$company" en: $text',
              );
            }
          }
        }
      },
    );
  });
}
