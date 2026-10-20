# Plan: ajustes

Rutas relativas a `app/lib/features/ajustes/` salvo que se indique otra cosa.

## Capas

- `domain/entities/theme_preference.dart`: `enum ThemePreference { system, light, dark }`.
  Dart puro; no conoce `ThemeMode` (eso es Flutter).
- `domain/ports/theme_preference_port.dart`: `load()` (devuelve `system` si no hay nada) y
  `save(ThemePreference)`.
- `application/use_cases/`: `LoadThemePreferenceUseCase` y `SetThemePreferenceUseCase`.
- `infrastructure/adapters/file_theme_preference_adapter.dart`: `settings.json` con
  `{"version": 1, "theme": "dark"}`. Ausente, corrupto, otra versión o valor desconocido →
  `system`. Un fallo de escritura se ignora (criterio 7).
- `presentation/controllers/theme_controller.dart`: `ChangeNotifier` con `preference`,
  `load()` y `select()`. Cambia el estado antes de guardar, para que el tema cambie al
  instante aunque el guardado falle.
- `presentation/widgets/theme_mode_button.dart`: `PopupMenuButton` con las tres opciones y
  la activa marcada. Su icono es el de la opción activa.
- `presentation/theme_mode_mapper.dart`: `ThemePreference` → `ThemeMode`.

## Decisiones

- **Feature propia, no dentro de `analisis_accion`:** el tema es transversal y no es
  análisis de acciones.
- **`JsonFile` pasa a `app/lib/core/storage/json_file.dart`:** lo necesitan ya dos features
  y una no puede importar de otra (`project-policies.md`). Se mueve con su test.
- **El botón llega a la portada por composition root:** `HomeScreen` recibe un
  `Widget? themeAction` ya construido por `app.dart`; así `analisis_accion` no importa
  `ajustes`.
- **Carga asíncrona:** `app.dart` arranca en Sistema y aplica la preferencia guardada en
  cuanto se lee (un fotograma). No se bloquea el arranque.
