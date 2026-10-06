/// El contenido didáctico no se ha podido leer o no tiene el formato esperado.
///
/// [details] indica qué archivo y qué campo fallan; nunca se muestra al
/// usuario.
class InvalidContentException implements Exception {
  const InvalidContentException(this.details);

  final String details;

  @override
  String toString() => 'InvalidContentException: $details';
}
