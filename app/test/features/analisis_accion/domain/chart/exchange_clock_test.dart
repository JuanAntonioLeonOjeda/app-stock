import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/chart/exchange_clock.dart';

int? _offset(DateTime utc, String zone) => exchangeOffsetMinutes(utc, zone);

void main() {
  group('zonas sin cambio de hora', () {
    test('Tokio es siempre UTC+9', () {
      expect(_offset(DateTime.utc(2026, 1, 15), 'Asia/Tokyo'), 540);
      expect(_offset(DateTime.utc(2026, 7, 15), 'Asia/Tokyo'), 540);
    });

    test('Hong Kong y Shanghái son UTC+8; Calcuta, UTC+5:30', () {
      expect(_offset(DateTime.utc(2026, 7, 1), 'Asia/Hong_Kong'), 480);
      expect(_offset(DateTime.utc(2026, 7, 1), 'Asia/Shanghai'), 480);
      expect(_offset(DateTime.utc(2026, 7, 1), 'Asia/Kolkata'), 330);
    });
  });

  group('zonas europeas', () {
    test('Madrid: UTC+1 en invierno y UTC+2 en verano', () {
      expect(_offset(DateTime.utc(2026, 1, 15), 'Europe/Madrid'), 60);
      expect(_offset(DateTime.utc(2026, 10, 8), 'Europe/Madrid'), 120);
    });

    test('el cambio a verano es el último domingo de marzo a la 01:00 UTC', () {
      // 2026-03-29 es el último domingo de marzo.
      expect(_offset(DateTime.utc(2026, 3, 29, 0, 59), 'Europe/Madrid'), 60);
      expect(_offset(DateTime.utc(2026, 3, 29, 1), 'Europe/Madrid'), 120);
    });

    test(
      'el cambio a invierno es el último domingo de octubre a la 01:00 UTC',
      () {
        // 2026-10-25 es el último domingo de octubre.
        expect(
          _offset(DateTime.utc(2026, 10, 25, 0, 59), 'Europe/Madrid'),
          120,
        );
        expect(_offset(DateTime.utc(2026, 10, 25, 1), 'Europe/Madrid'), 60);
      },
    );

    test('Londres: UTC+0 en invierno y UTC+1 en verano', () {
      expect(_offset(DateTime.utc(2026, 1, 15), 'Europe/London'), 0);
      expect(_offset(DateTime.utc(2026, 7, 15), 'Europe/London'), 60);
    });

    test('Helsinki: UTC+2 en invierno y UTC+3 en verano', () {
      expect(_offset(DateTime.utc(2026, 1, 15), 'Europe/Helsinki'), 120);
      expect(_offset(DateTime.utc(2026, 7, 15), 'Europe/Helsinki'), 180);
    });
  });

  group('zonas norteamericanas', () {
    test('Nueva York: UTC-5 en invierno y UTC-4 en verano', () {
      expect(_offset(DateTime.utc(2026, 1, 15), 'America/New_York'), -300);
      expect(_offset(DateTime.utc(2026, 7, 15), 'America/New_York'), -240);
    });

    test(
      'el cambio a verano es el segundo domingo de marzo a las 02:00 locales',
      () {
        // 2026-03-08 es el segundo domingo de marzo; 02:00 EST = 07:00 UTC.
        expect(
          _offset(DateTime.utc(2026, 3, 8, 6, 59), 'America/New_York'),
          -300,
        );
        expect(_offset(DateTime.utc(2026, 3, 8, 7), 'America/New_York'), -240);
      },
    );

    test('el cambio a invierno es el primer domingo de noviembre a las 02:00 locales', () {
      // 2026-11-01 es el primer domingo de noviembre; 02:00 EDT = 06:00 UTC.
      expect(
        _offset(DateTime.utc(2026, 11, 1, 5, 59), 'America/New_York'),
        -240,
      );
      expect(_offset(DateTime.utc(2026, 11, 1, 6), 'America/New_York'), -300);
    });

    test('Los Ángeles: UTC-8 en invierno y UTC-7 en verano', () {
      expect(_offset(DateTime.utc(2026, 1, 15), 'America/Los_Angeles'), -480);
      expect(_offset(DateTime.utc(2026, 7, 15), 'America/Los_Angeles'), -420);
    });

    test('el cambio de Los Ángeles usa su propia hora local', () {
      // 02:00 PST = 10:00 UTC.
      expect(
        _offset(DateTime.utc(2026, 3, 8, 9, 59), 'America/Los_Angeles'),
        -480,
      );
      expect(
        _offset(DateTime.utc(2026, 3, 8, 10), 'America/Los_Angeles'),
        -420,
      );
    });
  });

  group('exchangeWallClock', () {
    test('devuelve los campos de la hora local de la bolsa', () {
      // Iberdrola: 14:50 UTC del 8 de octubre = 16:50 en Madrid (verano).
      final wall = exchangeWallClock(
        DateTime.utc(2026, 10, 8, 14, 50),
        'Europe/Madrid',
      )!;

      expect(wall.hour, 16);
      expect(wall.minute, 50);
      expect(wall.day, 8);
    });

    test('puede cambiar el día respecto a UTC', () {
      // 20:00 UTC del 8 de octubre en Tokio ya es el 9 a las 05:00.
      final wall = exchangeWallClock(
        DateTime.utc(2026, 10, 8, 20),
        'Asia/Tokyo',
      )!;

      expect(wall.day, 9);
      expect(wall.hour, 5);
    });

    test('la apertura de Nueva York cae a las 09:30', () {
      final wall = exchangeWallClock(
        DateTime.utc(2026, 10, 8, 13, 30),
        'America/New_York',
      )!;

      expect(wall.hour, 9);
      expect(wall.minute, 30);
    });

    test('una zona desconocida o ausente devuelve null', () {
      expect(
        exchangeWallClock(DateTime.utc(2026, 10, 8), 'Mars/Olympus'),
        isNull,
      );
      expect(exchangeWallClock(DateTime.utc(2026, 10, 8), null), isNull);
      expect(
        exchangeOffsetMinutes(DateTime.utc(2026, 10, 8), 'Australia/Sydney'),
        isNull,
      );
    });
  });
}
