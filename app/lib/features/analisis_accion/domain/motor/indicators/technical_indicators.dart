// Indicadores técnicos sobre cierres diarios en orden ascendente.
// Fórmulas: references/metricas.md, sección 1. Todos devuelven null si no hay
// datos suficientes.

/// Media simple de los últimos [period] valores.
double? sma(List<double> closes, int period) {
  if (period <= 0 || closes.length < period) return null;
  return _mean(closes.sublist(closes.length - period));
}

/// Serie completa de la media exponencial: semilla = media simple de los
/// [period] primeros valores; después `ema = valor·k + ema_anterior·(1−k)`,
/// con `k = 2/(period+1)`. El primer elemento corresponde al índice
/// `period − 1` de [values].
List<double>? emaSeries(List<double> values, int period) {
  if (period <= 0 || values.length < period) return null;
  final k = 2 / (period + 1);
  var current = _mean(values.sublist(0, period));
  final series = [current];
  for (final value in values.skip(period)) {
    current = value * k + current * (1 - k);
    series.add(current);
  }
  return series;
}

/// RSI de Wilder. Sin bajadas: 100 (o 50 si tampoco hay subidas).
/// Requiere al menos `period + 1` cierres.
double? rsi(List<double> closes, {int period = 14}) {
  if (closes.length < period + 1) return null;
  final changes = [
    for (var i = 1; i < closes.length; i++) closes[i] - closes[i - 1],
  ];
  final seed = changes.take(period).toList();
  var averageGain = _mean(seed.map(_gain).toList());
  var averageLoss = _mean(seed.map(_loss).toList());
  for (final change in changes.skip(period)) {
    averageGain = (averageGain * (period - 1) + _gain(change)) / period;
    averageLoss = (averageLoss * (period - 1) + _loss(change)) / period;
  }
  if (averageLoss == 0) return averageGain == 0 ? 50 : 100;
  return 100 - 100 / (1 + averageGain / averageLoss);
}

/// Valores actuales del MACD y el histograma de la sesión anterior (para
/// saber si sube o baja).
class Macd {
  const Macd({
    required this.line,
    required this.signal,
    required this.histogram,
    required this.previousHistogram,
  });

  final double line;
  final double signal;
  final double histogram;
  final double previousHistogram;
}

/// MACD(12, 26, 9). Requiere al menos `slow + signalPeriod` cierres (35).
Macd? macd(
  List<double> closes, {
  int fast = 12,
  int slow = 26,
  int signalPeriod = 9,
}) {
  if (closes.length < slow + signalPeriod) return null;
  final fastEma = emaSeries(closes, fast);
  final slowEma = emaSeries(closes, slow);
  if (fastEma == null || slowEma == null) return null;

  // fastEma empieza en el índice fast−1 y slowEma en slow−1: se alinean.
  final offset = slow - fast;
  final line = [
    for (var i = 0; i < slowEma.length; i++) fastEma[i + offset] - slowEma[i],
  ];
  final signal = emaSeries(line, signalPeriod);
  if (signal == null) return null;
  final histogram = [
    for (var i = 0; i < signal.length; i++)
      line[i + signalPeriod - 1] - signal[i],
  ];
  if (histogram.length < 2) return null;
  return Macd(
    line: line.last,
    signal: signal.last,
    histogram: histogram.last,
    previousHistogram: histogram[histogram.length - 2],
  );
}

/// Pendiente de la media de [period] sesiones: media hoy / media hace
/// [lookback] sesiones − 1. Requiere `period + lookback` cierres.
double? smaSlope(List<double> closes, {int period = 200, int lookback = 20}) {
  if (closes.length < period + lookback) return null;
  final current = sma(closes, period);
  final past = sma(closes.sublist(0, closes.length - lookback), period);
  if (current == null || past == null || past == 0) return null;
  return current / past - 1;
}

/// Caída máxima en las últimas [window] sesiones: mínimo de
/// `cierre / máximo acumulado − 1` (≤ 0).
double? maxDrawdown(List<double> closes, {int window = 252}) {
  if (closes.length < window) return null;
  var peak = double.negativeInfinity;
  var worst = 0.0;
  for (final close in closes.sublist(closes.length - window)) {
    if (close > peak) peak = close;
    final drawdown = close / peak - 1;
    if (drawdown < worst) worst = drawdown;
  }
  return worst;
}

/// Máximo de los últimos [window] valores (p. ej. máximo de 52 semanas).
double? maxOfLast(List<double> values, {int window = 252}) {
  if (values.length < window) return null;
  return values.sublist(values.length - window).reduce((a, b) => a > b ? a : b);
}

double _mean(List<double> values) =>
    values.reduce((a, b) => a + b) / values.length;

double _gain(double change) => change > 0 ? change : 0;

double _loss(double change) => change < 0 ? -change : 0;
