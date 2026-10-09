import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/tradingview_chart_connection.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/tradingview_chart_protocol.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/tradingview_history_client.dart';

import '../../../../fixtures/tradingview_fixtures.dart';
import 'fake_chart_connection.dart';

TradingViewHistoryClient _client(
  FakeChartConnection connection, {
  Duration timeout = const Duration(seconds: 2),
}) => TradingViewHistoryClient(
  connector: () async => connection,
  timeout: timeout,
  newSessionId: () => 'cs_test',
);

void main() {
  group('TradingViewHistoryClient', () {
    test('devuelve el histórico de la transcripción real', () async {
      final transcript = readChartTranscript('chart_tse_7974');
      final connection = FakeChartConnection(transcript.received);

      final bars = await _client(connection).fetch('TSE:7974');

      expect(bars, hasLength(30));
      expect(bars.last.close, 7851);
      expect(bars.last.date, DateTime.utc(2026, 10, 8));
    });

    test('envía la petición de la serie con el símbolo y 6000 velas', () async {
      final connection = FakeChartConnection(
        readChartTranscript('chart_tse_7974').received,
      );

      await _client(connection).fetch('TSE:7974');

      expect(connection.sent, hasLength(4));
      expect(connection.sent[2], contains('TSE:7974'));
      expect(connection.sent[3], contains('6000'));
      expect(connection.sent[1], contains('cs_test'));
    });

    test('cierra la conexión al terminar', () async {
      final connection = FakeChartConnection(
        readChartTranscript('chart_tse_7974').received,
      );

      await _client(connection).fetch('TSE:7974');

      expect(connection.isClosed, isTrue);
    });

    test('devuelve los latidos tal cual, enmarcados', () async {
      final connection = FakeChartConnection([
        frameMessage('~h~12'),
        chartChunk(20000),
        frameMessage('~h~13'),
        chartCompleted,
      ]);

      await _client(connection).fetch('TSE:7974');

      expect(connection.sent, contains(frameMessage('~h~12')));
      expect(connection.sent, contains(frameMessage('~h~13')));
    });

    test('une los trozos de la serie recibidos por separado', () async {
      final connection = FakeChartConnection([
        chartChunk(20000),
        chartChunk(20002),
        chartCompleted,
      ]);

      final bars = await _client(connection).fetch('TSE:7974');

      expect(bars, hasLength(4));
      expect(bars.first.date.isBefore(bars.last.date), isTrue);
    });

    test('procesa varios mensajes llegados en un mismo paquete', () async {
      final connection = FakeChartConnection([
        chartChunk(20000) + chartCompleted,
      ]);

      final bars = await _client(connection).fetch('TSE:7974');

      expect(bars, hasLength(2));
    });

    test('un símbolo desconocido es NotFound', () async {
      final connection = FakeChartConnection(
        readChartTranscript('chart_unknown_symbol').received,
      );

      await expectLater(
        _client(connection).fetch('NASDAQ:ZZZZZZQ'),
        throwsA(isA<NotFoundException>()),
      );
      expect(connection.isClosed, isTrue);
    });

    test('un error del servidor es respuesta inválida', () async {
      final connection = FakeChartConnection([
        frameMessage('{"m":"critical_error","p":[]}'),
      ]);

      await expectLater(
        _client(connection).fetch('TSE:7974'),
        throwsA(isA<InvalidResponseException>()),
      );
    });

    test('una serie con menos de 2 sesiones es respuesta inválida', () async {
      final connection = FakeChartConnection([
        frameMessage('{"m":"timescale_update","p":["cs",{"sds_1":{"s":[]}}]}'),
        chartCompleted,
      ]);

      await expectLater(
        _client(connection).fetch('TSE:7974'),
        throwsA(isA<InvalidResponseException>()),
      );
    });

    test('un paquete mal enmarcado es respuesta inválida', () async {
      final connection = FakeChartConnection(['sin marco']);

      await expectLater(
        _client(connection).fetch('TSE:7974'),
        throwsA(isA<InvalidResponseException>()),
      );
    });

    test('si el canal se cierra antes de terminar, es error de red', () async {
      final connection = FakeChartConnection([
        chartChunk(20000),
      ], closeAfterScript: true);

      await expectLater(
        _client(connection).fetch('TSE:7974'),
        throwsA(isA<NetworkException>()),
      );
    });

    test(
      'si el servidor no responde, el tiempo agotado es error de red',
      () async {
        final connection = FakeChartConnection(const []);

        await expectLater(
          _client(
            connection,
            timeout: const Duration(milliseconds: 50),
          ).fetch('TSE:7974'),
          throwsA(isA<NetworkException>()),
        );
        expect(connection.isClosed, isTrue);
      },
    );

    test('si no puede conectar, es error de red', () async {
      final client = TradingViewHistoryClient(
        connector: () async => throw const SocketException('sin red'),
      );

      await expectLater(
        client.fetch('TSE:7974'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('un WebSocketException al conectar también es error de red', () async {
      final client = TradingViewHistoryClient(
        connector: () async => throw const WebSocketException('rechazado'),
      );

      await expectLater(
        client.fetch('TSE:7974'),
        throwsA(isA<NetworkException>()),
      );
    });

    test(
      'si enviar la petición falla con una excepción de E/S, es error de red',
      () async {
        final connection = FakeChartConnection(
          const [],
          sendError: const WebSocketException('cerrado'),
        );

        await expectLater(
          _client(connection).fetch('TSE:7974'),
          throwsA(isA<NetworkException>()),
        );
        expect(connection.isClosed, isTrue);
      },
    );

    test(
      'si el canal ya está cerrado al enviar (StateError), es error de red',
      () async {
        final connection = FakeChartConnection(
          const [],
          sendError: StateError('WebSocket is closed'),
        );

        await expectLater(
          _client(connection).fetch('TSE:7974'),
          throwsA(isA<NetworkException>()),
        );
      },
    );

    test(
      'si falla al devolver un latido, es error de red y no queda sin capturar',
      () async {
        final connection = _FailAfterRequestConnection([frameMessage('~h~7')]);

        await expectLater(
          _client(connection).fetch('TSE:7974'),
          throwsA(isA<NetworkException>()),
        );
      },
    );

    test(
      'cerrar un canal ya cerrado (StateError) no oculta el resultado',
      () async {
        final connection = _ThrowOnCloseConnection(
          readChartTranscript('chart_tse_7974').received,
        );

        final bars = await _client(connection).fetch('TSE:7974');

        expect(bars, isNotEmpty);
        expect(connection.closeAttempted, isTrue);
      },
    );

    test(
      'una conexión que se abre tarde, tras el tiempo agotado, se cierra',
      () async {
        final late = FakeChartConnection(const []);
        final client = TradingViewHistoryClient(
          connector: () => Future<ChartConnection>.delayed(
            const Duration(milliseconds: 120),
            () => late,
          ),
          timeout: const Duration(milliseconds: 30),
        );

        await expectLater(
          client.fetch('TSE:7974'),
          throwsA(isA<NetworkException>()),
        );
        await Future<void>.delayed(const Duration(milliseconds: 250));

        expect(late.isClosed, isTrue);
      },
    );
  });
}

/// Acepta la petición y falla justo al devolver el latido.
class _FailAfterRequestConnection extends FakeChartConnection {
  _FailAfterRequestConnection(super.script);

  int _sends = 0;

  @override
  void send(String text) {
    _sends++;
    // Las 4 primeras son la petición; la siguiente es el latido de vuelta.
    if (_sends > 4) throw const WebSocketException('roto');
    super.send(text);
  }
}

/// Conexión cuyo `close` falla como un canal que ya estaba cerrado.
class _ThrowOnCloseConnection extends FakeChartConnection {
  _ThrowOnCloseConnection(super.script);

  bool closeAttempted = false;

  @override
  Future<void> close() async {
    closeAttempted = true;
    throw StateError('WebSocket is closed');
  }
}
