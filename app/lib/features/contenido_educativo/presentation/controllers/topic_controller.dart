import 'package:flutter/foundation.dart';
import 'package:stock_app/features/contenido_educativo/application/use_cases/load_educational_content_use_case.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/block_content.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/educational_content.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/metric_content.dart';
import 'package:stock_app/features/contenido_educativo/domain/exceptions/educational_content_exception.dart';

/// Estado de la explicación de un tema (una métrica, un bloque o la guía).
///
/// Guarda la pila de temas visitados para volver atrás (criterio 3) y la
/// opción elegida en la pregunta, que se descarta al cambiar de tema y no se
/// conserva en ningún sitio (criterio 5).
class TopicController extends ChangeNotifier {
  TopicController({required this._loadContent, required String initialTopicId})
    : _stack = [initialTopicId];

  final LoadEducationalContentUseCase _loadContent;
  final List<String> _stack;

  EducationalContent? _content;
  InvalidContentException? _error;
  bool _isLoading = false;
  int? _selectedOption;
  bool _isDisposed = false;

  EducationalContent? get content => _content;

  /// Fallo al leer el contenido; `null` si todo va bien.
  InvalidContentException? get error => _error;

  bool get isLoading => _isLoading;

  String get currentTopicId => _stack.last;

  /// Ficha de la métrica actual; `null` si el tema no es una métrica o no hay
  /// contenido.
  MetricContent? get currentMetric => _content?.metricById(currentTopicId);

  BlockContent? get currentBlock => _content?.blockById(currentTopicId);

  bool get canGoBack => _stack.length > 1;

  /// Opción elegida en la pregunta de comprobación del tema actual.
  int? get selectedOption => _selectedOption;

  /// Lee el contenido. Un fallo se puede reintentar llamando otra vez.
  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    _notify();
    try {
      _content = await _loadContent();
    } on InvalidContentException catch (error) {
      _error = error;
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  /// Pasa al tema [topicId]; la respuesta elegida se descarta.
  void openTopic(String topicId) {
    if (topicId == currentTopicId) return;
    _stack.add(topicId);
    _selectedOption = null;
    _notify();
  }

  /// Vuelve al tema anterior.
  void goBack() {
    if (!canGoBack) return;
    _stack.removeLast();
    _selectedOption = null;
    _notify();
  }

  /// Elige una opción de la pregunta. Se puede cambiar de opinión: no se
  /// puntúa ni se guarda nada.
  void selectOption(int index) {
    _selectedOption = index;
    _notify();
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
