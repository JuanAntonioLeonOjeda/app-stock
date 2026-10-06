import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/contenido_educativo/domain/content/glossary_search.dart';

import '../../sample_content.dart';

void main() {
  final metrics = sampleContent().metrics;

  group('normalizeForSearch', () {
    test('pasa a minúsculas y quita tildes y diéresis', () {
      expect(
        normalizeForSearch('Deuda NETA sobre Ébitda'),
        'deuda neta sobre ebitda',
      );
      expect(normalizeForSearch('Pingüino y niño'), 'pinguino y nino');
    });
  });

  group('filterMetrics', () {
    test('un texto vacío devuelve todas las métricas', () {
      expect(filterMetrics(metrics, ''), metrics);
      expect(filterMetrics(metrics, '   '), metrics);
    });

    test('busca en el título sin distinguir mayúsculas', () {
      final result = filterMetrics(metrics, 'rsi');

      expect([for (final m in result) m.id], ['rsi']);
    });

    test('busca en el resumen', () {
      final result = filterMetrics(metrics, 'AJUSTADO por crecimiento');

      expect([for (final m in result) m.id], ['peg']);
    });

    test('no distingue tildes en la búsqueda ni en el texto', () {
      final result = filterMetrics(metrics, 'cuantos anos');

      expect([for (final m in result) m.id], ['per']);
    });

    test('sin coincidencias devuelve una lista vacía', () {
      expect(filterMetrics(metrics, 'zzz'), isEmpty);
    });
  });
}
