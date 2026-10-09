import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/contenido_educativo/application/use_cases/load_educational_content_use_case.dart';
import 'package:stock_app/features/contenido_educativo/application/use_cases/search_glossary_use_case.dart';
import 'package:stock_app/features/contenido_educativo/domain/exceptions/educational_content_exception.dart';
import 'package:stock_app/features/contenido_educativo/presentation/controllers/glossary_controller.dart';

import '../../application/fake_ports.dart';

GlossaryController _controller(FakeEducationalContent port) =>
    GlossaryController(
      loadContent: LoadEducationalContentUseCase(port),
      searchGlossary: const SearchGlossaryUseCase(),
    );

void main() {
  group('GlossaryController', () {
    test('al cargar muestra todas las métricas por bloque', () async {
      final controller = _controller(FakeEducationalContent());

      await controller.load();

      expect(controller.groups.map((g) => g.block.id), [
        'bloque_valoracion',
        'bloque_tecnico',
      ]);
      expect(controller.hasNoResults, isFalse);
    });

    test('el glosario no incluye los conceptos de la gráfica', () async {
      final controller = _controller(FakeEducationalContent());

      await controller.load();

      final ids = [
        for (final group in controller.groups)
          for (final metric in group.metrics) metric.id,
      ];
      expect(ids, isNot(contains('media_50')));
      expect(ids, containsAll(['per', 'peg', 'rsi']));
    });

    test('buscar filtra las métricas sin distinguir tildes', () async {
      final controller = _controller(FakeEducationalContent());
      await controller.load();

      controller.search('cuantos AÑOS');

      expect(controller.groups.single.metrics.map((m) => m.id), ['per']);
    });

    test('una búsqueda sin coincidencias lo indica', () async {
      final controller = _controller(FakeEducationalContent());
      await controller.load();

      controller.search('zzz');

      expect(controller.groups, isEmpty);
      expect(controller.hasNoResults, isTrue);
    });

    test('borrar la búsqueda devuelve todas las métricas', () async {
      final controller = _controller(FakeEducationalContent());
      await controller.load();
      controller.search('zzz');

      controller.search('');

      expect(controller.groups, hasLength(2));
    });

    test('lo escrito antes de que cargue se aplica al cargar', () async {
      final controller = _controller(FakeEducationalContent());
      controller.search('rsi');

      await controller.load();

      expect(controller.groups.single.metrics.single.id, 'rsi');
    });

    test('un contenido ilegible deja el error', () async {
      final controller = _controller(
        FakeEducationalContent(error: const InvalidContentException('roto')),
      );

      await controller.load();

      expect(controller.error, isA<InvalidContentException>());
      expect(controller.content, isNull);
      expect(controller.hasNoResults, isFalse);
    });
  });
}
