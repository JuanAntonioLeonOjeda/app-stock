import 'dart:convert';

import 'package:stock_app/features/contenido_educativo/domain/exceptions/educational_content_exception.dart';

typedef JsonObject = Map<String, Object?>;

/// Lee campos de un objeto JSON con tipos comprobados. El rastro de campos
/// recorridos se añade a cada mensaje de error.
class ContentReader {
  const ContentReader._(this._file, this._path, this._json);

  factory ContentReader.root(String file, String body) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException catch (error) {
      throw InvalidContentException('$file: no es JSON (${error.message})');
    }
    if (decoded is! JsonObject) {
      throw InvalidContentException('$file: se esperaba un objeto');
    }
    return ContentReader._(file, const [], decoded);
  }

  final String _file;
  final List<String> _path;
  final JsonObject _json;

  ContentReader under(String name) =>
      ContentReader._(_file, [..._path, name], _json);

  InvalidContentException fail(String field, String problem) {
    final where = [_file, ..._path, field].join(' › ');
    return InvalidContentException('$where: $problem');
  }

  String text(String field) {
    final value = _json[field];
    if (value is! String || value.trim().isEmpty) {
      throw fail(field, 'se esperaba un texto no vacío');
    }
    return value.trim();
  }

  int integer(String field) {
    final value = _json[field];
    if (value is! int) throw fail(field, 'se esperaba un número entero');
    return value;
  }

  List<String> textList(String field) {
    final value = _json[field];
    if (value is! List<Object?>) throw fail(field, 'se esperaba una lista');
    return [
      for (final item in value)
        if (item is String && item.trim().isNotEmpty)
          item.trim()
        else
          throw fail(field, 'todos los elementos deben ser textos no vacíos'),
    ];
  }

  ContentReader object(String field) {
    final value = _json[field];
    if (value is! JsonObject) throw fail(field, 'se esperaba un objeto');
    return ContentReader._(_file, [..._path, field], value);
  }

  List<ContentReader> list(String field) {
    final value = _json[field];
    if (value is! List<Object?>) throw fail(field, 'se esperaba una lista');
    return [
      for (var i = 0; i < value.length; i++)
        if (value[i] case final JsonObject item)
          ContentReader._(_file, [..._path, '$field[$i]'], item)
        else
          throw fail('$field[$i]', 'se esperaba un objeto'),
    ];
  }

  bool has(String field) => _json[field] != null;

  /// Número entero o decimal.
  double number(String field) {
    final value = _json[field];
    if (value is! num) throw fail(field, 'se esperaba un número');
    return value.toDouble();
  }

  double? optionalNumber(String field) => has(field) ? number(field) : null;

  bool boolean(String field) {
    final value = _json[field];
    if (value is! bool) throw fail(field, 'se esperaba verdadero o falso');
    return value;
  }

  /// Un texto o una lista de textos, siempre devuelto como lista.
  List<String> textOrList(String field) =>
      _json[field] is String ? [text(field)] : textList(field);

  /// Lista de objetos, o vacía si el campo no está.
  List<ContentReader> optionalList(String field) =>
      has(field) ? list(field) : const [];

  ContentReader? optionalObject(String field) =>
      has(field) ? object(field) : null;
}
