import 'package:stock_app/features/contenido_educativo/application/use_cases/get_metric_scale_use_case.dart';
import 'package:stock_app/features/contenido_educativo/domain/content/activity_grading.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/learning_activity.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/reading_scale.dart';
import 'package:stock_app/features/contenido_educativo/presentation/controllers/topic_controller.dart';
import 'package:stock_app/features/contenido_educativo/presentation/lesson_steps.dart';

/// Estado del recorrido paso a paso de una ficha (criterios 72-73, 85, 90).
///
/// Amplía [TopicController] con el paso actual y lo respondido en cada
/// actividad. Todo está en memoria y se descarta al cambiar de tema o al
/// cerrar la pantalla: no se guarda nada. Las respuestas se indexan por la
/// posición del paso, porque dos actividades pueden ser del mismo tipo.
class LessonController extends TopicController {
  LessonController({
    required super.loadContent,
    required super.initialTopicId,
    required this._getMetricScale,
  });

  final GetMetricScaleUseCase _getMetricScale;

  int _currentStep = 0;
  final Map<int, Map<String, double>> _simulatorValues = {};
  final Map<int, Set<int>> _trapsTapped = {};
  final Map<int, bool> _compareAnswers = {};
  final Map<int, int> _predictAnswers = {};
  final Map<int, List<int>> _orders = {};
  final Set<int> _ordersChecked = {};

  /// Pasos del tema actual; vacío si no es una métrica o no hay contenido.
  List<LessonStep> get steps {
    final metric = currentMetric;
    return metric == null ? const [] : lessonStepsFor(metric);
  }

  int get currentStep => _currentStep;

  /// Escala del motor de la métrica actual, o `null` si no tiene.
  ReadingScale? get scale => _getMetricScale(currentTopicId);

  /// Va al paso [index] sin pasar por los anteriores (criterio 73).
  void goToStep(int index) {
    if (index == _currentStep || index < 0 || index >= steps.length) return;
    _currentStep = index;
    notifyIfAlive();
  }

  // Simulador (criterio 81).

  /// Valores que el usuario ha puesto en el simulador del [step].
  Map<String, double> simulatorValues(int step) =>
      Map.unmodifiable(_simulatorValues[step] ?? const {});

  void setSimulatorValue(int step, String key, double value) {
    _simulatorValues.putIfAbsent(step, () => {})[key] = value;
    notifyIfAlive();
  }

  void resetSimulator(int step) {
    _simulatorValues.remove(step);
    notifyIfAlive();
  }

  // Detectar la trampa (criterio 82).

  /// Posiciones de los datos ya pulsados en la actividad del [step].
  Set<int> trapsTapped(int step) => Set.unmodifiable(_trapsTapped[step] ?? {});

  void tapTrapItem(int step, int index) {
    _trapsTapped.putIfAbsent(step, () => {}).add(index);
    notifyIfAlive();
  }

  // Comparar (criterio 83).

  /// `true` si respondió la empresa A, `false` la B, `null` si no ha respondido.
  bool? compareAnswer(int step) => _compareAnswers[step];

  void answerCompare(int step, {required bool isA}) {
    _compareAnswers[step] = isA;
    notifyIfAlive();
  }

  // Predecir (criterio 84).

  int? predictAnswer(int step) => _predictAnswers[step];

  void answerPredict(int step, int option) {
    _predictAnswers[step] = option;
    notifyIfAlive();
  }

  // Ordenar (criterio 84).

  /// Posiciones (en `items`) en el orden en que se muestran ahora; la primera
  /// vez sale barajado con una semilla fija por ficha y paso.
  List<int> orderOf(int step, OrderActivity activity) => List.unmodifiable(
    _orders[step] ??= shuffledOrder('$currentTopicId#$step', [
      for (final item in activity.items) item.value,
    ]),
  );

  /// Mueve un elemento; [newIndex] ya viene ajustado por `onReorderItem`.
  void reorder(int step, OrderActivity activity, int oldIndex, int newIndex) {
    final order = [...orderOf(step, activity)];
    order.insert(newIndex, order.removeAt(oldIndex));
    _orders[step] = order;
    _ordersChecked.remove(step);
    notifyIfAlive();
  }

  /// Si el usuario ya ha pulsado "Comprobar" con el orden actual.
  bool isOrderChecked(int step) => _ordersChecked.contains(step);

  void checkOrder(int step) {
    _ordersChecked.add(step);
    notifyIfAlive();
  }

  /// Si el orden mostrado en el [step] es el correcto.
  bool isOrderCorrect(int step, OrderActivity activity) => isAscending([
    for (final index in orderOf(step, activity)) activity.items[index],
  ]);

  void retryOrder(int step) {
    _orders.remove(step);
    _ordersChecked.remove(step);
    notifyIfAlive();
  }

  @override
  void resetAnswers() {
    super.resetAnswers();
    _currentStep = 0;
    _simulatorValues.clear();
    _trapsTapped.clear();
    _compareAnswers.clear();
    _predictAnswers.clear();
    _orders.clear();
    _ordersChecked.clear();
  }
}
