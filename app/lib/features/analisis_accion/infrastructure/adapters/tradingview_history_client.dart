import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:stock_app/features/analisis_accion/domain/entities/daily_bar.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/tradingview_chart_connection.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/tradingview_chart_protocol.dart';

/// Máximo de velas que se piden (unos 24 años de sesiones).
const maxHistoryBars = 6000;

const _defaultTimeout = Duration(seconds: 20);

/// Menos sesiones que esto no es un histórico (criterio 57).
const _minSessions = 2;

/// Pide a TradingView el histórico diario de una acción por su canal de
/// gráficos (WebSocket no oficial) y lo traduce a velas.
///
/// Solo lanza subtipos de `MarketDataException`: los fallos de red, de
/// protocolo y de símbolo no escapan como excepciones de `dart:io`.
class TradingViewHistoryClient {
  TradingViewHistoryClient({
    required this._connector,
    this._timeout = _defaultTimeout,
    String Function()? newSessionId,
  }) : _newSessionId = newSessionId ?? _randomSessionId;

  final ChartConnector _connector;
  final Duration _timeout;
  final String Function() _newSessionId;

  /// Velas diarias de [ticker] (`BOLSA:TICKER`), de la más antigua a la más
  /// reciente.
  Future<List<DailyBar>> fetch(String ticker) async {
    final ChartConnection connection;
    final connecting = _connector();
    try {
      connection = await connecting.timeout(_timeout);
    } on IOException {
      throw const NetworkException('No se pudo abrir el canal de gráficos');
    } on TimeoutException {
      // La conexión sigue abriéndose: si llega tarde, se cierra en cuanto
      // exista para no dejar un socket abierto sin dueño.
      unawaited(
        connecting.then<void>(_closeQuietly).catchError((Object _) {
          // Si ni siquiera llegó a conectar, no hay nada que cerrar.
        }),
      );
      throw const NetworkException('Tiempo de espera agotado al conectar');
    }
    try {
      return await _download(connection, ticker).timeout(_timeout);
    } on TimeoutException {
      throw const NetworkException('Tiempo de espera agotado');
    } finally {
      await _closeQuietly(connection);
    }
  }

  Future<List<DailyBar>> _download(
    ChartConnection connection,
    String ticker,
  ) async {
    final done = Completer<List<DailyBar>>();
    final chunks = <List<DailyBar>>[];

    void fail(MarketDataException error) {
      if (!done.isCompleted) done.completeError(error);
    }

    // Enviar a un canal ya roto lanza (`WebSocketException`, o `StateError` si
    // se cerró): es un fallo de red, no un error de programación.
    void sendSafely(String text) {
      try {
        connection.send(text);
      } on IOException {
        fail(const NetworkException('No se pudo escribir en el canal'));
      } on StateError {
        fail(const NetworkException('Canal cerrado'));
      }
    }

    final subscription = connection.messages.listen(
      (payload) {
        try {
          for (final message in splitFrames(payload)) {
            switch (parseChartMessage(message)) {
              case Heartbeat(:final text):
                sendSafely(frameMessage(text));
              case BarsReceived(:final bars):
                chunks.add(bars);
              case SeriesCompleted():
                if (done.isCompleted) break;
                final bars = mergeBars(chunks);
                if (bars.length < _minSessions) {
                  fail(const InvalidResponseException('Histórico vacío'));
                } else {
                  done.complete(bars);
                }
              case SymbolNotFound():
                fail(const NotFoundException('Símbolo desconocido'));
              case ServerError(:final details):
                fail(InvalidResponseException('Error del servidor: $details'));
              case IgnoredMessage():
                break;
            }
          }
        } on MarketDataException catch (error) {
          fail(error);
        }
      },
      onError: (Object _) =>
          fail(const NetworkException('Fallo en el canal de gráficos')),
      onDone: () =>
          fail(const NetworkException('Canal cerrado antes de tiempo')),
    );
    try {
      for (final message in buildHistoryRequest(
        session: _newSessionId(),
        ticker: ticker,
        bars: maxHistoryBars,
      )) {
        sendSafely(message);
      }
      return await done.future;
    } finally {
      await subscription.cancel();
    }
  }

  Future<void> _closeQuietly(ChartConnection connection) async {
    try {
      await connection.close();
    } on IOException {
      // Cerrar un canal ya roto no aporta nada: el resultado ya está decidido.
    }
  }

  static String _randomSessionId() {
    const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    final suffix = [
      for (var i = 0; i < 12; i++) alphabet[random.nextInt(alphabet.length)],
    ].join();
    return 'cs_$suffix';
  }
}
