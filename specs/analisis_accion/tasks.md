# Tasks: analisis_accion

> Derivadas de `plan.md`. Marcar cada una al completarla.
>
> **Cada tarea con comportamiento incluye su archivo de test** (`app/test/` refleja
> `app/lib/`); las entidades que solo guardan datos no llevan test, según
> `testing-conventions.md`. Ninguna tarea se da por terminada hasta que
> `flutter analyze` no da avisos y `flutter test` pasa. La sección
> "Tests" recoge solo lo transversal. Rutas relativas a
> `app/lib/features/analisis_accion/` salvo que se indique otra cosa.

## Setup

- [x] T01. `flutter create --project-name stock_app --org com.stock_app app`; eliminar el
      contador de ejemplo y su test.
- [x] T02. `app/analysis_options.yaml` con `flutter_lints` y los extras de `code-style.md`.
- [x] T03. Dependencias `http`, `path_provider` e `intl` en `app/pubspec.yaml`.
- [x] T04. `app/config/secrets.example.json` (versionado, con
      `ALPHA_VANTAGE_API_KEY` vacía). Comprobar que `app/config/secrets.json` queda
      ignorado por git.
- [x] T05. Estructura de carpetas vacía de la feature y de `app/lib/core/theme/`
      (creada en local; git no versiona carpetas vacías: entran con su primer archivo).

## Domain

Entidades y excepciones:

- [x] T06. `domain/entities/daily_bar.dart`, `company_overview.dart`,
      `income_statement.dart`, `balance_sheet.dart`, `cash_flow_statement.dart` y
      `earnings_report.dart`.
- [ ] T07. `domain/entities/stock_data.dart` (con `fetchedAt`; histórico ascendente e
      informes del más reciente al más antiguo, como invariante documentado).
- [ ] T08. `domain/entities/symbol_match.dart` y `fetch_step.dart`.
- [ ] T09. `domain/entities/analysis_result.dart` (`AnalysisResult`, `BlockResult`,
      `MetricResult` y los enums `Verdict`, `Confidence`, `CompanyProfile`, `Horizon`,
      `Block` y `MetricFormat`).
- [ ] T10. `domain/entities/history_entry.dart`.
- [ ] T11. `domain/exceptions/market_data_exception.dart` con sus 5 subtipos.

Motor (seguir la skill `motor-analisis` y `references/metricas.md`):

- [ ] T12. `domain/motor/motor_version.dart`.
- [ ] T13. `domain/motor/scoring/piecewise_scale.dart`: interpolación, saturación y
      redondeo.
- [ ] T14. `domain/motor/indicators/technical_indicators.dart`: SMA, EMA, RSI, MACD,
      pendiente de la SMA200, rentabilidades, volatilidad, caída máxima y máximo/mínimo
      de 52 semanas.
- [ ] T15. `domain/motor/indicators/fundamental_ratios.dart`: TTM, FCF, ratios de salud, márgenes, CAGR, ROIC (con el tipo impositivo de
      respaldo), ROE, dilución, dividendo/FCF, P/FCF y sorpresas de BPA.
- [ ] T16. `domain/motor/rules/metric_rule.dart` (`MetricRule`, `ScorePoint`).
- [ ] T17. `domain/motor/rules/metric_rules.dart`: las 30 reglas de las secciones 2-6 de
      `metricas.md`, con perfiles y pesos.
- [ ] T18. `domain/motor/rules/block_weights.dart` y `verdict_thresholds.dart`.
- [ ] T19. `domain/motor/indicators/metric_values.dart`: valor de cada `id` a partir de
      `StockData`, respaldo del perfil si hay menos de 200 sesiones y notas explicativas
      cuando el valor es `null` por un motivo conocido.
- [ ] T20. `domain/motor/scoring/profile_detector.dart`.
- [ ] T21. `domain/motor/scoring/block_scorer.dart`: nota y cobertura.
- [ ] T22. `domain/motor/scoring/verdict_calculator.dart`: nota global, veredicto,
      coherencia por salud y confianza.
- [ ] T23. `domain/motor/scoring/flag_detector.dart`: alarmas de la sección 7, datos
      antiguos, histórico corto, veredicto limitado y resultados en 14 días o menos.
- [ ] T24. `domain/motor/stock_analyzer.dart`: ensambla el `AnalysisResult` (con los
      datos que faltan y la versión del motor).

