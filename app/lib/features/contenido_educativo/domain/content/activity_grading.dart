import 'dart:math' as math;

import 'package:stock_app/features/contenido_educativo/domain/entities/learning_activity.dart';

/// Si [shown] está ordenado de menor a mayor valor (criterio 84).
bool isAscending(List<OrderItem> shown) {
  for (var i = 1; i < shown.length; i++) {
    if (shown[i].value < shown[i - 1].value) return false;
  }
  return true;
}

/// Orden en el que se muestran los elementos de [OrderActivity]: una
/// permutación de `0..values.length-1` que **no** está ordenada.
///
/// Es determinista según [seedKey] para que la actividad no cambie entre
/// aperturas ni ya salga resuelta. Con valores todos iguales no puede
/// desordenar y devuelve el orden original.
List<int> shuffledOrder(String seedKey, List<double> values) {
  final indices = [for (var i = 0; i < values.length; i++) i];
  final random = math.Random(_fnv1a(seedKey));
  for (var attempt = 0; attempt < 32; attempt++) {
    indices.shuffle(random);
    if (!_isSorted(indices, values)) return indices;
  }
  return _descendingOrder(values);
}

bool _isSorted(List<int> order, List<double> values) {
  for (var i = 1; i < order.length; i++) {
    if (values[order[i]] < values[order[i - 1]]) return false;
  }
  return true;
}

/// Último recurso: el orden descendente, que solo está ordenado si todo es igual.
List<int> _descendingOrder(List<double> values) =>
    [for (var i = 0; i < values.length; i++) i]
      ..sort((a, b) => values[b].compareTo(values[a]));

/// Hash estable entre ejecuciones (`String.hashCode` no lo garantiza).
int _fnv1a(String text) {
  var hash = 0x811c9dc5;
  for (final unit in text.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff;
  }
  return hash;
}
