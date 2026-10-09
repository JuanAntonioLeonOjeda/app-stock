import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:stock_app/features/analisis_accion/domain/entities/exchange_rate_series.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';
import 'package:stock_app/features/analisis_accion/domain/ports/exchange_rate_port.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/ecb_rate_parser.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/exchange_rate_http.dart';

/// Desde cuándo se piden los tipos: las gráficas de TradingView empiezan hacia
/// 2001 y el BCE publica desde 1999.
const _since = '2001-01-01';

/// [ExchangeRatePort] con los tipos de referencia diarios del BCE (API
/// SDMX/JSON, oficial y sin clave). Se publican una vez al día, hacia las
/// 16:00 CET, en días laborables.
class EcbExchangeRateAdapter implements ExchangeRatePort {
  EcbExchangeRateAdapter({required this._client});

  final http.Client _client;

  @override
  Future<ExchangeRateSeries> fetchRates(
    String isoCode, {
    bool forceRefresh = false,
  }) async {
    final code = validCurrencyCode(isoCode);
    if (code == null) throw NotFoundException('Moneda no válida: $isoCode');
    final uri = Uri.https(
      'data-api.ecb.europa.eu',
      '/service/data/EXR/D.$code.EUR.SP00.A',
      {'startPeriod': _since, 'format': 'jsondata', 'detail': 'dataonly'},
    );
    final response = await sendRateRequest(
      () => _client.get(uri, headers: {'Accept': 'application/json'}),
    );
    throwForRateStatus(response, code);
    return parseEcbRates(utf8.decode(response.bodyBytes), code);
  }
}
