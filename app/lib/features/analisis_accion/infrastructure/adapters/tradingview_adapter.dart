import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:stock_app/features/analisis_accion/domain/chart/intraday_resolution.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/daily_bar.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/fetch_step.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/intraday_bar.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/intraday_series.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/stock_data.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/symbol_match.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';
import 'package:stock_app/features/analisis_accion/domain/ports/cache_port.dart';
import 'package:stock_app/features/analisis_accion/domain/ports/intraday_history_port.dart';
import 'package:stock_app/features/analisis_accion/domain/ports/market_data_port.dart';
import 'package:stock_app/features/analisis_accion/domain/ports/price_history_port.dart';
import 'package:stock_app/features/analisis_accion/domain/search/group_listings.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/tradingview_chart_connection.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/tradingview_fields.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/tradingview_history_cache.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/tradingview_history_client.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/tradingview_parser.dart';

/// Caducidad de las búsquedas y de los datos (criterio 38 de la spec): todo
/// viene de una sola petición, así que no hay caducidades por endpoint.
const _cacheTtl = Duration(hours: 6);

/// Caducidad del intradía: los precios llegan con 15-20 minutos de retraso, así
/// que pedirlos más a menudo no da datos nuevos (criterio 65).
const _intradayTtl = Duration(minutes: 5);

const _requestTimeout = Duration(seconds: 30);

/// Empresas como máximo a las que se les completa la cotización principal con
/// una búsqueda por ISIN (criterio 77): limita las peticiones de una búsqueda.
const _maxIsinCompletions = 3;

const _searchHost = 'symbol-search.tradingview.com';
const _scannerHost = 'scanner.tradingview.com';

/// Sin esta cabecera el buscador rechaza la petición.
const _headers = {
  'Origin': 'https://www.tradingview.com',
  'User-Agent': 'Mozilla/5.0',
};

