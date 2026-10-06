import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/contenido_educativo/application/use_cases/load_educational_content_use_case.dart';
import 'package:stock_app/features/contenido_educativo/domain/exceptions/educational_content_exception.dart';

import '../fake_ports.dart';

void main() {
  group('LoadEducationalContentUseCase', () {
    test('devuelve el contenido del port', () async {
      final port = FakeEducationalContent();

      final content = await LoadEducationalContentUseCase(port)();

      expect(content, same(port.content));
      expect(port.loadCalls, 1);
    });

    test('deja pasar el error de contenido inválido', () async {
      final port = FakeEducationalContent(
        error: const InvalidContentException('roto'),
      );

      await expectLater(
        LoadEducationalContentUseCase(port)(),
        throwsA(isA<InvalidContentException>()),
      );
    });
  });
}
