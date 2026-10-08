import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/daily_bar.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/intraday_bar.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/intraday_series.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/tradingview_history_cache.dart';

void main() {
  group('histórico diario guardado', () {
    final bars = [
      DailyBar(
        date: DateTime.utc(2026, 10, 7),
        open: 10,
        high: 12,
        low: 9,
        close: 11,
        volume: 500,
      ),
      DailyBar(
        date: DateTime.utc(2026, 10, 8),
        open: 11,
        high: 13,
        low: 10.5,
        close: 12.25,
        volume: 700,
      ),
    ];

    test('se recupera exactamente lo guardado', () {
      final restored = decodeHistory(encodeHistory(bars));

      expect(restored, hasLength(2));
      expect(restored.last.date, DateTime.utc(2026, 10, 8));
      expect(restored.last.close, 12.25);
      expect(restored.first.volume, 500);
    });

    test('un texto con otra forma es respuesta inválida', () {
      expect(
        () => decodeHistory('{"formato":"antiguo"}'),
        throwsA(isA<InvalidResponseException>()),
      );
      expect(
        () => decodeHistory('[[1,2,3]]'),
        throwsA(isA<InvalidResponseException>()),
      );
      expect(
        () => decodeHistory('no json'),
        throwsA(isA<InvalidResponseException>()),
      );
    });
  });

  group('intradía guardado', () {
    final series = IntradaySeries(
      bars: [
        IntradayBar(time: DateTime.utc(2026, 10, 8, 7), close: 21.1),
        IntradayBar(time: DateTime.utc(2026, 10, 8, 7, 5), close: 21.15),
      ],
      timezone: 'Europe/Madrid',
      delay: const Duration(minutes: 15),
    );

    test('se recupera con su zona y su retraso', () {
      final restored = decodeIntraday(encodeIntraday(series));

      expect(restored.timezone, 'Europe/Madrid');
      expect(restored.delay, const Duration(minutes: 15));
      expect(restored.bars, hasLength(2));
      expect(restored.bars.last.time, DateTime.utc(2026, 10, 8, 7, 5));
      expect(restored.bars.last.close, 21.15);
    });

    test('sin zona ni retraso se guarda como ausente, no como 0', () {
      final restored = decodeIntraday(
        encodeIntraday(
          IntradaySeries(bars: series.bars, timezone: null, delay: null),
        ),
      );

      expect(restored.timezone, isNull);
      expect(restored.delay, isNull);
    });

    test('un texto con otra forma es respuesta inválida', () {
      for (final text in ['[]', '{"bars":"x"}', '{"bars":[[1]]}', 'no json']) {
        expect(
          () => decodeIntraday(text),
          throwsA(isA<InvalidResponseException>()),
          reason: text,
        );
      }
    });
  });
}
