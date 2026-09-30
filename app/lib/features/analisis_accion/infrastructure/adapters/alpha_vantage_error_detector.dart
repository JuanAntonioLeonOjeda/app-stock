import 'dart:convert';

import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';

/// La petición usa una función de pago (p. ej. `outputsize=full`). No es un
/// error para el usuario: el adapter reintenta con la versión gratuita. Nunca
/// sale de infrastructure/.
class AlphaVantagePremiumException implements Exception {
  const AlphaVantagePremiumException(this.message);

  final String message;

  @override
  String toString() => 'AlphaVantagePremiumException: $message';
}

/// Decodifica el cuerpo de una respuesta de Alpha Vantage y comprueba que no
/// sea un error.
///
/// Alpha Vantage devuelve los errores con HTTP 200, en el propio JSON
/// (`Error Message`, `Note` o `Information`), así que el código HTTP no basta.
/// Lanza un subtipo de `MarketDataException` o
/// [AlphaVantagePremiumException].
Map<String, Object?> decodeAlphaVantageBody(String body) {
  final json = _decodeObject(body);
  final errorMessage = json['Error Message'];
  if (errorMessage is String) throw NotFoundException(_redact(errorMessage));

  final notice = json['Note'] ?? json['Information'];
  if (notice is String) throw _noticeException(notice);

  // Símbolo inexistente en OVERVIEW: objeto vacío con HTTP 200.
  if (json.isEmpty) throw const NotFoundException('Respuesta vacía');
  return json;
}

Map<String, Object?> _decodeObject(String body) {
  final Object? decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException catch (error) {
    throw InvalidResponseException('JSON no válido: ${error.message}');
  }
  if (decoded is! Map<String, Object?>) {
    throw const InvalidResponseException('Se esperaba un objeto JSON');
  }
  return decoded;
}

/// Clasifica un aviso `Note`/`Information` por su texto. El orden importa:
/// el aviso de límite también menciona los planes "premium".
Exception _noticeException(String notice) {
  final text = notice.toLowerCase();
  final details = _redact(notice);
  if (_rateLimitHints.any(text.contains)) return RateLimitException(details);
  if (_apiKeyHints.any(text.contains)) return MissingApiKeyException(details);
  if (text.contains('premium')) return AlphaVantagePremiumException(details);
  return InvalidResponseException(details);
}

/// Quita la clave de la API de un texto del proveedor. Alpha Vantage la
/// repite en algunos avisos ("We have detected your API key as XXXX..."), y
/// ese texto acaba en el detalle de la excepción.
String _redact(String text) => text
    .replaceAllMapped(
      RegExp(r'(api key as )\S+', caseSensitive: false),
      (match) => '${match[1]}[clave oculta]',
    )
    .replaceAll(_apiKeyPattern, '[clave oculta]');

/// Las claves de Alpha Vantage son 16 caracteres en mayúsculas y dígitos.
final _apiKeyPattern = RegExp(r'\b[A-Z0-9]{16}\b');

const _rateLimitHints = [
  'rate limit',
  'requests per day',
  'call frequency',
  'calls per minute',
  // Aviso de ráfaga del plan gratuito ("...spreading out your free API
  // requests more sparingly (1 request per second)").
  'more sparingly',
];

const _apiKeyHints = ['apikey', 'api key is invalid', '**demo** api key'];
