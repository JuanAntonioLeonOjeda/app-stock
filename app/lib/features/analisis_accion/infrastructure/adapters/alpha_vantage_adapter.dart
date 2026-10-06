import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:stock_app/features/analisis_accion/domain/entities/daily_bar.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/fetch_step.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/stock_data.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/symbol_match.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';
import 'package:stock_app/features/analisis_accion/domain/ports/cache_port.dart';
import 'package:stock_app/features/analisis_accion/domain/ports/market_data_port.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/alpha_vantage_error_detector.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/alpha_vantage_parser.dart';

// Caducidad de cada tipo de respuesta en la caché (skill datos-mercado).
const _dailyHistoryTtl = Duration(hours: 6);
const _overviewTtl = Duration(hours: 24);
const _statementsTtl = Duration(days: 7);
const _searchTtl = Duration(days: 30);

/// Clave de caché que recuerda que el plan no permite `outputsize=full`,
/// para no gastar una petición en intentarlo en cada análisis.
const fullHistoryUnavailableKey = 'av:plan:full_history_unavailable';
const _fullHistoryUnavailableTtl = Duration(days: 30);

const _requestTimeout = Duration(seconds: 30);

/// [MarketDataPort] con la API REST de Alpha Vantage.
///
/// Hace las peticiones en secuencia, con [pauseBetweenRequests] entre dos
/// peticiones de red (el plan gratuito limita las ráfagas). Guarda en caché
/// cada respuesta correcta en cuanto llega (el JSON en crudo, ya validado),
/// así que un fallo a mitad no desperdicia lo ya obtenido. Las respuestas de
/// error nunca se guardan. La clave de la API nunca aparece en claves de
/// caché ni en mensajes de error.
class AlphaVantageAdapter implements MarketDataPort {
  AlphaVantageAdapter({
    required this._client,
    required this._cache,
    required String apiKey,
    this.pauseBetweenRequests = const Duration(milliseconds: 1200),
    Future<void> Function(Duration duration)? delay,
    DateTime Function()? now,
  }) : _apiKey = apiKey.trim(),
       _delay = delay ?? _futureDelay,
       _now = now ?? DateTime.now;

  final http.Client _client;
  final CachePort _cache;
  final String _apiKey;
  final Duration pauseBetweenRequests;
  final Future<void> Function(Duration duration) _delay;
  final DateTime Function() _now;

  /// Si ya se ha hecho una petición de red en la operación en curso (para
  /// saber si hay que esperar antes de la siguiente).
  bool _hasRequestedInOperation = false;

  @override
  Future<List<SymbolMatch>> searchSymbol(String query) async {
    final keywords = query.trim();
    if (keywords.isEmpty) return const [];
    _ensureApiKey();
    _hasRequestedInOperation = false;
    final matches = await _fetch(
      params: {'function': 'SYMBOL_SEARCH', 'keywords': keywords},
      cacheKey: 'av:SYMBOL_SEARCH:${keywords.toLowerCase()}',
      ttl: _searchTtl,
      forceRefresh: false,
      parse: parseSymbolSearch,
    );
    return matches..sort((a, b) => b.matchScore.compareTo(a.matchScore));
  }

  @override
  Future<StockData> fetchStockData(
    String symbol, {
    bool forceRefresh = false,
    void Function(FetchStep step)? onProgress,
  }) async {
    final normalizedSymbol = symbol.trim().toUpperCase();
    if (normalizedSymbol.isEmpty) {
      throw const NotFoundException('Símbolo vacío');
    }
    _ensureApiKey();
    _hasRequestedInOperation = false;

    Future<T> fetchEndpoint<T>(
      FetchStep step,
      String function,
      Duration ttl,
      T Function(Json json) parse,
    ) {
      onProgress?.call(step);
      return _fetch(
        params: {'function': function, 'symbol': normalizedSymbol},
        cacheKey: _cacheKey(function, normalizedSymbol),
        ttl: ttl,
        forceRefresh: forceRefresh,
        parse: parse,
      );
    }

    final overview = await fetchEndpoint(
      FetchStep.overview,
      'OVERVIEW',
      _overviewTtl,
      parseOverview,
    );
    onProgress?.call(FetchStep.dailyHistory);
    final dailyBars = await _fetchDailyHistory(normalizedSymbol, forceRefresh);
    final income = await fetchEndpoint(
      FetchStep.incomeStatement,
      'INCOME_STATEMENT',
      _statementsTtl,
      parseIncomeStatements,
    );
    final balance = await fetchEndpoint(
      FetchStep.balanceSheet,
      'BALANCE_SHEET',
      _statementsTtl,
      parseBalanceSheets,
    );
    final cashFlow = await fetchEndpoint(
      FetchStep.cashFlow,
      'CASH_FLOW',
      _statementsTtl,
      parseCashFlows,
    );
    final earnings = await fetchEndpoint(
      FetchStep.earnings,
      'EARNINGS',
      _statementsTtl,
      parseEarnings,
    );

    return StockData(
      overview: overview,
      dailyBars: dailyBars,
      annualIncome: income.annual,
      quarterlyIncome: income.quarterly,
      annualBalance: balance.annual,
      quarterlyBalance: balance.quarterly,
      annualCashFlow: cashFlow.annual,
      quarterlyCashFlow: cashFlow.quarterly,
      quarterlyEarnings: earnings,
      // Momento del ensamblado; la antigüedad real de los precios la mide el
      // motor con la fecha del último cierre.
      fetchedAt: _now(),
    );
  }

