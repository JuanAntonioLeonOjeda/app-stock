/// Un punto intradía: el cierre de una vela de minutos.
class IntradayBar {
  const IntradayBar({required this.time, required this.close});

  /// Instante en que empieza la vela, en UTC.
  final DateTime time;
  final double close;
}