## Ports

- [ ] T25. `domain/ports/market_data_port.dart` (con `forceRefresh` y `onProgress`).
- [ ] T26. `domain/ports/cache_port.dart`.
- [ ] T27. `domain/ports/analysis_history_port.dart`.

## Adapters

- [ ] T28. Capturar fixtures reales en `app/test/fixtures/alpha_vantage/`: los 7
      endpoints para `IBM` con la clave `demo` de Alpha Vantage (no gasta cuota), una
      búsqueda sin resultados y respuestas de error (`Note`, `Information` y
      `Error Message`, además del aviso de `outputsize=full` premium). La clave
      nunca queda en los fixtures.
- [ ] T29. `infrastructure/adapters/alpha_vantage_error_detector.dart`.
- [ ] T30. `infrastructure/adapters/alpha_vantage_parser.dart`: números en texto,
      ausentes a `null`, signos, orden, deuda y caja con respaldo (las entidades las
      reciben ya resueltas).
- [ ] T31. Confirmar en la documentación de Alpha Vantage el límite por minuto actual y
      ajustar la pausa por defecto (decisión 6 del plan).
- [ ] T32. `infrastructure/adapters/alpha_vantage_adapter.dart`: secuencia con pausa,
      caché por endpoint con su caducidad, JSON en crudo en caché, recuerdo de
      `full_history_unavailable`, `forceRefresh`, progreso, `MissingApiKeyException` y
      claves de caché sin la clave de la API.
- [ ] T33. `infrastructure/adapters/file_cache_adapter.dart`.
- [ ] T34. `infrastructure/adapters/analysis_result_json.dart`.
- [ ] T35. `infrastructure/adapters/file_analysis_history_adapter.dart`: como máximo 10
      entradas, sin duplicados y la más reciente primero.

## Use cases

- [ ] T36. `application/use_cases/search_symbol_use_case.dart`.
- [ ] T37. `application/use_cases/analyze_stock_use_case.dart` (reloj inyectado).
- [ ] T38. `application/use_cases/load_history_use_case.dart`.

## Presentation

- [ ] T39. `presentation/formatters/metric_value_formatter.dart` y `error_messages.dart`.
- [ ] T40. `presentation/controllers/home_controller.dart`.
- [ ] T41. `presentation/controllers/analysis_controller.dart` (la actualización forzada
      conserva el resultado anterior si falla).
- [ ] T42. Widgets de inicio: `search_bar_section.dart`, `symbol_match_tile.dart` e
      `history_list.dart`.
- [ ] T43. Widgets de resultado: `verdict_header.dart`, `flags_section.dart`,
      `block_tile.dart`, `metric_row.dart`, `missing_data_section.dart`,
      `analysis_progress.dart` y `educational_disclaimer.dart`.
- [ ] T44. `presentation/screens/home_screen.dart` y `analysis_screen.dart`.
- [ ] T45. `app/lib/core/theme/app_theme.dart`, composition root en `app/lib/app.dart` y
      `app/lib/main.dart` (clave con `String.fromEnvironment`).

## Tests

- [ ] T46. `test/.../domain/motor/synthetic_companies.dart`: empresa de calidad →
      `favorable` y empresa frágil → `desfavorable`.
- [ ] T47. Casos límite del motor: PER con beneficios negativos, perfil financiero,
      salud < 4, datos vacíos → `datos_insuficientes`, datos antiguos → confianza `baja`
      y determinismo.
- [ ] T48. `metric_rules`: `id` únicos, escalas ordenadas y coincidencia con los `id` de
      `metricas.md`.
- [ ] T49. `test/.../application/fake_ports.dart` completos y compartidos por los
      tests de use cases y controllers.
- [ ] T50. Repasar los 32 criterios de `spec.md` y anotar qué test cubre cada uno o si
      se verifica en dispositivo.

## Verificación en dispositivo

- [ ] T51. Con clave real: una búsqueda, un análisis completo, un análisis repetido desde
      la caché y "Actualizar datos".
- [ ] T52. Persistencia del historial y de la caché tras cerrar la app y volver a
      abrirla.
- [ ] T53. Sin conexión y sin clave: mensajes correctos y el historial accesible.

## Revisión

- [ ] T54. `flutter-reviewer`
- [ ] T55. Actualizar `AGENTS.md` con las rutas nuevas.
