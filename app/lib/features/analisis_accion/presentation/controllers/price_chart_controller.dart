import 'package:flutter/foundation.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/get_intraday_history_use_case.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/get_price_history_use_case.dart';
import 'package:stock_app/features/analisis_accion/domain/chart/chart_range.dart';
import 'package:stock_app/features/analisis_accion/domain/chart/intraday_resolution.dart';
import 'package:stock_app/features/analisis_accion/domain/chart/price_series.dart';
import 'package:stock_app/features/analisis_accion/domain/chart/sessions.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/daily_bar.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/intraday_series.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';

/// Medias móviles que se pueden superponer (criterio 50).
const shortAverageSessions = 50;
const longAverageSessions = 200;

/// Puntos a los que se reduce cada línea al dibujarla (criterio 51).
const chartMaxPoints = 500;

/// Sesiones que muestra el periodo de una semana (criterio 60).
const weekSessions = 5;

/// Lo que pinta la gráfica para el periodo elegido: ya recortado y agrupado.
class PriceChartView {
  PriceChartView({
    required List<ChartPoint> closes,
    required List<ChartPoint> shortAverage,
    required List<ChartPoint> longAverage,
    required this.extremes,
    this.isIntraday = false,
    this.timezone,
    this.delay,
    List<int> sessionStarts = const [],
  }) : closes = List.unmodifiable(closes),
       shortAverage = List.unmodifiable(shortAverage),
       longAverage = List.unmodifiable(longAverage),
       sessionStarts = List.unmodifiable(sessionStarts);

  /// Línea de cierres.
  final List<ChartPoint> closes;

  /// Media de 50 sesiones; vacía si está desactivada o no hay datos.
  final List<ChartPoint> shortAverage;

  /// Media de 200 sesiones; vacía si está desactivada o no hay datos.
  final List<ChartPoint> longAverage;

  /// Máximo y mínimo de cierre del periodo (sobre todos los cierres, no solo
  /// los puntos agrupados).
  final CloseExtremes? extremes;

  /// Velas de minutos (1D y 1S) en lugar de cierres diarios.
  final bool isIntraday;

  /// Zona horaria de la bolsa (solo intradía); `null` si no se conoce.
  final String? timezone;

  /// Retraso de los precios que indica el proveedor (solo intradía).
  final Duration? delay;

  /// Posición de la primera vela de cada sesión (solo intradía).
  final List<int> sessionStarts;
}

/// Estado de la gráfica de precio de la pestaña Resumen: carga del histórico,
/// periodo, interruptores de medias y los datos que se dibujan.
///
/// El día y la semana (intradía) se cargan al elegirlos y tienen su propio
/// estado y error: un fallo ahí no afecta a los periodos largos (criterio 66).
class PriceChartController extends ChangeNotifier {
  PriceChartController({
    required this._getPriceHistory,
    required this._getIntradayHistory,
    required this.symbol,
  });

  final GetPriceHistoryUseCase _getPriceHistory;
  final GetIntradayHistoryUseCase _getIntradayHistory;
  final String symbol;

  List<DailyBar>? _bars;
  MarketDataException? _error;
  bool _isLoading = false;
  ChartRange _range = ChartRange.year1;
  bool _showShortAverage = false;
  bool _showLongAverage = false;
  PriceChartView? _view;
  bool _isDisposed = false;

  /// Se pidió una recarga forzada mientras había otra carga en curso.
  bool _hasPendingRefresh = false;

  final Map<IntradayResolution, IntradaySeries> _intraday = {};
  final Set<IntradayResolution> _loadingIntraday = {};
  final Map<IntradayResolution, MarketDataException> _intradayErrors = {};

  /// Resoluciones para las que se pidió una recarga forzada mientras había
  /// otra carga en curso.
  final Set<IntradayResolution> _pendingIntradayRefresh = {};

  /// Histórico diario cargado; `null` hasta que llega.
  List<DailyBar>? get bars => _bars;

  /// Se está cargando lo que muestra el periodo elegido y aún no hay nada que
  /// dibujar.
  bool get isLoading => _view == null && _isLoadingCurrent;

  bool get _isLoadingCurrent {
    final resolution = _resolutionOf(_range);
    return resolution == null
        ? _isLoading
        : _loadingIntraday.contains(resolution);
  }

  /// Error de lo que muestra el periodo elegido. Si ya había datos que
  /// dibujar, se siguen dibujando.
  MarketDataException? get error {
    final resolution = _resolutionOf(_range);
    return resolution == null ? _error : _intradayErrors[resolution];
  }

  ChartRange get range => _range;

  bool get showShortAverage => _showShortAverage;

  bool get showLongAverage => _showLongAverage;

  /// Datos para dibujar el periodo elegido; `null` mientras no los haya.
  PriceChartView? get view => _view;

