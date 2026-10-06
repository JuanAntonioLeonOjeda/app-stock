import 'package:flutter/foundation.dart';
import 'package:stock_app/features/contenido_educativo/application/use_cases/load_educational_content_use_case.dart';
import 'package:stock_app/features/contenido_educativo/application/use_cases/search_glossary_use_case.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/educational_content.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/glossary_group.dart';
import 'package:stock_app/features/contenido_educativo/domain/exceptions/educational_content_exception.dart';

/// Estado del glosario: contenido, texto buscado y métricas que coinciden,
/// agrupadas por bloque.
class GlossaryController extends ChangeNotifier {
  GlossaryController({
    required this._loadContent,
    required this._searchGlossary,
  });

  final LoadEducationalContentUseCase _loadContent;
  final SearchGlossaryUseCase _searchGlossary;

  EducationalContent? _content;
  InvalidContentException? _error;
  bool _isLoading = false;
  String _query = '';
  List<GlossaryGroup> _groups = const [];
  bool _isDisposed = false;

  bool get isLoading => _isLoading;

  InvalidContentException? get error => _error;

  EducationalContent? get content => _content;

  String get query => _query;

  /// Métricas que coinciden con [query], por bloque.
  List<GlossaryGroup> get groups => _groups;

  /// Hay contenido, pero ninguna métrica coincide con la búsqueda.
  bool get hasNoResults => _content != null && _groups.isEmpty;

  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    _notify();
    try {
      final content = await _loadContent();
      _content = content;
      _groups = List.unmodifiable(_searchGlossary(content, _query));
    } on InvalidContentException catch (error) {
      _error = error;
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  /// Filtra el glosario por título o resumen.
  void search(String query) {
    _query = query;
    final content = _content;
    if (content != null) {
      _groups = List.unmodifiable(_searchGlossary(content, query));
    }
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
