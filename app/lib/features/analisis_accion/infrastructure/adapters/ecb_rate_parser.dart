// Respuesta SDMX/JSON del BCE (tipos de referencia diarios) → serie de tipos.
// La fecha de cada observación no está en ella: está en la estructura, en el
// mismo orden que sus índices.

import 'dart:convert';

import 'package:stock_app/features/analisis_accion/domain/entities/exchange_rate_series.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';

/// Tipos de [currency] frente al euro a partir de la respuesta del BCE.
///
/// Lanza `InvalidResponseException` si la forma no es la esperada y
/// `NotFoundException` si no trae ninguna observación.
ExchangeRateSeries parseEcbRates(String body, String currency) {
  final Object? decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException {
    throw const InvalidResponseException('El BCE no respondió con JSON');
  }
  final dates = _dates(decoded);
  final observations = _observations(decoded);
  final points = <RatePoint>[];
  for (final MapEntry(key: index, value: value) in observations.entries) {
    final position = int.tryParse(index);
    final rate = value is List<Object?> && value.isNotEmpty
        ? value.first
        : null;
    if (position == null || position >= dates.length || rate is! num) continue;
    if (rate <= 0) continue;
    points.add(RatePoint(dates[position], rate.toDouble()));
  }
  if (points.isEmpty) {
    throw NotFoundException('El BCE no trae tipos para $currency');
  }
  return ExchangeRateSeries(currency: currency, points: points);
}

/// Las fechas de las observaciones, en el orden de sus índices.
List<DateTime> _dates(Object? decoded) {
  final structure = decoded is Map<String, Object?>
      ? decoded['structure']
      : null;
  final dimensions = structure is Map<String, Object?>
      ? structure['dimensions']
      : null;
  final observation = dimensions is Map<String, Object?>
      ? dimensions['observation']
      : null;
  final first = observation is List<Object?> && observation.isNotEmpty
      ? observation.first
      : null;
  final values = first is Map<String, Object?> ? first['values'] : null;
  if (values is! List<Object?>) {
    throw const InvalidResponseException('El BCE no trae las fechas');
  }
  return [for (final value in values) _date(value is Map ? value['id'] : null)];
}

DateTime _date(Object? id) {
  final parsed = id is String ? DateTime.tryParse(id) : null;
  if (parsed == null) {
    throw const InvalidResponseException('El BCE trae una fecha ilegible');
  }
  return DateTime.utc(parsed.year, parsed.month, parsed.day);
}

/// Las observaciones de la única serie de la respuesta.
Map<String, Object?> _observations(Object? decoded) {
  final dataSets = decoded is Map<String, Object?> ? decoded['dataSets'] : null;
  final first = dataSets is List<Object?> && dataSets.isNotEmpty
      ? dataSets.first
      : null;
  final series = first is Map<String, Object?> ? first['series'] : null;
  if (series is! Map<String, Object?>) {
    throw const InvalidResponseException('El BCE no trae series');
  }
  if (series.isEmpty) return const {};
  final only = series.values.first;
  final observations = only is Map<String, Object?>
      ? only['observations']
      : null;
  if (observations is! Map<String, Object?>) {
    throw const InvalidResponseException('El BCE no trae observaciones');
  }
  return observations;
}