/// [MarketDataPort], [PriceHistoryPort] e [IntradayHistoryPort] con el buscador, el scanner y el canal
/// de gráficos de TradingView.
///
/// Fuente **no oficial**: puede cambiar o cortarse sin aviso. No necesita
/// clave. Guarda en caché el JSON en crudo de cada respuesta ya validada
/// (el parser se ejecuta siempre al leer) y nunca una respuesta de error.
class TradingViewAdapter
    implements MarketDataPort, PriceHistoryPort, IntradayHistoryPort {
  TradingViewAdapter({
    required this._client,
    required this._cache,
    required ChartConnector chartConnector,
    DateTime Function()? now,
  }) : _historyClient = TradingViewHistoryClient(connector: chartConnector),
       _now = now ?? DateTime.now;

  final http.Client _client;
  final CachePort _cache;
  final TradingViewHistoryClient _historyClient;
  final DateTime Function() _now;

  /// Descargas del histórico en curso, por símbolo: al abrir un análisis nuevo
  /// el motor y la gráfica lo piden a la vez y comparten una sola petición.
  final Map<String, Future<List<DailyBar>>> _historyDownloads = {};

  /// Lo mismo para el intradía, por resolución y símbolo.
  final Map<String, Future<IntradaySeries>> _intradayDownloads = {};

  @override
  Future<List<SymbolMatch>> searchSymbol(String query) async {
    final text = query.trim();
    if (text.isEmpty) return const [];
    final found = await _searchText(text);
    // Por nombre, TradingView puede devolver solo versiones secundarias de una
    // empresa ("Inditex" trae las de OTC pero no la de Madrid). Se completa
    // buscando por su ISIN, que sí las trae todas.
    final missing = isinsMissingPrimary(found).take(_maxIsinCompletions);
    if (missing.isEmpty) return found;
    final extras = await Future.wait([
      for (final isin in missing) _searchTextOrNothing(isin),
    ]);
    return _withoutRepeats([found, ...extras]);
  }

  /// Una búsqueda del buscador de TradingView, con caché.
  Future<List<SymbolMatch>> _searchText(String text) {
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

  /// La búsqueda complementaria nunca estropea la principal: si falla, no
  /// aporta nada (criterio 82).
  Future<List<SymbolMatch>> _searchTextOrNothing(String text) async {
    try {
      return await _searchText(text);
    } on MarketDataException {
      return const [];
    }
  }

  /// Une varias listas sin repetir símbolos, conservando el orden.
  List<SymbolMatch> _withoutRepeats(List<List<SymbolMatch>> lists) {
    final seen = <String>{};
    return [
      for (final list in lists)
        for (final match in list)
          if (seen.add(match.symbol)) match,
    ];
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
    // El histórico se pide a la vez que el scanner, y un fallo suyo no impide
    // analizar: se queda la barra única del último cierre (criterio 56).
    final historyFuture = _historyOrNull(ticker, forceRefresh: forceRefresh);
    // Si el scanner falla, el error sale al instante: el histórico ya no puede
    // fallar (devuelve null) y se queda descargando en segundo plano.
    final data = await _fetch(
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
    final history = await historyFuture;
    if (history == null) return data;
    return data.withDailyBars(_withLastBar(history, data.dailyBars.last));
  }

  @override
  Future<List<DailyBar>> fetchPriceHistory(
    String symbol, {
    bool forceRefresh = false,
  }) async {
    final ticker = symbol.trim().toUpperCase();
    if (ticker.isEmpty) {
      throw const NotFoundException('Símbolo vacío');
    }
    if (!forceRefresh) {
      final cached = await _readCachedHistory(ticker);
      if (cached != null) return cached;
    }
    return _historyDownloads.putIfAbsent(
      ticker,
      () => _downloadHistory(ticker).whenComplete(() {
        // Con cuerpo y sin devolver nada: `remove` devuelve este mismo Future
        // y `whenComplete` se esperaría a sí mismo para siempre.
        _historyDownloads.remove(ticker);
      }),
    );
  }

  @override
  Future<IntradaySeries> fetchIntraday(
    String symbol,
    IntradayResolution resolution, {
    bool forceRefresh = false,
  }) async {
    final ticker = symbol.trim().toUpperCase();
    if (ticker.isEmpty) {
      throw const NotFoundException('Símbolo vacío');
    }
    final key = 'tv:v1:intraday:${resolution.minutes}:$ticker';
    if (!forceRefresh) {
      final cached = await _readCachedIntraday(key);
      if (cached != null) return cached;
    }
    return _intradayDownloads.putIfAbsent(
      key,
      () => _downloadIntraday(ticker, resolution, key).whenComplete(() {
        // Con cuerpo y sin devolver nada (ver `fetchPriceHistory`).
        _intradayDownloads.remove(key);
      }),
    );
  }

  Future<IntradaySeries> _downloadIntraday(
    String ticker,
    IntradayResolution resolution,
    String key,
  ) async {
    final series = await _historyClient.fetchSeries(
      ticker,
      resolution: '${resolution.minutes}',
      bars: resolution.barsToRequest,
    );
    final result = IntradaySeries(
      bars: [
        for (final candle in series.candles)
          IntradayBar(time: candle.time, close: candle.close),
      ],
      timezone: series.timezone,
      delay: series.delay,
    );
    await _cache.write(key, encodeIntraday(result), _intradayTtl);
    return result;
  }

  /// Lo guardado, o `null` si no hay o ya no se puede interpretar.
  Future<IntradaySeries?> _readCachedIntraday(String key) async {
    final cached = await _cache.read(key);
    if (cached == null) return null;
    try {
      return decodeIntraday(cached);
    } on MarketDataException {
      return null;
    }
  }

  Future<List<DailyBar>> _downloadHistory(String ticker) async {
    final bars = await _historyClient.fetch(ticker);
    await _cache.write(_historyKey(ticker), encodeHistory(bars), _cacheTtl);
    return bars;
  }

  /// El histórico guardado, o `null` si no hay o ya no se puede interpretar
  /// (se vuelve a pedir en lugar de fallar durante horas).
  Future<List<DailyBar>?> _readCachedHistory(String ticker) async {
    final cached = await _cache.read(_historyKey(ticker));
    if (cached == null) return null;
    try {
      return decodeHistory(cached);
    } on MarketDataException {
      return null;
    }
  }

  /// El histórico, o `null` si no se pudo obtener: para el análisis es un
  /// dato opcional.
  Future<List<DailyBar>?> _historyOrNull(
    String ticker, {
    required bool forceRefresh,
  }) async {
    try {
      return await fetchPriceHistory(ticker, forceRefresh: forceRefresh);
    } on MarketDataException {
      return null;
    }
  }

  /// El histórico con el último cierre del scanner: si el scanner trae un día
  /// más reciente lo añade, y si es el mismo día manda el del scanner (es el
  /// precio que se muestra en la cabecera).
  List<DailyBar> _withLastBar(List<DailyBar> history, DailyBar latest) {
    if (history.last.date.isAfter(latest.date)) return history;
    final withoutSameDay = history.where((b) => b.date != latest.date);
    return [...withoutSameDay, latest];
  }

  static String _historyKey(String ticker) => 'tv:v1:history:$ticker';

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
