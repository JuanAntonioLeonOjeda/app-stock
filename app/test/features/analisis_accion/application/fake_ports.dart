// Fakes escritos a mano de los ports (sin framework de mocking, ver
// .claude/rules/testing-conventions.md).

import 'dart:async';

import 'package:stock_app/features/analisis_accion/domain/chart/intraday_resolution.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/daily_bar.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/fetch_step.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/history_entry.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/intraday_series.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/stock_data.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/symbol_match.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';
import 'package:stock_app/features/analisis_accion/domain/ports/analysis_history_port.dart';
import 'package:stock_app/features/analisis_accion/domain/ports/cache_port.dart';
import 'package:stock_app/features/analisis_accion/domain/ports/link_opener_port.dart';
import 'package:stock_app/features/analisis_accion/domain/ports/intraday_history_port.dart';
import 'package:stock_app/features/analisis_accion/domain/ports/market_data_port.dart';
import 'package:stock_app/features/analisis_accion/domain/ports/price_history_port.dart';

/// Histórico de precios en memoria. Con [error] simula un fallo del proveedor
/// y con [gate] retiene la respuesta hasta que el test la complete.
class FakePriceHistory implements PriceHistoryPort {
  FakePriceHistory({this.bars = const [], this.error});

  final List<DailyBar> bars;
  final MarketDataException? error;
  Completer<void>? gate;
  final List<({String symbol, bool forceRefresh})> calls = [];

  @override
  Future<List<DailyBar>> fetchPriceHistory(
    String symbol, {
    bool forceRefresh = false,
  }) async {
    calls.add((symbol: symbol, forceRefresh: forceRefresh));
    await gate?.future;
    final failure = error;
    if (failure != null) throw failure;
    return bars;
  }
}

/// Velas intradía en memoria: una serie por resolución. Con [error] simula un
/// fallo del proveedor y con [gate] retiene la respuesta.
class FakeIntradayHistory implements IntradayHistoryPort {
  FakeIntradayHistory({this.byResolution = const {}, this.error});

  final Map<IntradayResolution, IntradaySeries> byResolution;
  final MarketDataException? error;
  Completer<void>? gate;
  final List<
    ({String symbol, IntradayResolution resolution, bool forceRefresh})
  >
  calls = [];

  @override
  Future<IntradaySeries> fetchIntraday(
    String symbol,
    IntradayResolution resolution, {
    bool forceRefresh = false,
  }) async {
    calls.add((
      symbol: symbol,
      resolution: resolution,
      forceRefresh: forceRefresh,
    ));
    await gate?.future;
    final failure = error;
    if (failure != null) throw failure;
    return byResolution[resolution] ??
        IntradaySeries(bars: const [], timezone: null, delay: null);
  }
}

/// Abridor de enlaces que registra qué se abrió. [canOpen] simula un
/// dispositivo sin navegador.
class FakeLinkOpener implements LinkOpenerPort {
  FakeLinkOpener({this.canOpen = true});

  final bool canOpen;
  final List<Uri> opened = [];

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return canOpen;
  }
}

/// Caché en memoria que registra con qué caducidad se guardó cada clave.
/// No caduca sola: los tests simulan la caducidad con [expire].
class FakeCache implements CachePort {
  final Map<String, String> values = {};
  final Map<String, Duration> ttls = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value, Duration ttl) async {
    values[key] = value;
    ttls[key] = ttl;
  }

  /// Simula que la entrada [key] ha caducado.
  void expire(String key) {
    values.remove(key);
    ttls.remove(key);
  }
}

/// Una llamada registrada a [FakeMarketData.fetchStockData].
typedef FetchCall = ({String symbol, bool forceRefresh});

/// Datos de mercado configurables: devuelve [stockData] y [matches], o lanza
/// [error] si no es null. Registra las llamadas y emite todos los pasos de
/// progreso.
///
/// Con [gate] se puede dejar una llamada "en curso" hasta completarlo, para
/// comprobar estados intermedios.
class FakeMarketData implements MarketDataPort {
  FakeMarketData({this.stockData, this.matches = const []});

  StockData? stockData;
  List<SymbolMatch> matches;
  Object? error;
  Completer<void>? gate;

  final List<String> searchQueries = [];
  final List<FetchCall> fetchCalls = [];

  @override
  Future<List<SymbolMatch>> searchSymbol(String query) async {
    searchQueries.add(query);
    await gate?.future;
    if (error case final error?) throw error;
    return matches;
  }

  @override
  Future<StockData> fetchStockData(
    String symbol, {
    bool forceRefresh = false,
    void Function(FetchStep step)? onProgress,
  }) async {
    fetchCalls.add((symbol: symbol, forceRefresh: forceRefresh));
    FetchStep.values.forEach(onProgress ?? (_) {});
    await gate?.future;
    if (error case final error?) throw error;
    return stockData ??
        (throw StateError('FakeMarketData sin stockData configurado'));
  }
}

/// Historial en memoria con la misma semántica que el real: el más reciente
/// primero, sin símbolos repetidos.
class FakeHistory implements AnalysisHistoryPort {
  FakeHistory([List<HistoryEntry> initial = const []]) : entries = [...initial];

  final List<HistoryEntry> entries;
  int saveCount = 0;

  @override
  Future<List<HistoryEntry>> load() async => [...entries];

  @override
  Future<void> save(HistoryEntry entry) async {
    saveCount++;
    entries
      ..removeWhere((e) => e.result.symbol == entry.result.symbol)
      ..insert(0, entry);
  }
}
