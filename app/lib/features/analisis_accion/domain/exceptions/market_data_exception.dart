/// Errores esperados al obtener datos de mercado.
///
/// Los adapters traducen a estos tipos cualquier error de sus librerías;
/// presentación los convierte en mensajes para el usuario. Es `sealed` para
/// que ese `switch` sea exhaustivo.
sealed class MarketDataException implements Exception {
  const MarketDataException([this.details]);

  /// Detalle técnico para depurar; nunca se muestra al usuario ni contiene
  /// la clave de la API.
  final String? details;

  @override
  String toString() =>
      details == null ? runtimeType.toString() : '$runtimeType: $details';
}

/// La API ha rechazado la petición por límite de peticiones.
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

/// La app se compiló sin clave de la API, o el proveedor la rechaza.
final class MissingApiKeyException extends MarketDataException {
  const MissingApiKeyException([super.details]);
}
