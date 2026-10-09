/// Abre una dirección web fuera de la app (el navegador del dispositivo).
abstract interface class LinkOpenerPort {
  /// `true` si se pudo abrir [uri]; `false` si el dispositivo no puede.
  Future<bool> open(Uri uri);
}
