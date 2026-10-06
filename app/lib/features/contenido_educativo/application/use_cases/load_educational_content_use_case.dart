import 'package:stock_app/features/contenido_educativo/domain/entities/educational_content.dart';
import 'package:stock_app/features/contenido_educativo/domain/ports/educational_content_port.dart';

/// Carga todo el contenido didáctico.
class LoadEducationalContentUseCase {
  const LoadEducationalContentUseCase(this._port);

  final EducationalContentPort _port;

  /// Lanza `InvalidContentException` si el contenido no se puede leer.
  Future<EducationalContent> call() => _port.load();
}
