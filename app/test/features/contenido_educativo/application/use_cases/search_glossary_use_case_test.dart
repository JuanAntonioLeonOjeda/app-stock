import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/contenido_educativo/application/use_cases/search_glossary_use_case.dart';

import '../../sample_content.dart';

void main() {
  const search = SearchGlossaryUseCase();
  final content = sampleContent();

  group('SearchGlossaryUseCase', () {
    test('sin texto devuelve todas las métricas agrupadas por bloque', () {
      final groups = search(content, '');

      expect(groups.map((g) => g.block.id), [
        'bloque_valoracion',
        'bloque_tecnico',
      ]);
      expect(groups.first.metrics.map((m) => m.id), ['per', 'peg']);
    });

    test('filtra dentro de cada bloque', () {
      final groups = search(content, 'peg');

      expect(groups, hasLength(1));
      expect(groups.single.metrics.map((m) => m.id), ['peg']);
    });

    test('los bloques sin coincidencias no aparecen', () {
      final groups = search(content, 'rsi');

      expect(groups.map((g) => g.block.id), ['bloque_tecnico']);
    });

    test('sin ninguna coincidencia devuelve una lista vacía', () {
      expect(search(content, 'zzz'), isEmpty);
    });
  });
}
