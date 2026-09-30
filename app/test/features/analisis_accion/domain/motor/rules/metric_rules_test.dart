import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/indicators/metric_value.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/rules/block_weights.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/rules/metric_rule.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/rules/metric_rules.dart';

// `flutter test` se ejecuta desde app/.
const _metricasPath = '../.claude/skills/motor-analisis/references/metricas.md';

/// Ids de la primera columna de las tablas de las secciones 2-6 de
/// metricas.md (p. ej. "| precio_sma200 (peso 1,5) | ..." → precio_sma200).
Set<String> _documentedIds() {
  final lines = File(_metricasPath).readAsLinesSync();
  final start = lines.indexWhere((l) => l.startsWith('## 2.'));
  final end = lines.indexWhere((l) => l.startsWith('## 7.'));
  final idCell = RegExp(r'^\| ([a-z0-9_]+)(?: \(peso [0-9,]+\))? \|');
  return {
    for (final line in lines.sublist(start, end))
      if (idCell.firstMatch(line) case final match?) match.group(1)!,
  }..remove('id');
}

MetricRule _rule(String id) => metricRules.firstWhere((r) => r.id == id);

double? _macdScore(double histogram, double previous) =>
    _rule('macd').score(MetricValue(histogram, previous: previous));

void main() {
  group('metricRules', () {
    test('cada id es único', () {
      final ids = metricRules.map((r) => r.id).toList();

      expect(ids.toSet().length, ids.length);
    });

    test('los ids coinciden con los de references/metricas.md', () {
      expect(metricRules.map((r) => r.id).toSet(), _documentedIds());
    });

    test('todas las escalas están ordenadas por valor ascendente', () {
      for (final rule in metricRules) {
        final scoring = rule.scoring;
        if (scoring is! ScaleScoring) continue;
        final values = scoring.points.map((p) => p.value).toList();

        expect(values, orderedEquals([...values]..sort()), reason: rule.id);
      }
    });

    test('todas las notas de las escalas están entre 0 y 10', () {
      for (final rule in metricRules) {
        final scoring = rule.scoring;
        if (scoring is! ScaleScoring) continue;

        for (final point in scoring.points) {
          expect(point.score, inInclusiveRange(0, 10), reason: rule.id);
        }
      }
    });

    test('cada bloque tiene métricas activas para cada perfil', () {
      for (final profile in CompanyProfile.values) {
        for (final block in Block.values) {
          final active = metricRules.where(
            (r) => r.block == block && r.weightFor(profile) > 0,
          );

          expect(active, isNotEmpty, reason: '$block / $profile');
        }
      }
    });

    test('el perfil financiero desactiva las métricas de deuda', () {
      for (final id in ['deuda_ebitda', 'deuda_patrimonio', 'liquidez']) {
        expect(_rule(id).weightFor(CompanyProfile.financial), 0, reason: id);
      }
    });
  });

  group('puntuación del MACD', () {
    test('histograma positivo y subiendo → 9', () {
      expect(_macdScore(0.5, 0.2), 9);
    });

    test('histograma positivo y bajando → 6', () {
      expect(_macdScore(0.2, 0.5), 6);
    });

    test('histograma negativo y subiendo → 4', () {
      expect(_macdScore(-0.2, -0.5), 4);
    });

    test('histograma negativo y bajando → 2', () {
      expect(_macdScore(-0.5, -0.2), 2);
    });

    test('sin histograma anterior no puntúa', () {
      expect(_rule('macd').score(const MetricValue(0.5)), isNull);
    });
  });

  group('blockWeights', () {
    test('los pesos de cada horizonte suman 1 y cubren los 5 bloques', () {
      for (final horizon in Horizon.values) {
        final weights = blockWeights[horizon]!;

        expect(weights.keys.toSet(), Block.values.toSet());
        expect(
          weights.values.reduce((a, b) => a + b),
          closeTo(1, 1e-9),
          reason: '$horizon',
        );
      }
    });
  });
}
