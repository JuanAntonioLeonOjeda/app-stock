import 'package:stock_app/features/analisis_accion/domain/entities/intraday_bar.dart';

/// Hueco mayor que este entre dos velas = cambio de sesión. La pausa de la
/// comida de Tokio dura 1 hora y la noche, más de 15: así el corte no depende
/// de la zona horaria.
const sessionGap = Duration(hours: 3);

/// Agrupa las velas en sesiones: rachas sin un hueco de más de [maxGap].
List<List<IntradayBar>> splitSessions(
  List<IntradayBar> bars, {
  Duration maxGap = sessionGap,
}) {
  final sessions = <List<IntradayBar>>[];
  for (final bar in bars) {
    final isNewSession =
        sessions.isEmpty ||
        bar.time.difference(sessions.last.last.time) > maxGap;
    if (isNewSession) {
      sessions.add([bar]);
    } else {
      sessions.last.add(bar);
    }
  }
  return sessions;
}

/// Las velas de las últimas sesiones y dónde empieza cada una.
typedef SessionSlice = ({List<IntradayBar> bars, List<int> starts});

/// Las velas de las últimas [count] sesiones, pegadas y en orden, con la
/// posición de la primera vela de cada sesión. Si hay menos sesiones, devuelve
/// las que haya (criterio 67).
SessionSlice lastSessions(List<IntradayBar> bars, int count) {
  final sessions = splitSessions(bars);
  final first = sessions.length > count ? sessions.length - count : 0;
  final shown = sessions.skip(first);
  final starts = <int>[];
  var position = 0;
  for (final session in shown) {
    starts.add(position);
    position += session.length;
  }
  return (bars: [for (final session in shown) ...session], starts: starts);
}
