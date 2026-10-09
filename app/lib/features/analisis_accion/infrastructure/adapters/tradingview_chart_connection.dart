import 'dart:async';
import 'dart:io';

/// Conexión de texto con el canal de gráficos. Es una interfaz interna de
/// `infrastructure/` para poder probar el cliente sin red.
abstract interface class ChartConnection {
  /// Paquetes de texto recibidos del servidor.
  Stream<String> get messages;

  /// Envía un mensaje ya enmarcado.
  void send(String text);

  Future<void> close();
}

/// Abre una [ChartConnection].
typedef ChartConnector = Future<ChartConnection> Function();

const _chartUrl = 'wss://data.tradingview.com/socket.io/websocket';

/// [ChartConnection] real, con el WebSocket de `dart:io`.
class IoChartConnection implements ChartConnection {
  IoChartConnection._(this._socket);

  final WebSocket _socket;

  /// Conecta con TradingView. Sin la cabecera `Origin` el servidor rechaza la
  /// conexión.
  static Future<ChartConnection> connect() async => IoChartConnection._(
    await WebSocket.connect(
      _chartUrl,
      headers: {
        'Origin': 'https://www.tradingview.com',
        'User-Agent': 'Mozilla/5.0',
      },
    ),
  );

  @override
  Stream<String> get messages =>
      _socket.where((event) => event is String).cast<String>();

  @override
  void send(String text) => _socket.add(text);

  @override
  Future<void> close() => _socket.close();
}
