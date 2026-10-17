/// Una acción marcada como favorita: lo justo para mostrarla y abrirla.
class Favorite {
  const Favorite({required this.symbol, required this.name});

  /// Símbolo completo (`BOLSA:TICKER`); identifica al favorito.
  final String symbol;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is Favorite && other.symbol.toUpperCase() == symbol.toUpperCase();

  @override
  int get hashCode => symbol.toUpperCase().hashCode;
}
