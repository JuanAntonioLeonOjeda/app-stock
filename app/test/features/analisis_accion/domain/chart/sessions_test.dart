import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/chart/sessions.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/intraday_bar.dart';

/// Velas cada [stepMinutes] minutos desde [start], [count] seguidas.
List<IntradayBar> _run(DateTime start, int count, {int stepMinutes = 30}) => [
  for (var i = 0; i < count; i++)
    IntradayBar(
      time: start.add(Duration(minutes: i * stepMinutes)),
      close: 100.0 + i,
    ),
];

void main() {
  // Lunes 5 y martes 6 de octubre de 2026 (sesiones de Madrid en UTC).
  final monday = DateTime.utc(2026, 10, 5, 7);
  final tuesday = DateTime.utc(2026, 10, 6, 7);
  final friday = DateTime.utc(2026, 10, 9, 7);

  group('splitSessions', () {
    test('una racha continua es una sola sesión', () {
      expect(splitSessions(_run(monday, 17)), hasLength(1));
    });

    test('la noche separa dos sesiones', () {
      final bars = [..._run(monday, 17), ..._run(tuesday, 17)];

      final sessions = splitSessions(bars);

      expect(sessions, hasLength(2));
      expect(sessions.first, hasLength(17));
      expect(sessions.last.first.time, tuesday);
    });

    test('el fin de semana también separa sesiones', () {
      final bars = [
        ..._run(friday, 5),
        ..._run(DateTime.utc(2026, 10, 12, 7), 5),
      ];

      expect(splitSessions(bars), hasLength(2));
    });

    test('la pausa de la comida de Tokio (1 hora) no corta la sesión', () {
      // 09:00-11:30 JST = 00:00-02:30 UTC; reanuda a las 12:30 JST = 03:30 UTC.
      final morning = _run(DateTime.utc(2026, 10, 8, 0), 6);
      final afternoon = _run(DateTime.utc(2026, 10, 8, 3, 30), 6);

      expect(splitSessions([...morning, ...afternoon]), hasLength(1));
    });

    test('sin velas no hay sesiones', () {
      expect(splitSessions(const []), isEmpty);
    });
  });

  group('lastSessions', () {
    List<IntradayBar> days(int n) => [
      for (var d = 0; d < n; d++) ..._run(monday.add(Duration(days: d)), 4),
    ];

    test('devuelve solo las últimas sesiones pedidas, pegadas y en orden', () {
      final result = lastSessions(days(8), 5);

      expect(splitSessions(result.bars), hasLength(5));
      expect(result.bars.first.time, monday.add(const Duration(days: 3)));
      expect(result.bars.last.time, days(8).last.time);
    });

    test('indica dónde empieza cada sesión', () {
      final result = lastSessions(days(8), 5);

      expect(result.starts, [0, 4, 8, 12, 16]);
    });

    test(
      'con menos sesiones de las pedidas devuelve las que haya (criterio 67)',
      () {
        final result = lastSessions(days(2), 5);

        expect(splitSessions(result.bars), hasLength(2));
        expect(result.bars, hasLength(8));
        expect(result.starts, [0, 4]);
      },
    );

    test('una sesión pedida devuelve la última', () {
      final result = lastSessions(days(3), 1);

      expect(result.bars, hasLength(4));
      expect(result.bars.first.time, monday.add(const Duration(days: 2)));
      expect(result.starts, [0]);
    });

    test('sin velas devuelve listas vacías', () {
      final result = lastSessions(const [], 5);

      expect(result.bars, isEmpty);
      expect(result.starts, isEmpty);
    });
  });
}
