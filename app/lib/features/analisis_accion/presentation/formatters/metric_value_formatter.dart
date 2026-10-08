// ÚNICO punto donde un valor numérico o una fecha se convierten en texto.
// Aquí, y solo aquí, una fracción se multiplica por 100 para mostrarla como
// porcentaje (naming-conventions.md).

import 'package:intl/intl.dart';
import 'package:stock_app/features/analisis_accion/domain/chart/chart_range.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';

/// Texto para una métrica sin dato.
const noDataText = 'sin dato';

final _oneDecimal = NumberFormat('#,##0.0', 'es');
final _twoDecimals = NumberFormat('#,##0.00', 'es');
final _noDecimals = NumberFormat('#,##0', 'es');

/// Valor de una métrica según su formato; [noDataText] si es `null`.
String formatMetricValue(double? value, MetricFormat format) {
  if (value == null) return noDataText;
  return switch (format) {
    MetricFormat.percent => '${_oneDecimal.format(value * 100)} %',
    MetricFormat.multiple => '${_oneDecimal.format(value)}x',
    MetricFormat.decimal => _twoDecimals.format(value),
    MetricFormat.count => _noDecimals.format(value),
  };
}

/// Nota 0-10 con un decimal ("8,3"), o "–" si no hay nota.
String formatScore(double? score) =>
    score == null ? '–' : _oneDecimal.format(score);

/// Fracción como porcentaje sin decimales (p. ej. la cobertura: "80 %").
String formatWholePercent(double fraction) =>
    '${_noDecimals.format(fraction * 100)} %';

/// Precio con dos decimales y su divisa ("219,99 USD").
String formatPrice(double? price, String? currency) {
  if (price == null) return noDataText;
  final amount = _twoDecimals.format(price);
  return currency == null ? amount : '$amount $currency';
}

/// Fecha como "29/09/2026".
String formatDate(DateTime date) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  return '${twoDigits(date.day)}/${twoDigits(date.month)}/${date.year}';
}

const _months = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

/// Fecha corta para el eje de la gráfica: "12 sep" en periodos de hasta un
/// año y "sep 25" en los más largos, donde el día no se distingue.
String formatChartAxisDate(DateTime date, ChartRange range) {
  final month = _months[date.month - 1];
  final days = range.days;
  final isShort = days != null && days <= 365;
  if (isShort) return '${date.day} $month';
  return '$month ${(date.year % 100).toString().padLeft(2, '0')}';
}

/// Precio compacto para el eje de la gráfica: más decimales cuanto más
/// pequeño es el valor.
String formatChartAxisPrice(double price) {
  if (price >= 1000) return _noDecimals.format(price);
  if (price >= 10) return _oneDecimal.format(price);
  return _twoDecimals.format(price);
}

/// Antigüedad en palabras: "hace 5 minutos", "hace 1 hora", "hace 3 días".
String formatAge(Duration age) {
  if (age.inDays >= 1) return 'hace ${_plural(age.inDays, 'día', 'días')}';
  if (age.inHours >= 1) {
    return 'hace ${_plural(age.inHours, 'hora', 'horas')}';
  }
  final minutes = age.inMinutes < 1 ? 1 : age.inMinutes;
  return 'hace ${_plural(minutes, 'minuto', 'minutos')}';
}

String _plural(int count, String singular, String plural) =>
    '$count ${count == 1 ? singular : plural}';
