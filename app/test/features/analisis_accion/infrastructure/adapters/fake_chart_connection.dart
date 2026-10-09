import 'dart:async';
import 'dart:convert';

import 'package:stock_app/features/analisis_accion/infrastructure/adapters/tradingview_chart_connection.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/tradingview_chart_protocol.dart';

/// Conexión escrita a mano: al recibir la petición de la serie
/// (`create_series`) reproduce los paquetes del guion, y registra lo enviado.
class FakeChartConnection implements ChartConnection {
  FakeChartConnection(
    this.script, {
    this.closeAfterScript = false,
    this.sendError,
  });

  /// Si no es null, `send` lo lanza (simula un canal roto).
  final Object? sendError;

  /// Paquetes que "manda el servidor" cuando llega la petición.
  final List<String> script;

  /// Si es true, cierra el canal después del guion (sin series_completed).
  final bool closeAfterScript;
  final List<String> sent = [];
  final _controller = StreamController<String>();
  bool isClosed = false;

  @override
  Stream<String> get messages => _controller.stream;

  @override
  void send(String text) {
    final failure = sendError;
    if (failure != null) throw failure;
    sent.add(text);
    if (text.contains('create_series')) {
      scheduleMicrotask(() {
        script.forEach(_controller.add);
        if (closeAfterScript) _controller.close();
      });
    }
  }

  @override
  Future<void> close() async {
    isClosed = true;
    if (!_controller.isClosed) await _controller.close();
  }
}

/// Paquete con dos velas diarias buenas que empiezan en el día [firstDay]
/// (días desde 1970-01-01; 20732 = 2026-10-06). Los cierres son 11 y 12.
String chartChunk(int firstDay) => frameMessage(
  jsonEncode({
    'm': 'timescale_update',
    'p': [
      'cs_test',
      {
        'sds_1': {
          's': [
            {
              'i': 0,
              'v': [firstDay * 86400, 10, 12, 9, 11, 5],
            },
            {
              'i': 1,
              'v': [(firstDay + 1) * 86400, 11, 13, 10, 12, 5],
            },
          ],
        },
      },
    ],
  }),
);

/// Paquete con el que el servidor da por terminada la serie.
final chartCompleted = frameMessage('{"m":"series_completed","p":["cs_test"]}');
