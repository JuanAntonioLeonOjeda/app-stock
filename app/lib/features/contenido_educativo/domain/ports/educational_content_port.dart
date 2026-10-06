import 'package:stock_app/features/contenido_educativo/domain/entities/educational_content.dart';

/// Acceso al contenido didáctico, independiente de dónde se guarde.
abstract interface class EducationalContentPort {
  /// Todo el contenido.
  ///
  /// Lanza solo `InvalidContentException`.
  Future<EducationalContent> load();
}
