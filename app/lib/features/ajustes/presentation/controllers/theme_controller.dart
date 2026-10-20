import 'package:flutter/foundation.dart';
import 'package:stock_app/features/ajustes/application/use_cases/load_theme_preference_use_case.dart';
import 'package:stock_app/features/ajustes/application/use_cases/set_theme_preference_use_case.dart';
import 'package:stock_app/features/ajustes/domain/entities/theme_preference.dart';

/// Estado del tema elegido. Vive mientras dura la app.
class ThemeController extends ChangeNotifier {
  ThemeController({required this.loadPreference, required this.setPreference});

  final LoadThemePreferenceUseCase loadPreference;
  final SetThemePreferenceUseCase setPreference;

  ThemePreference _preference = ThemePreference.system;
  bool _isDisposed = false;
  bool _hasUserChosen = false;

  ThemePreference get preference => _preference;

  /// Aplica la preferencia guardada, salvo que el usuario ya haya elegido una
  /// mientras se leía.
  Future<void> load() async {
    final saved = await loadPreference();
    if (_hasUserChosen) return;
    _update(saved);
  }

  /// Cambia el tema al instante y lo guarda después, para que se vea el cambio
  /// aunque el guardado falle.
  Future<void> select(ThemePreference preference) async {
    _hasUserChosen = true;
    _update(preference);
    await setPreference(preference);
  }

  void _update(ThemePreference preference) {
    if (_isDisposed || preference == _preference) return;
    _preference = preference;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
