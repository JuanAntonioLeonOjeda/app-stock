import 'package:stock_app/features/analisis_accion/domain/entities/intraday_bar.dart';

/// Velas intradía de una acción con lo que hace falta para mostrarlas bien.
class IntradaySeries {
  IntradaySeries({
    required List<IntradayBar> bars,
    required this.timezone,
    required this.delay,
  }) : bars = List.unmodifiable(bars);

  /// De la más antigua a la más reciente.
  final List<IntradayBar> bars;

  /// Zona horaria de la bolsa (nombre IANA, p. ej. `Europe/Madrid`); `null` si
  /// el proveedor no la dio.
  final String? timezone;

  /// Retraso con el que el proveedor da los precios; `null` si no lo indica.
  final Duration? delay;
}
