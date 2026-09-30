import 'dart:convert';
import 'dart:io';

/// Lectura y escritura de un archivo JSON. La escritura es atómica: se
/// escribe en un temporal y se renombra, así que un cierre de la app a mitad
/// nunca deja un archivo corrupto.
class JsonFile {
  const JsonFile(this.file);

  final File file;

  /// Contenido del archivo, o `null` si no existe o no es un JSON válido
  /// (un archivo corrupto se trata como ausente).
  Future<Object?> read() async {
    try {
      return jsonDecode(await file.readAsString());
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    }
  }

  Future<void> write(Object? json) async {
    await file.parent.create(recursive: true);
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(jsonEncode(json), flush: true);
    await temporary.rename(file.path);
  }

  Future<void> delete() async {
    try {
      await file.delete();
    } on FileSystemException {
      // Ya no existía.
    }
  }
}
