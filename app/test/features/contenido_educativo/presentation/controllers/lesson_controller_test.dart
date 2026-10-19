import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/contenido_educativo/application/use_cases/get_metric_scale_use_case.dart';
import 'package:stock_app/features/contenido_educativo/application/use_cases/load_educational_content_use_case.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/learning_activity.dart';
import 'package:stock_app/features/contenido_educativo/presentation/controllers/lesson_controller.dart';

import '../../application/fake_ports.dart';
import '../../sample_content.dart';

// Posición de cada paso de la ficha `per` de la muestra.
const _simulatorStep = 5;
const _trapStep = 6;
const _compareStep = 7;
const _predictStep = 8;
const _orderStep = 9;

Future<LessonController> _loaded({String topic = 'per'}) async {
  final controller = LessonController(
    loadContent: LoadEducationalContentUseCase(FakeEducationalContent()),
    initialTopicId: topic,
    getMetricScale: GetMetricScaleUseCase(
      FakeMetricScales({'per': sampleScale()}),
    ),
  );
  addTearDown(controller.dispose);
  await controller.load();
  return controller;
}

OrderActivity _order(LessonController controller) =>
    controller.currentMetric!.activities[4] as OrderActivity;

void main() {
  group('LessonController pasos', () {
    test('empieza en el primer paso', () async {
      final controller = await _loaded();

      expect(controller.currentStep, 0);
      expect(controller.steps, hasLength(11));
    });

    test(
      'goToStep salta a cualquier paso sin pasar por los anteriores',
      () async {
        final controller = await _loaded();

        controller.goToStep(8);

        expect(controller.currentStep, 8);
      },
    );

    test('goToStep ignora un paso fuera de rango', () async {
      final controller = await _loaded();

      controller
        ..goToStep(-1)
        ..goToStep(99);

      expect(controller.currentStep, 0);
    });

    test('sin contenido cargado no hay pasos', () {
      final controller = LessonController(
        loadContent: LoadEducationalContentUseCase(FakeEducationalContent()),
        initialTopicId: 'per',
        getMetricScale: GetMetricScaleUseCase(FakeMetricScales({})),
      );
      addTearDown(controller.dispose);

      expect(controller.steps, isEmpty);
    });

    test('la escala es la del motor para la métrica actual', () async {
      final controller = await _loaded();

      expect(controller.scale, isNotNull);

      controller.openTopic('peg');

      expect(controller.scale, isNull);
    });
  });

  group('LessonController cambio de ficha', () {
    test(
      'abrir una relacionada vuelve al primer paso y se puede volver',
      () async {
        final controller = await _loaded();
        controller.goToStep(4);

        controller.openTopic('peg');

        expect(controller.currentTopicId, 'peg');
        expect(controller.currentStep, 0);
        expect(controller.canGoBack, isTrue);
        controller.goBack();
        expect(controller.currentTopicId, 'per');
      },
    );

    test('al cambiar de ficha se descarta todo lo respondido', () async {
      final controller = await _loaded();
      controller
        ..selectOption(1)
        ..setSimulatorValue(_simulatorStep, 'precio', 50)
        ..tapTrapItem(_trapStep, 2)
        ..answerCompare(_compareStep, isA: true)
        ..answerPredict(_predictStep, 0)
        ..checkOrder(_orderStep);

      controller.openTopic('peg');
      controller.goBack();

      expect(controller.selectedOption, isNull);
      expect(controller.simulatorValues(_simulatorStep), isEmpty);
      expect(controller.trapsTapped(_trapStep), isEmpty);
      expect(controller.compareAnswer(_compareStep), isNull);
      expect(controller.predictAnswer(_predictStep), isNull);
      expect(controller.isOrderChecked(_orderStep), isFalse);
    });
  });

  group('LessonController actividades', () {
    test(
      'el simulador guarda el valor de cada pieza y se puede reiniciar',
      () async {
        final controller = await _loaded();

        controller.setSimulatorValue(_simulatorStep, 'precio', 50);

        expect(controller.simulatorValues(_simulatorStep), {'precio': 50});
        controller.resetSimulator(_simulatorStep);
        expect(controller.simulatorValues(_simulatorStep), isEmpty);
      },
    );

    test('detectar la trampa recuerda los datos ya probados', () async {
      final controller = await _loaded();

      controller
        ..tapTrapItem(_trapStep, 0)
        ..tapTrapItem(_trapStep, 2);

      expect(controller.trapsTapped(_trapStep), {0, 2});
    });

    test('comparar y predecir permiten cambiar de respuesta', () async {
      final controller = await _loaded();

      controller
        ..answerCompare(_compareStep, isA: true)
        ..answerCompare(_compareStep, isA: false)
        ..answerPredict(_predictStep, 0)
        ..answerPredict(_predictStep, 1);

      expect(controller.compareAnswer(_compareStep), isFalse);
      expect(controller.predictAnswer(_predictStep), 1);
    });

    test('ordenar: sale desordenado y es el mismo orden cada vez', () async {
      final controller = await _loaded();
      final order = _order(controller);

      final first = controller.orderOf(_orderStep, order);

      expect(first, isNot([0, 1, 2]));
      expect(controller.orderOf(_orderStep, order), first);
      expect(controller.isOrderCorrect(_orderStep, order), isFalse);
    });

    test(
      'ordenar: mover elementos hasta dejarlos de menor a mayor es correcto',
      () async {
        final controller = await _loaded();
        final order = _order(controller);
        // Selección por intercambios hasta tener 0, 1, 2.
        for (var target = 0; target < 3; target++) {
          final current = controller.orderOf(_orderStep, order);
          final from = current.indexOf(target);
          if (from != target) {
            controller.reorder(_orderStep, order, from, target);
          }
        }

        expect(controller.orderOf(_orderStep, order), [0, 1, 2]);
        expect(controller.isOrderCorrect(_orderStep, order), isTrue);
      },
    );

    test('ordenar: mover un elemento anula la comprobación previa', () async {
      final controller = await _loaded();
      final order = _order(controller);
      controller.checkOrder(_orderStep);

      controller.reorder(_orderStep, order, 0, 1);

      expect(controller.isOrderChecked(_orderStep), isFalse);
    });

    test('ordenar: repetir vuelve al orden barajado inicial', () async {
      final controller = await _loaded();
      final order = _order(controller);
      final initial = controller.orderOf(_orderStep, order);
      controller
        ..reorder(_orderStep, order, 0, 2)
        ..checkOrder(_orderStep);

      controller.retryOrder(_orderStep);

      expect(controller.orderOf(_orderStep, order), initial);
      expect(controller.isOrderChecked(_orderStep), isFalse);
    });
  });
}
