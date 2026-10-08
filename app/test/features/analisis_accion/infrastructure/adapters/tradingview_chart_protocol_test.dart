import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/tradingview_chart_protocol.dart';

import '../../../../fixtures/tradingview_fixtures.dart';

/// Mensaje `timescale_update` con las velas dadas como `[t, o, h, l, c, v]`.
String _timescale(List<List<Object?>> bars) => jsonEncode({
  'm': 'timescale_update',
  'p': [
    'cs_x',
    {
      'sds_1': {
        's': [
          for (var i = 0; i < bars.length; i++) {'i': i, 'v': bars[i]},
        ],
      },
    },
  ],
});

// 2026-10-07 00:00 UTC.
const _day = 1791331200;

void main() {
  group('frameMessage', () {
    test('antepone la longitud entre marcas', () {
      expect(frameMessage('hola'), '~m~4~m~hola');
    });

    test('un latido se enmarca igual', () {
      expect(frameMessage('~h~12'), '~m~5~m~~h~12');
    });
  });

  group('splitFrames', () {
    test('parte un paquete con varios mensajes', () {
      expect(splitFrames('~m~3~m~abc~m~2~m~de'), ['abc', 'de']);
    });

    test('un paquete sin mensajes da una lista vacía', () {
      expect(splitFrames(''), isEmpty);
    });

    test('parte el paquete real de la transcripción', () {
      final transcript = readChartTranscript('chart_tse_7974');

      final messages = [for (final p in transcript.received) ...splitFrames(p)];

      // Sesión, series_loading, symbol_resolved, timescale_update, completed.
      expect(messages, hasLength(5));
    });

    test('un marco truncado es una respuesta inválida', () {
      expect(
        () => splitFrames('~m~10~m~corto'),
        throwsA(isA<InvalidResponseException>()),
      );
    });

    test('un paquete sin marca es una respuesta inválida', () {
      expect(
        () => splitFrames('sin marco'),
        throwsA(isA<InvalidResponseException>()),
      );
    });

    test('una longitud ilegible es una respuesta inválida', () {
      expect(
        () => splitFrames('~m~xx~m~abc'),
        throwsA(isA<InvalidResponseException>()),
      );
    });
  });

  group('buildHistoryRequest', () {
    final request = buildHistoryRequest(
      session: 'cs_abc',
      ticker: 'TSE:7974',
      bars: 6000,
    );
    final decoded = [
      for (final message in request)
        jsonDecode(splitFrames(message).single) as Map<String, Object?>,
    ];

    test('manda los cuatro mensajes en el orden del protocolo', () {
      expect(decoded.map((m) => m['m']), [
        'set_auth_token',
        'chart_create_session',
        'resolve_symbol',
        'create_series',
      ]);
    });

    test('resuelve el símbolo con ajuste por splits', () {
      final params = decoded[2]['p']! as List<Object?>;

      expect(params[0], 'cs_abc');
      expect(params[2], contains('"symbol":"TSE:7974"'));
      expect(params[2], contains('"adjustment":"splits"'));
    });

    test('pide velas diarias y el número indicado', () {
      final params = decoded[3]['p']! as List<Object?>;

      expect(params, contains('D'));
      expect(params, contains(6000));
    });
  });

  group('parseChartMessage', () {
    test('un latido se reconoce como tal', () {
      final event = parseChartMessage('~h~12');

      expect(event, isA<Heartbeat>());
      expect((event as Heartbeat).text, '~h~12');
    });

    test('la serie real de Nintendo se convierte en velas ascendentes', () {
      final transcript = readChartTranscript('chart_tse_7974');
      final events = [
        for (final p in transcript.received)
          for (final m in splitFrames(p)) parseChartMessage(m),
      ];

      final bars = events.whereType<BarsReceived>().single.bars;

      expect(bars, hasLength(30));
      expect(bars.last.date, DateTime.utc(2026, 10, 8));
      expect(bars.last.close, 7851);
      expect(bars.first.date.isBefore(bars.last.date), isTrue);
    });

    test('la transcripción real termina con series_completed', () {
      final transcript = readChartTranscript('chart_tse_7974');
      final events = [
        for (final p in transcript.received)
          for (final m in splitFrames(p)) parseChartMessage(m),
      ];

      expect(events.whereType<SeriesCompleted>(), hasLength(1));
    });

    test('un símbolo desconocido se reconoce', () {
      final transcript = readChartTranscript('chart_unknown_symbol');
      final events = [
        for (final p in transcript.received)
          for (final m in splitFrames(p)) parseChartMessage(m),
      ];

      expect(events.whereType<SymbolNotFound>(), hasLength(1));
      expect(events.whereType<ServerError>(), hasLength(1));
    });

    test('el mensaje de sesión y el resto se ignoran', () {
      expect(
        parseChartMessage('{"session_id":"x","timestamp":1}'),
        isA<IgnoredMessage>(),
      );
      expect(
        parseChartMessage('{"m":"series_loading","p":[]}'),
        isA<IgnoredMessage>(),
      );
    });

    test('un mensaje que no es JSON es inválido', () {
      expect(
        () => parseChartMessage('{roto'),
        throwsA(isA<InvalidResponseException>()),
      );
    });

    test('un timescale_update sin serie es inválido', () {
      expect(
        () => parseChartMessage('{"m":"timescale_update","p":["cs",{}]}'),
        throwsA(isA<InvalidResponseException>()),
      );
    });

    test(
      'descarta las velas incoherentes y conserva las buenas (criterio 57)',
      () {
        final event = parseChartMessage(
          _timescale([
            [_day, 10, 12, 9, 11, 500], // buena
            [_day + 86400, 10, 8, 9, 9, 500], // máximo menor que el mínimo
            [_day + 2 * 86400, 10, 12, 9, 20, 500], // cierre fuera de rango
            [_day + 3 * 86400, 0, 0, 0, 0, 0], // precio cero
            [_day + 4 * 86400, null, 12, 9, 11, 500], // dato ausente
            [_day + 5 * 86400, 10, 12], // vela incompleta
            [_day + 6 * 86400, 10, 13, 9, 12, 700], // buena
          ]),
        );

        final bars = (event as BarsReceived).bars;

        expect(bars.map((b) => b.close), [11, 12]);
      },
    );

    test('una vela sin volumen se guarda con volumen 0', () {
      final event = parseChartMessage(
        _timescale([
          [_day, 10, 12, 9, 11],
        ]),
      );

      expect((event as BarsReceived).bars.single.volume, 0);
    });

    test('tolera un cierre que sobrepasa el máximo por redondeo', () {
      final event = parseChartMessage(
        _timescale([
          [_day, 10, 12, 9, 12.0000001, 5],
        ]),
      );

      expect((event as BarsReceived).bars, hasLength(1));
    });

    test('la fecha de la vela es el día UTC', () {
      final event = parseChartMessage(
        _timescale([
          [_day, 10, 12, 9, 11, 5],
        ]),
      );

      expect(
        (event as BarsReceived).bars.single.date,
        DateTime.utc(2026, 10, 7),
      );
    });
  });

  group('mergeBars', () {
    test('une los trozos sin fechas repetidas y en orden', () {
      final first = (parseChartMessage(
        _timescale([
          [_day + 86400, 10, 12, 9, 11, 5],
          [_day, 10, 12, 9, 10, 5],
        ]),
      ) as BarsReceived).bars;
      final second = (parseChartMessage(
        _timescale([
          [_day + 86400, 10, 100, 9, 99.0, 5],
          [_day + 2 * 86400, 10, 12, 9, 12, 5],
        ]),
      ) as BarsReceived).bars;

      final merged = mergeBars([first, second]);

      // Con fecha repetida gana el último trozo recibido.
      expect(merged.map((b) => b.close), [10, 99, 12]);
      expect(merged, hasLength(3));
      expect(merged.map((b) => b.date).toList(), [
        DateTime.utc(2026, 10, 7),
        DateTime.utc(2026, 10, 8),
        DateTime.utc(2026, 10, 9),
      ]);
    });
  });
}
