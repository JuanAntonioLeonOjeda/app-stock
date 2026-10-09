// Conversión de precios a euros con el tipo de referencia de cada día. Funciones
// puras: devuelven `null` donde no hay tipo y nunca inventan uno.

import 'package:stock_app/features/analisis_accion/domain/currency/quote_currency.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/exchange_rate_series.dart';

/// [value] en [currency] pasado a euros con el tipo publicado en [day] (o el
/// último anterior). Una acción que ya cotiza en euros no cambia. `null` si no
/// hay tipo para ese día.
double? toEuros(
  double value, {
  required QuoteCurrency currency,
  required ExchangeRateSeries? rates,
  required DateTime day,
}) {
  if (currency.isEuro) return value;
  final rate = rates?.rateOn(day);
  if (rate == null || rate <= 0) return null;
  return value / currency.subunitDivisor / rate;
}