  /// Carga el histórico diario. Con [forceRefresh] lo vuelve a pedir al
  /// proveedor, y también el día o la semana si es lo que se está mirando.
  ///
  /// Si ya hay una carga en curso y se pide una forzada, se repite al terminar
  /// en lugar de perderla (criterio 45).
  Future<void> load({bool forceRefresh = false}) async {
    if (_isLoading) {
      if (forceRefresh) _hasPendingRefresh = true;
      return;
    }
    _isLoading = true;
    _error = null;
    _notify();
    final intradayLoad = forceRefresh && _range.isIntraday
        ? loadIntraday(forceRefresh: true)
        : null;
    try {
      _bars = await _getPriceHistory(symbol, forceRefresh: forceRefresh);
      _recompute();
    } on MarketDataException catch (error) {
      _error = error;
    } finally {
      _isLoading = false;
      _notify();
      await intradayLoad;
    }
    if (_hasPendingRefresh && !_isDisposed) {
      _hasPendingRefresh = false;
      await load(forceRefresh: true);
    }
  }

  /// Carga las velas del periodo intradía elegido (1D o 1S). Si ya las tenía de
  /// antes, las sigue mostrando mientras se refrescan.
  Future<void> loadIntraday({bool forceRefresh = false}) async {
    final resolution = _resolutionOf(_range);
    if (resolution == null) return;
    if (_loadingIntraday.contains(resolution)) {
      // Una recarga forzada no se pierde: se repite al terminar la carga.
      if (forceRefresh) _pendingIntradayRefresh.add(resolution);
      return;
    }
    _loadingIntraday.add(resolution);
    _intradayErrors.remove(resolution);
    _notify();
    try {
      _intraday[resolution] = await _getIntradayHistory(
        symbol,
        resolution,
        forceRefresh: forceRefresh,
      );
      _recompute();
    } on MarketDataException catch (error) {
      _intradayErrors[resolution] = error;
    } finally {
      _loadingIntraday.remove(resolution);
      _notify();
    }
    if (_pendingIntradayRefresh.remove(resolution) && !_isDisposed) {
      await loadIntraday(forceRefresh: true);
    }
  }

  /// Repite la carga de lo que muestra el periodo elegido ("Reintentar").
  Future<void> retry() => _range.isIntraday ? loadIntraday() : load();

  void selectRange(ChartRange range) {
    if (range == _range) return;
    _range = range;
    _recompute();
    _notify();
    if (range.isIntraday) loadIntraday();
  }

  void setShortAverage({required bool isVisible}) {
    _showShortAverage = isVisible;
    _recompute();
    _notify();
  }

  void setLongAverage({required bool isVisible}) {
    _showLongAverage = isVisible;
    _recompute();
    _notify();
  }

  IntradayResolution? _resolutionOf(ChartRange range) => switch (range) {
    ChartRange.day => IntradayResolution.minutes5,
    ChartRange.week => IntradayResolution.minutes30,
    _ => null,
  };

  void _recompute() {
    final resolution = _resolutionOf(_range);
    _view = resolution == null ? _dailyView() : _intradayView(resolution);
  }

  PriceChartView? _dailyView() {
    final bars = _bars;
    if (bars == null) return null;
    final slice = sliceRange(bars, _range);
    final closes = closePoints(slice);
    return PriceChartView(
      closes: downsample(closes, maxPoints: chartMaxPoints),
      shortAverage: _showShortAverage
          ? _averageLine(bars, slice, shortAverageSessions)
          : const [],
      longAverage: _showLongAverage
          ? _averageLine(bars, slice, longAverageSessions)
          : const [],
      extremes: closeExtremes(closes),
    );
  }

  /// La última sesión (1D) o las últimas 5 (1S), con las velas pegadas.
  PriceChartView? _intradayView(IntradayResolution resolution) {
    final series = _intraday[resolution];
    if (series == null) return null;
    final sessionCount = _range == ChartRange.day ? 1 : weekSessions;
    final slice = lastSessions(series.bars, sessionCount);
    final points = [
      for (final bar in slice.bars) ChartPoint(bar.time, bar.close),
    ];
    return PriceChartView(
      closes: points,
      shortAverage: const [],
      longAverage: const [],
      extremes: closeExtremes(points),
      isIntraday: true,
      timezone: series.timezone,
      delay: series.delay,
      sessionStarts: slice.starts,
    );
  }

  /// La media calculada sobre todo el histórico (para que la del primer día
  /// del periodo use las sesiones anteriores) y recortada al periodo. Donde no
  /// hay sesiones suficientes no hay punto.
  List<ChartPoint> _averageLine(
    List<DailyBar> all,
    List<DailyBar> slice,
    int sessions,
  ) {
    if (slice.isEmpty) return const [];
    final from = slice.first.date;
    final points = [
      for (final point in movingAverageSeries(all, sessions))
        if (point != null && !point.date.isBefore(from)) point,
    ];
    return downsample(points, maxPoints: chartMaxPoints);
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
