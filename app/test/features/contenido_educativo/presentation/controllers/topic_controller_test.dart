import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/contenido_educativo/application/use_cases/load_educational_content_use_case.dart';
import 'package:stock_app/features/contenido_educativo/domain/exceptions/educational_content_exception.dart';
import 'package:stock_app/features/contenido_educativo/presentation/controllers/topic_controller.dart';

import '../../application/fake_ports.dart';

TopicController _controller(
  FakeEducationalContent port, {
  String topic = 'per',
}) => TopicController(
  loadContent: LoadEducationalContentUseCase(port),
  initialTopicId: topic,
);

void main() {
  group('TopicController.load', () {
    test('carga el contenido y deja disponible la ficha del tema', () async {
      final controller = _controller(FakeEducationalContent());

      await controller.load();

      expect(controller.content, isNotNull);
      expect(controller.currentMetric?.id, 'per');
      expect(controller.currentBlock, isNull);
      expect(controller.error, isNull);
    });

    test('mientras carga, isLoading es true', () async {
      final port = FakeEducationalContent()..gate = Completer<void>();
      final controller = _controller(port);

      final loading = controller.load();

      expect(controller.isLoading, isTrue);
      port.gate!.complete();
      await loading;
      expect(controller.isLoading, isFalse);
    });

    test('un contenido ilegible deja el error y se puede reintentar', () async {
      final failing = FakeEducationalContent(
        error: const InvalidContentException('roto'),
      );
      final controller = _controller(failing);

      await controller.load();

      expect(controller.content, isNull);
      expect(controller.error, isA<InvalidContentException>());
      await controller.load();
      expect(failing.loadCalls, 2);
    });

    test('un concepto de la gráfica se resuelve como explicación', () async {
      final controller = _controller(
        FakeEducationalContent(),
        topic: 'media_50',
      );

      await controller.load();

      expect(controller.currentMetric?.id, 'media_50');
      expect(controller.currentBlock, isNull);
    });

    test('un tema de bloque se resuelve como bloque', () async {
      final controller = _controller(
        FakeEducationalContent(),
        topic: 'bloque_valoracion',
      );

      await controller.load();

      expect(controller.currentBlock?.id, 'bloque_valoracion');
      expect(controller.currentMetric, isNull);
    });

    test('un tema desconocido no es ni métrica ni bloque', () async {
      final controller = _controller(FakeEducationalContent(), topic: 'nada');

      await controller.load();

      expect(controller.currentMetric, isNull);
      expect(controller.currentBlock, isNull);
    });
  });

  group('TopicController navegación', () {
    test('abrir otro tema lo hace actual y permite volver atrás', () async {
      final controller = _controller(FakeEducationalContent());
      await controller.load();

      controller.openTopic('peg');

      expect(controller.currentTopicId, 'peg');
      expect(controller.canGoBack, isTrue);
      controller.goBack();
      expect(controller.currentTopicId, 'per');
      expect(controller.canGoBack, isFalse);
    });

    test('volver atrás desde el primer tema no hace nada', () async {
      final controller = _controller(FakeEducationalContent());

      controller.goBack();

      expect(controller.currentTopicId, 'per');
    });

    test('abrir el mismo tema no apila nada', () async {
      final controller = _controller(FakeEducationalContent());

      controller.openTopic('per');

      expect(controller.canGoBack, isFalse);
    });

    test('se puede ir y volver por varias métricas relacionadas', () async {
      final controller = _controller(FakeEducationalContent());
      controller
        ..openTopic('peg')
        ..openTopic('rsi');

      controller.goBack();
      controller.goBack();

      expect(controller.currentTopicId, 'per');
    });
  });

  group('TopicController pregunta', () {
    test('guarda la opción elegida y se puede cambiar', () async {
      final controller = _controller(FakeEducationalContent());

      controller.selectOption(0);
      controller.selectOption(2);

      expect(controller.selectedOption, 2);
    });

    test('al abrir otro tema la respuesta se descarta', () async {
      final controller = _controller(FakeEducationalContent());
      controller.selectOption(1);

      controller.openTopic('peg');

      expect(controller.selectedOption, isNull);
    });

    test('al volver atrás la respuesta también se descarta', () async {
      final controller = _controller(FakeEducationalContent());
      controller.openTopic('peg');
      controller.selectOption(1);

      controller.goBack();

      expect(controller.selectedOption, isNull);
    });
  });

  test('notifica a los oyentes en cada cambio', () async {
    final controller = _controller(FakeEducationalContent());
    var notifications = 0;
    controller.addListener(() => notifications++);

    await controller.load();
    controller.openTopic('peg');
    controller.selectOption(0);

    expect(notifications, greaterThanOrEqualTo(4));
  });

  test('tras liberarlo, una carga pendiente no lanza', () async {
    final port = FakeEducationalContent()..gate = Completer<void>();
    final controller = _controller(port);
    final loading = controller.load();

    controller.dispose();
    port.gate!.complete();

    await expectLater(loading, completes);
  });
}
