import 'package:flutter/foundation.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/get_price_history_use_case.dart';
import 'package:stock_app/features/analisis_accion/domain/chart/chart_range.dart';
import 'package:stock_app/features/analisis_accion/domain/chart/price_series.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/daily_bar.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';

/// Medias móviles que se pueden superponer (criterio 50).
const shortAverageSessions = 50;
const longAverageSessions = 200;

/// Puntos a los que se reduce cada línea al dibujarla (criterio 51).
const chartMaxPoints = 500;

/// Lo que pinta la gráfica para el periodo elegido: ya recortado y agrupado.
class PriceChartView {
  PriceChartView({
    required List<ChartPoint> closes,
    required List<ChartPoint> shortAverage,
    required List<ChartPoint> longAverage,
    required this.extremes,
  }) : closes = List.unmodifiable(closes),
       shortAverage = List.unmodifiable(shortAverage),
       longAverage = List.unmodifiable(longAverage);

  /// Línea de cierres.
  final List<ChartPoint> closes;

  /// Media de 50 sesiones; vacía si está desactivada o no hay datos.
  final List<ChartPoint> shortAverage;

  /// Media de 200 sesiones; vacía si está desactivada o no hay datos.
  final List<ChartPoint> longAverage;

  /// Máximo y mínimo de cierre del periodo (sobre todos los cierres, no solo
  /// los puntos agrupados).
  final CloseExtremes? extremes;
}

/// Estado de la gráfica de precio de la pestaña Resumen: carga del histórico,
/// periodo, interruptores de medias y los datos que se dibujan.
class PriceChartController extends ChangeNotifier {
  PriceChartController({required this._getPriceHistory, required this.symbol});

  final GetPriceHistoryUseCase _getPriceHistory;
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

  /// Histórico cargado; `null` hasta que llega.
  List<DailyBar>? get bars => _bars;

  bool get isLoading => _isLoading;

  /// Error del último intento. Si ya había histórico se conserva y se sigue
  /// dibujando.
  MarketDataException? get error => _error;

  ChartRange get range => _range;

  bool get showShortAverage => _showShortAverage;

  bool get showLongAverage => _showLongAverage;

  /// Datos para dibujar; `null` mientras no haya histórico.
  PriceChartView? get view => _view;

  /// Carga el histórico. Con [forceRefresh] lo vuelve a pedir al proveedor.
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
    try {
      _bars = await _getPriceHistory(symbol, forceRefresh: forceRefresh);
      _recompute();
    } on MarketDataException catch (error) {
      _error = error;
    } finally {
      _isLoading = false;
      _notify();
    }
    if (_hasPendingRefresh && !_isDisposed) {
      _hasPendingRefresh = false;
      await load(forceRefresh: true);
    }
  }

  void selectRange(ChartRange range) {
    if (range == _range) return;
    _range = range;
    _recompute();
    _notify();
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

  void _recompute() {
    final bars = _bars;
    if (bars == null) return;
    final slice = sliceRange(bars, _range);
    final closes = closePoints(slice);
    _view = PriceChartView(
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
