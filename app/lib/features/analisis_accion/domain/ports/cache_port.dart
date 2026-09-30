/// Almacén clave-valor con caducidad.
abstract interface class CachePort {
  /// Valor guardado en [key], o `null` si no existe o ha caducado.
  Future<String?> read(String key);

  /// Guarda [value] en [key] durante [ttl], sustituyendo lo que hubiera.
  Future<void> write(String key, String value, Duration ttl);
}
