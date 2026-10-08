import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';

const _requestTimeout = Duration(seconds: 30);

/// Una moneda válida como código ISO (tres letras mayúsculas), lista para ir en
/// una URL, o `null`: no se mete en una dirección nada que no lo sea.
String? validCurrencyCode(String isoCode) {
  final code = isoCode.trim().toUpperCase();
  return RegExp(r'^[A-Z]{3}$').hasMatch(code) ? code : null;
}

/// Lanza la petición traduciendo los fallos de red a `NetworkException`.
Future<http.Response> sendRateRequest(
  Future<http.Response> Function() send,
) async {
  try {
    return await send().timeout(_requestTimeout);
  } on http.ClientException {
    throw const NetworkException('Fallo de conexión');
  } on SocketException {
    throw const NetworkException('Sin conexión');
  } on TimeoutException {
    throw const NetworkException('Tiempo de espera agotado');
  }
}

/// Lanza el `MarketDataException` que corresponde a un HTTP que no es 200.
void throwForRateStatus(http.Response response, String currency) {
  final status = response.statusCode;
  if (status == 200) return;
  if (status == 404) throw NotFoundException('Sin tipo para $currency');
  if (status == 429) throw RateLimitException('HTTP $status');
  if (status >= 500) throw NetworkException('HTTP $status');
  throw InvalidResponseException('HTTP $status');
}