  /// Histórico completo si el plan lo permite; si no, el compacto (~100
  /// sesiones), recordando en caché que el completo es de pago.
  Future<List<DailyBar>> _fetchDailyHistory(
    String symbol,
    bool forceRefresh,
  ) async {
    final cacheKey = _cacheKey('TIME_SERIES_DAILY', symbol);
    final isFullUnavailable = await _cache.read(fullHistoryUnavailableKey);
    if (isFullUnavailable == null) {
      try {
        return await _fetch(
          params: {
            'function': 'TIME_SERIES_DAILY',
            'symbol': symbol,
            'outputsize': 'full',
          },
          cacheKey: cacheKey,
          ttl: _dailyHistoryTtl,
          forceRefresh: forceRefresh,
          parse: parseDailySeries,
        );
      } on AlphaVantagePremiumException {
        await _cache.write(
          fullHistoryUnavailableKey,
          'true',
          _fullHistoryUnavailableTtl,
        );
      }
    }
    return _fetch(
      params: {'function': 'TIME_SERIES_DAILY', 'symbol': symbol},
      cacheKey: cacheKey,
      ttl: _dailyHistoryTtl,
      forceRefresh: forceRefresh,
      parse: parseDailySeries,
    );
  }

  /// Respuesta de la caché o, si no está (o [forceRefresh]), de la API,
  /// convertida con [parse]. Solo guarda en caché las respuestas que no son
  /// un error y que [parse] acepta.
  Future<T> _fetch<T>({
    required Map<String, String> params,
    required String cacheKey,
    required Duration ttl,
    required bool forceRefresh,
    required T Function(Json json) parse,
  }) async {
    if (!forceRefresh) {
      final cached = await _cache.read(cacheKey);
      if (cached != null) return parse(decodeAlphaVantageBody(cached));
    }
    final body = await _get(params);
    final value = parse(decodeAlphaVantageBody(body));
    await _cache.write(cacheKey, body, ttl);
    return value;
  }

  Future<String> _get(Map<String, String> params) async {
    if (_hasRequestedInOperation && pauseBetweenRequests > Duration.zero) {
      await _delay(pauseBetweenRequests);
    }
    _hasRequestedInOperation = true;
    final uri = Uri.https('www.alphavantage.co', '/query', {
      ...params,
      'apikey': _apiKey,
    });
    final http.Response response;
    try {
      response = await _client.get(uri).timeout(_requestTimeout);
    } on http.ClientException {
      // El mensaje de ClientException incluye la URL, con la clave: no se
      // propaga.
      throw const NetworkException('Fallo de conexión');
    } on SocketException {
      throw const NetworkException('Sin conexión');
    } on TimeoutException {
      throw const NetworkException('Tiempo de espera agotado');
    }
    return _bodyOrThrow(response);
  }

  String _bodyOrThrow(http.Response response) {
    final status = response.statusCode;
    if (status == 200) return response.body;
    if (status == 429) throw const RateLimitException('HTTP 429');
    if (status >= 500) throw NetworkException('HTTP $status');
    throw InvalidResponseException('HTTP $status');
  }

  void _ensureApiKey() {
    if (_apiKey.isEmpty) throw const MissingApiKeyException();
  }

  static String _cacheKey(String function, String symbol) =>
      'av:$function:$symbol';

  static Future<void> _futureDelay(Duration duration) =>
      Future<void>.delayed(duration);
}
