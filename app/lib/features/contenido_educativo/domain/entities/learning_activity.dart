/// Actividad de una ficha, distinta de la pregunta de comprobación. No puntúa
/// ni se guarda: sirve para practicar (criterios 80-85).
sealed class LearningActivity {
  const LearningActivity();
}

/// Mover las piezas de la fórmula y ver dónde cae el resultado (criterio 81).
class SimulatorActivity extends LearningActivity {
  const SimulatorActivity({required this.prompt});

  final String prompt;
}

/// Un dato de la empresa inventada de [SpotTrapActivity].
class TrapItem {
  const TrapItem({
    required this.label,
    required this.value,
    required this.isTrap,
    required this.explanation,
  });

  final String label;
  final String value;
  final bool isTrap;

  /// Por qué es (o no es) la trampa; se muestra al pulsarlo.
  final String explanation;
}

/// Encontrar el dato engañoso de una empresa inventada (criterio 82).
class SpotTrapActivity extends LearningActivity {
  SpotTrapActivity({
    required this.company,
    required this.prompt,
    required List<TrapItem> items,
  }) : items = List.unmodifiable(items);

  final String company;
  final String prompt;
  final List<TrapItem> items;
}

/// Una fila de la tabla de [CompareActivity].
class CompareRow {
  const CompareRow({required this.label, required this.a, required this.b});

  final String label;
  final String a;
  final String b;
}

/// Comparar dos empresas inventadas del mismo sector (criterio 83).
class CompareActivity extends LearningActivity {
  CompareActivity({
    required this.sector,
    required this.companyA,
    required this.companyB,
    required List<CompareRow> rows,
    required this.question,
    required this.correctIsA,
    required this.explanation,
  }) : rows = List.unmodifiable(rows);

  final String sector;
  final String companyA;
  final String companyB;
  final List<CompareRow> rows;
  final String question;

  /// `true` si la respuesta correcta es la empresa A.
  final bool correctIsA;
  final String explanation;
}

/// Predecir antes de mirar (criterio 84).
class PredictActivity extends LearningActivity {
  PredictActivity({
    required this.text,
    required List<String> options,
    required this.correctIndex,
    required this.explanation,
    required this.reveal,
  }) : options = List.unmodifiable(options);

  final String text;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  /// El dato que confirma la respuesta, mostrado después de responder.
  final String reveal;
}

/// Un elemento de [OrderActivity].
class OrderItem {
  const OrderItem({
    required this.name,
    required this.value,
    required this.shown,
  });

  final String name;

  /// Valor con el que se ordena.
  final double value;

  /// Cómo se muestra el valor una vez resuelta la actividad.
  final String shown;
}

/// Ordenar empresas inventadas de menor a mayor valor de una métrica
/// (criterio 84).
class OrderActivity extends LearningActivity {
  OrderActivity({
    required this.prompt,
    required List<OrderItem> items,
    required this.explanation,
  }) : items = List.unmodifiable(items);

  final String prompt;

  /// En el orden del archivo; la pantalla los baraja con una semilla fija.
  final List<OrderItem> items;
  final String explanation;
}
