import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:stock_app/features/analisis_accion/domain/entities/fetch_step.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/stock_data.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/symbol_match.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';
import 'package:stock_app/features/analisis_accion/domain/ports/cache_port.dart';
import 'package:stock_app/features/analisis_accion/domain/ports/market_data_port.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/tradingview_fields.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/tradingview_parser.dart';

/// Caducidad de las búsquedas y de los datos (criterio 38 de la spec): todo
/// viene de una sola petición, así que no hay caducidades por endpoint.
const _cacheTtl = Duration(hours: 6);

const _requestTimeout = Duration(seconds: 30);

const _searchHost = 'symbol-search.tradingview.com';
const _scannerHost = 'scanner.tradingview.com';

/// Sin esta cabecera el buscador rechaza la petición.
const _headers = {
  'Origin': 'https://www.tradingview.com',
  'User-Agent': 'Mozilla/5.0',
};

/// [MarketDataPort] con el buscador y el scanner de TradingView.
///
/// Fuente **no oficial**: puede cambiar o cortarse sin aviso. No necesita
/// clave. Guarda en caché el JSON en crudo de cada respuesta ya validada
/// (el parser se ejecuta siempre al leer) y nunca una respuesta de error.
class TradingViewAdapter implements MarketDataPort {
  TradingViewAdapter({
    required this._client,
    required this._cache,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final http.Client _client;
  final CachePort _cache;
  final DateTime Function() _now;

  @override
  Future<List<SymbolMatch>> searchSymbol(String query) async {
    final text = query.trim();
    if (text.isEmpty) return const [];
    final uri = Uri.https(_searchHost, '/symbol_search/v3/', {
      'text': text,
      'search_type': 'stock',
      'start': '0',
    });
    return _fetch(
      send: () => _client.get(uri, headers: _headers),
      cacheKey: 'tv:v1:search:${text.toLowerCase()}',
      forceRefresh: false,
      parse: parseTradingViewSearch,
    );
  }

  @override
  Future<StockData> fetchStockData(
    String symbol, {
    bool forceRefresh = false,
    void Function(FetchStep step)? onProgress,
  }) async {
    final ticker = symbol.trim().toUpperCase();
    if (ticker.isEmpty) {
      throw const NotFoundException('Símbolo vacío');
    }
    onProgress?.call(FetchStep.values.first);
    final uri = Uri.https(_scannerHost, '/global/scan');
    final body = jsonEncode({
      'symbols': {
        'tickers': [ticker],
      },
      'columns': tradingViewFields,
    });
    return _fetch(
      send: () => _client.post(
        uri,
        headers: {..._headers, 'Content-Type': 'application/json'},
        body: body,
      ),
      cacheKey: 'tv:v1:scan:$ticker',
      forceRefresh: forceRefresh,
      // El momento del ensamblado; la antigüedad real del precio la mide el
      // motor con la fecha del último cierre.
      parse: (body) => parseTradingViewScan(body, fetchedAt: _now()),
    );
  }

  /// Respuesta de la caché o, si no está (o [forceRefresh]), de la red,
  /// convertida con [parse]. Solo guarda en caché lo que [parse] acepta.
  Future<T> _fetch<T>({
    required Future<http.Response> Function() send,
    required String cacheKey,
    required bool forceRefresh,
    required T Function(String body) parse,
  }) async {
    if (!forceRefresh) {
      final cached = await _cache.read(cacheKey);
      if (cached != null) {
        try {
          return parse(cached);
        } on MarketDataException {
          // Una entrada guardada con un formato anterior no debe bloquear
          // durante horas: se ignora y se vuelve a pedir.
        }
      }
    }
    final body = await _send(send);
    final value = parse(body);
    await _cache.write(cacheKey, body, _cacheTtl);
    return value;
  }

  Future<String> _send(Future<http.Response> Function() send) async {
    final http.Response response;
    try {
      response = await send().timeout(_requestTimeout);
    } on http.ClientException {
      throw const NetworkException('Fallo de conexión');
    } on IOException {
      throw const NetworkException('Sin conexión');
    } on TimeoutException {
      throw const NetworkException('Tiempo de espera agotado');
    }
    return _bodyOrThrow(response);
  }

  String _decodeBody(http.Response response) {
    try {
      return utf8.decode(response.bodyBytes);
    } on FormatException {
      throw const InvalidResponseException('Cuerpo que no es UTF-8');
    }
  }

  String _bodyOrThrow(http.Response response) {
    final status = response.statusCode;
    if (status == 200) return _decodeBody(response);
    // 429 por exceso de peticiones; 403 cuando bloquea al cliente.
    if (status == 429 || status == 403) {
      throw RateLimitException('HTTP $status');
    }
    if (status >= 500) throw NetworkException('HTTP $status');
    throw InvalidResponseException('HTTP $status');
  }
}
