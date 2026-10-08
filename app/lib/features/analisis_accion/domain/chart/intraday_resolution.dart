/// Tamaño de las velas intradía que se piden y cuántas, según el periodo.
enum IntradayResolution {
  /// Velas de 5 minutos, para la sesión de hoy (criterio 59). 400 cubren más
  /// de una sesión en cualquier bolsa habitual.
  minutes5(5, 400),

  /// Velas de 30 minutos, para las últimas 5 sesiones (criterio 60).
  minutes30(30, 200);

  const IntradayResolution(this.minutes, this.barsToRequest);

  final int minutes;
  final int barsToRequest;
}
