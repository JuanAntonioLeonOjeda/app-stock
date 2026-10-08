import 'package:stock_app/features/analisis_accion/domain/entities/intraday_bar.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/intraday_series.dart';

/// [sessions] sesiones intradía en días laborables consecutivos desde el lunes
/// 28 de septiembre de 2026, cada una de [perSession] velas; la de la mitad
/// de la última sesión es el máximo.
IntradaySeries intradaySeries({
  int sessions = 7,
  int perSession = 12,
  String? timezone = 'Europe/Madrid',
  Duration? delay = const Duration(minutes: 15),
}) {
  final bars = <IntradayBar>[];
  for (var day = 0; day < sessions; day++) {
    // Lunes a viernes; el fin de semana se salta.
    final date = DateTime.utc(
      2026,
      9,
      28,
    ).add(Duration(days: day + (day ~/ 5) * 2));
    for (var i = 0; i < perSession; i++) {
      final isPeak = day == sessions - 1 && i == perSession ~/ 2;
      bars.add(
        IntradayBar(
          time: date.add(Duration(hours: 7, minutes: 30 * i)),
          close: isPeak ? 500 : 100.0 + day + i * 0.1,
        ),
      );
    }
  }
  return IntradaySeries(bars: bars, timezone: timezone, delay: delay);
}
