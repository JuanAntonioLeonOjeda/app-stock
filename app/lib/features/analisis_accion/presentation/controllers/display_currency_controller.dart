import 'package:flutter/foundation.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/get_exchange_rates_use_case.dart';
import 'package:stock_app/features/analisis_accion/domain/currency/euro_conversion.dart';
import 'package:stock_app/features/analisis_accion/domain/currency/quote_currency.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/exchange_rate_series.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';

/// Con un último tipo más antiguo que esto se avisa de que está desfasado
/// (criterio 97).
const staleRateAge = Duration(days: 5);

/// En qué punto está la conversión a euros.
enum CurrencyStatus {
  /// No hay nada que convertir: ya cotiza en euros o aún no se sabe la moneda.
  none,

  /// Se están pidiendo los tipos; mientras tanto se ve la divisa original.
  loading,

  /// Hay tipos: se puede mostrar en euros y cambiar a la divisa original.
  ready,

  /// No hay tipo de cambio publicado para esa moneda (criterio 92).
  unsupported,

  /// No se han podido obtener los tipos (criterio 93).
  failed,
}

/// Qué moneda se muestra: euros por defecto, con selector para la divisa
/// original (criterios 84-97).
///
/// Solo cambia lo que se pinta: el motor y el historial siguen en la divisa
/// original. Cada resultado crea el suyo y empieza en euros, sin recordar la
/// elección entre resultados.
class DisplayCurrencyController extends ChangeNotifier {
  DisplayCurrencyController({
    required this._getExchangeRates,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final GetExchangeRatesUseCase _getExchangeRates;
  final DateTime Function() _now;

  String? _quoteCode;
  QuoteCurrency? _currency;
  CurrencyStatus _status = CurrencyStatus.none;
  ExchangeRateSeries? _rates;
  bool _showOriginal = false;
  bool _isDisposed = false;
  int _requestId = 0;
  bool _isLoading = false;
  bool _hasPendingRefresh = false;

  CurrencyStatus get status => _status;

  /// La moneda tal como cotiza (`JPY`, `GBX`...); `null` si aún no se sabe.
  String? get quoteCode => _quoteCode;

  /// La moneda con tipo de cambio (`GBP` para los `GBX`).
  String? get isoCode => _currency?.isoCode;

  /// Hay tipos y se puede cambiar entre euros y divisa original.
  bool get canSwitch => _status == CurrencyStatus.ready;

  /// Lo que se ve ahora está en euros y convertido.
  bool get isInEuros => _status == CurrencyStatus.ready && !_showOriginal;

  bool get isConverting => _status == CurrencyStatus.loading;

  /// El texto de la moneda que se ve: `EUR`, o la de cotización.
  String? get currencyLabel => isInEuros ? 'EUR' : _quoteCode;

  /// El último tipo publicado.
  RatePoint? get latestRate => _rates?.latest;

  /// El tipo que se aplica a [day] (el último publicado hasta ese día).
  RatePoint? rateOn(DateTime day) => _rates?.pointOn(day);

  /// El último tipo tiene más de [staleRateAge] (criterio 97).
  bool get isRateStale {
    final latest = latestRate;
    return latest != null && _now().difference(latest.date) > staleRateAge;
  }

  /// Cuántos días tiene el último tipo.
  int? get latestRateAgeInDays {
    final latest = latestRate;
    return latest == null ? null : _now().difference(latest.date).inDays;
  }

  /// Indica la moneda del resultado y pide los tipos si hace falta. No hace
  /// nada si ya está configurado con esa moneda.
  Future<void> configure(String? quoteCode) async {
    final resolved = resolveQuoteCurrency(quoteCode);
    final normalized = quoteCode?.trim().toUpperCase();
    if (normalized == _quoteCode && resolved?.isoCode == _currency?.isoCode) {
      return;
    }
    _quoteCode = normalized;
    _currency = resolved;
    _rates = null;
    _showOriginal = false;
    if (resolved == null || resolved.isEuro) {
      _status = CurrencyStatus.none;
      _notify();
      return;
    }
    await _load(resolved, forceRefresh: false);
  }

  /// Vuelve a pedir los tipos ("Reintentar" y "Actualizar datos").
  Future<void> reload({bool forceRefresh = false}) async {
    final currency = _currency;
    if (currency == null || currency.isEuro) return;
    if (_isLoading) {
      _hasPendingRefresh = _hasPendingRefresh || forceRefresh;
      return;
    }
    await _load(currency, forceRefresh: forceRefresh);
  }

  /// Elige ver la divisa original ([original] verdadero) o los euros.
  void showOriginal({required bool original}) {
    if (_showOriginal == original) return;
    _showOriginal = original;
    _notify();
  }

  /// [value] en la moneda que se ve, para el [day] dado. Con euros, `null` si
  /// no hay tipo para ese día; en la divisa original, el mismo valor.
  double? toDisplay(double value, DateTime day) {
    final currency = _currency;
    if (!isInEuros || currency == null) return value;
    return toEuros(value, currency: currency, rates: _rates, day: day);
  }

  /// Como [toDisplay], con el último tipo publicado (día y semana, criterio
  /// 88).
  double? toDisplayLatest(double value) {
    final latest = latestRate;
    if (!isInEuros || latest == null) return isInEuros ? null : value;
    return toDisplay(value, latest.date);
  }

  Future<void> _load(
    QuoteCurrency currency, {
    required bool forceRefresh,
  }) async {
    final request = ++_requestId;
    // Al refrescar, los tipos que ya hay se siguen usando: la pantalla no
    // salta a la divisa original mientras llegan los nuevos.
    final hadRates = _rates != null && _status == CurrencyStatus.ready;
    if (!hadRates) {
      _status = CurrencyStatus.loading;
      _notify();
    }
    _isLoading = true;
    try {
      final rates = await _getExchangeRates(
        currency.isoCode,
        forceRefresh: forceRefresh,
      );
      if (request != _requestId) return;
      _rates = rates;
      _status = CurrencyStatus.ready;
    } on NotFoundException {
      if (request != _requestId) return;
      _status = CurrencyStatus.unsupported;
    } on MarketDataException {
      if (request != _requestId) return;
      if (!hadRates) _status = CurrencyStatus.failed;
    } finally {
      if (request == _requestId) {
        _isLoading = false;
        _notify();
        await _repeatPendingRefresh(currency);
      }
    }
  }

  /// Si mientras cargaba se pidió una actualización forzada, la repite.
  Future<void> _repeatPendingRefresh(QuoteCurrency currency) async {
    if (!_hasPendingRefresh) return;
    _hasPendingRefresh = false;
    await _load(currency, forceRefresh: true);
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
