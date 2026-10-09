/// Errores esperados al obtener datos de mercado.
///
/// Los adapters traducen a estos tipos cualquier error de sus librerías;
/// presentación los convierte en mensajes para el usuario. Es `sealed` para
/// que ese `switch` sea exhaustivo.
sealed class MarketDataException implements Exception {
  const MarketDataException([this.details]);

  /// Detalle técnico para depurar; nunca se muestra al usuario.
  final String? details;

  @override
  String toString() =>
      details == null ? runtimeType.toString() : '$runtimeType: $details';
}

/// El proveedor ha rechazado la petición por límite de peticiones o porque
/// bloquea al cliente (HTTP 429 o 403).
final class RateLimitException extends MarketDataException {
  const RateLimitException([super.details]);
}

/// El símbolo no existe o el proveedor no tiene datos para él.
final class NotFoundException extends MarketDataException {
  const NotFoundException([super.details]);
}

/// La respuesta no tiene el formato esperado.
final class InvalidResponseException extends MarketDataException {
  const InvalidResponseException([super.details]);
}

/// Sin conexión o fallo de red.
final class NetworkException extends MarketDataException {
  const NetworkException([super.details]);
}
