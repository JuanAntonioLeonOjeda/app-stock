import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/educational_content.dart';
import 'package:stock_app/features/contenido_educativo/domain/exceptions/educational_content_exception.dart';
import 'package:stock_app/features/contenido_educativo/domain/ports/educational_content_port.dart';
import 'package:stock_app/features/contenido_educativo/infrastructure/adapters/educational_content_parser.dart';

const _basePath = 'assets/contenido';

/// [EducationalContentPort] con los archivos JSON que van dentro de la app.
///
/// Lee y valida una sola vez y guarda el resultado en memoria (son decenas de
/// KB). Un fallo no se guarda: se vuelve a intentar en la siguiente llamada.
class AssetEducationalContentAdapter implements EducationalContentPort {
  AssetEducationalContentAdapter({required this._bundle});

  final AssetBundle _bundle;
  EducationalContent? _content;

  @override
  Future<EducationalContent> load() async => _content ??= await _read();

  Future<EducationalContent> _read() async {
    try {
      return parseEducationalContent(
        metrics: await _bundle.loadString('$_basePath/metricas.es.json'),
        concepts: await _bundle.loadString('$_basePath/conceptos.es.json'),
        blocks: await _bundle.loadString('$_basePath/bloques.es.json'),
        guide: await _bundle.loadString('$_basePath/guia.es.json'),
      );
    } on FlutterError catch (error) {
      // Un asset que falta llega como FlutterError; no debe escapar.
      throw InvalidContentException('No se puede leer un archivo: $error');
    }
  }
}
