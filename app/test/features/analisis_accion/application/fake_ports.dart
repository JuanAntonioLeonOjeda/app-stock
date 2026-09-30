// Fakes escritos a mano de los ports (sin framework de mocking, ver
// .claude/rules/testing-conventions.md).

import 'package:stock_app/features/analisis_accion/domain/ports/cache_port.dart';

/// Caché en memoria que registra con qué caducidad se guardó cada clave.
/// No caduca sola: los tests simulan la caducidad con [expire].
class FakeCache implements CachePort {
  final Map<String, String> values = {};
  final Map<String, Duration> ttls = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value, Duration ttl) async {
    values[key] = value;
    ttls[key] = ttl;
  }

  /// Simula que la entrada [key] ha caducado.
  void expire(String key) {
    values.remove(key);
    ttls.remove(key);
  }
}
