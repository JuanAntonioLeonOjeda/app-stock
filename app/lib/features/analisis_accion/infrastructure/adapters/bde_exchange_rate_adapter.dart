import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:stock_app/features/analisis_accion/domain/entities/exchange_rate_series.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';
import 'package:stock_app/features/analisis_accion/domain/ports/exchange_rate_port.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/bde_rate_parser.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/exchange_rate_http.dart';

/// [ExchangeRatePort] con el CSV oficial de tipos de cambio del Banco de
/// España, que republica los del BCE con un día de retraso. Es el respaldo: son
/// ~1,9 MB con todas las monedas desde 1999, y solo tiene unas 33.
class BdeExchangeRateAdapter implements ExchangeRatePort {
  BdeExchangeRateAdapter({required this._client});

  final http.Client _client;

  @override
  Future<ExchangeRateSeries> fetchRates(
    String isoCode, {
    bool forceRefresh = false,
  }) async {
    final code = validCurrencyCode(isoCode);
    if (code == null) throw NotFoundException('Moneda no válida: $isoCode');
    final uri = Uri.https(
      'www.bde.es',
      '/webbe/es/estadisticas/compartido/datos/csv/tc_1_1.csv',
    );
    final response = await sendRateRequest(() => _client.get(uri));
    throwForRateStatus(response, code);
    // El archivo viene en latin-1, no en UTF-8.
    return parseBdeRates(latin1.decode(response.bodyBytes), code);
  }
}
