import 'dart:convert';
import 'dart:io';

import 'package:stock_app/features/analisis_accion/domain/ports/cache_port.dart';
import 'package:stock_app/core/storage/json_file.dart';

/// [CachePort] persistente: un archivo JSON por clave
/// (`{"expiresAt": ..., "value": ...}`) dentro de [directory].
class FileCacheAdapter implements CachePort {
  FileCacheAdapter({required this.directory, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final Directory directory;
  final DateTime Function() _now;

  @override
  Future<String?> read(String key) async {
    final file = _fileFor(key);
    final entry = await file.read();
    if (entry is! Map<String, Object?>) return null;
    final value = entry['value'];
    final expiresAt = DateTime.tryParse('${entry['expiresAt']}');
    if (value is! String || expiresAt == null || _now().isAfter(expiresAt)) {
      await file.delete();
      return null;
    }
    return value;
  }

  /// La caché es una ayuda, no un requisito: si no se puede escribir (disco
  /// lleno, nombre demasiado largo...), se ignora y el análisis continúa.
  @override
  Future<void> write(String key, String value, Duration ttl) async {
    try {
      await _fileFor(
        key,
      ).write({'expiresAt': _now().add(ttl).toIso8601String(), 'value': value});
    } on FileSystemException {
      // Sin caché para esta clave: se volverá a pedir a la API.
    }
  }

  /// Nombre de archivo seguro para cualquier clave (las claves llevan `:` y
  /// `.`, que no valen en todos los sistemas de archivos).
  JsonFile _fileFor(String key) {
    final name = base64Url.encode(utf8.encode(key)).replaceAll('=', '');
    return JsonFile(File('${directory.path}/$name.json'));
  }
}
