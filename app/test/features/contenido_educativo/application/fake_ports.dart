// Fakes escritos a mano de los ports (sin framework de mocking, ver
// .claude/rules/testing-conventions.md).

import 'dart:async';

import 'package:stock_app/features/contenido_educativo/domain/entities/educational_content.dart';
import 'package:stock_app/features/contenido_educativo/domain/exceptions/educational_content_exception.dart';
import 'package:stock_app/features/contenido_educativo/domain/ports/educational_content_port.dart';

import '../sample_content.dart';

/// Contenido en memoria. Con [error] simula un contenido ilegible; con [gate]
/// retiene la carga hasta que el test la complete.
class FakeEducationalContent implements EducationalContentPort {
  FakeEducationalContent({EducationalContent? content, this.error})
    : content = content ?? sampleContent();

  final EducationalContent content;
  final InvalidContentException? error;
  Completer<void>? gate;
  int loadCalls = 0;

  @override
  Future<EducationalContent> load() async {
    loadCalls++;
    await gate?.future;
    final failure = error;
    if (failure != null) throw failure;
    return content;
  }
}
