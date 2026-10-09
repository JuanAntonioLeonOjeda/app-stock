import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';

// Textos de la spec, criterios 22-25 y 33.

/// Mensaje para el usuario de un error al obtener datos.
String errorMessage(MarketDataException error) => switch (error) {
  RateLimitException() =>
    'Límite de peticiones de la API alcanzado. Inténtalo más tarde; puedes '
        'consultar el historial.',
  NotFoundException() => 'No hay datos para este símbolo.',
  NetworkException() => 'Sin conexión.',
  InvalidResponseException() => 'Respuesta inesperada del proveedor de datos.',
};

/// Si tiene sentido ofrecer "Reintentar" para este error. Con un límite
/// alcanzado, reintentar en el momento no sirve.
bool isRetryable(MarketDataException error) => switch (error) {
  NetworkException() || InvalidResponseException() => true,
  RateLimitException() || NotFoundException() => false,
};
