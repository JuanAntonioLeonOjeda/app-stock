# Plan: analisis_accion

> Basado en `spec.md` (cerrada). Arquitectura en `.claude/rules/hexagonal-architecture.md`,
> estilo en `.claude/rules/code-style.md`, motor en la skill `motor-analisis`, datos en la
> skill `datos-mercado`. Rutas relativas a `app/lib/features/analisis_accion/` salvo que se
> indique otra cosa.

## Dependencias nuevas (`app/pubspec.yaml`)

| Paquete | Uso | Capa |
|---|---|---|
| `http` | Cliente de Alpha Vantage (`http.Client` inyectable; `package:http/testing.dart` para los tests) | infrastructure |
| `path_provider` | Carpeta de la app donde se guardan la caché y el historial | infrastructure |
| `intl` | Formateo de números, porcentajes y fechas en español | presentation |

Ninguna en `domain/` ni en `application/`.

## Elementos por capa

### domain/entities

| Archivo | Contenido |
|---|---|
| `stock_data.dart` | `StockData`: perfil, histórico, estados financieros, resultados y `fetchedAt` (contrato de la skill `motor-analisis`) |
| `company_overview.dart` | `CompanyOverview`: perfil y ratios del proveedor |
| `daily_bar.dart` | `DailyBar`: fecha, apertura, máximo, mínimo, cierre, volumen |
| `income_statement.dart`, `balance_sheet.dart`, `cash_flow_statement.dart` | Estados financieros normalizados (anuales y trimestrales) |
| `earnings_report.dart` | `EarningsReport`: BPA real, BPA estimado y fecha |
| `symbol_match.dart` | `SymbolMatch`: símbolo, nombre, región, divisa y puntuación |
| `analysis_result.dart` | `AnalysisResult`, `BlockResult`, `MetricResult` y los enums `Verdict`, `Confidence`, `CompanyProfile`, `Horizon`, `Block`, `MetricFormat` |
| `history_entry.dart` | `HistoryEntry`: `AnalysisResult` + `analyzedAt` |
| `fetch_step.dart` | `FetchStep` (enum de los 6 pasos) para informar del progreso |

### domain/exceptions

| Archivo | Contenido |
|---|---|
| `market_data_exception.dart` | `MarketDataException` y sus subtipos: `RateLimitException`, `NotFoundException`, `InvalidResponseException`, `NetworkException`, `MissingApiKeyException` |

### domain/motor

Funciones puras, sin I/O ni reloj. Toda la opinión (escalas, pesos y umbrales) está solo en `rules/`.

| Archivo | Contenido |
|---|---|
| `motor_version.dart` | `motorVersion = '1.0.0'` (semver, invariante 3) |
| `indicators/technical_indicators.dart` | SMA, EMA, RSI de Wilder, MACD, pendiente de la SMA200, rentabilidades, volatilidad, caída máxima y máximo/mínimo de 52 semanas |
| `indicators/fundamental_ratios.dart` | TTM, FCF, deuda neta/EBITDA, deuda/patrimonio, liquidez, cobertura, márgenes, CAGR, ROIC, ROE, dilución, dividendo/FCF, P/FCF y sorpresas de BPA |
| `indicators/metric_values.dart` | Calcula el valor de cada `id` de métrica a partir de `StockData` (orquesta indicadores y ratios, con respaldo del perfil si el histórico es corto) |
| `rules/metric_rule.dart` | `MetricRule` (`id`, bloque, etiqueta, formato, peso, escala o función propia, perfiles) |
| `rules/metric_rules.dart` | La lista declarativa de todas las reglas de `references/metricas.md` |
| `rules/block_weights.dart` | Pesos por bloque y horizonte |
| `rules/verdict_thresholds.dart` | Cortes del veredicto, de la confianza y de antigüedad |
| `rules/profile_criteria.dart` | Criterios de detección del perfil (palabras clave, crecimiento, dividendo) |
| `rules/flag_rules.dart` | Umbrales de los avisos, cada uno junto a su texto |
| `indicators/metric_value.dart` | `MetricValue`: valor calculado, valor anterior y nota; distingue "sin dato" (resta cobertura) de "no aplica" (no la resta) |
| `scoring/piecewise_scale.dart` | `ScorePoint`, interpolación lineal por tramos con saturación y redondeo a 1 decimal |
| `scoring/profile_detector.dart` | Detección del perfil (financiera → crecimiento → dividendo → general) |
| `scoring/block_scorer.dart` | Nota y cobertura de cada bloque |
| `scoring/verdict_calculator.dart` | Nota global, veredicto, regla de coherencia por salud y confianza |
| `scoring/flag_detector.dart` | Señales de alarma y avisos (datos antiguos, histórico corto, veredicto limitado, resultados próximos) |
| `stock_analyzer.dart` | Punto de entrada: `analyze(StockData, {required DateTime referenceDate, Horizon horizon})` → `AnalysisResult` |

### domain/ports

| Archivo | Contenido |
|---|---|
| `market_data_port.dart` | `searchSymbol(String query)` y `fetchStockData(String symbol, {bool forceRefresh, void Function(FetchStep)? onProgress})` |
| `cache_port.dart` | Clave-valor con caducidad: `read(String key)` (devuelve `null` si falta o ha caducado), `write(String key, String value, Duration ttl)` |
| `analysis_history_port.dart` | `load()` → `List<HistoryEntry>` y `save(HistoryEntry)` |

### infrastructure/adapters

| Archivo | Contenido |
|---|---|
| `alpha_vantage_adapter.dart` | `AlphaVantageAdapter implements MarketDataPort`: peticiones en secuencia con pausa configurable, caché por endpoint con su caducidad, `forceRefresh`, progreso y traducción de errores |
| `alpha_vantage_error_detector.dart` | Detecta `Error Message`, `Note` e `Information` en respuestas con HTTP 200 y los convierte en excepciones de `domain/` |
| `alpha_vantage_parser.dart` | JSON → entidades: textos a números, `"None"`/`"-"`/vacío a `null`, signos, orden, deuda y caja con respaldo, y reintento con `compact` |
| `file_cache_adapter.dart` | `FileCacheAdapter implements CachePort`: un archivo JSON por clave (`{value, expiresAt}`) en la carpeta de soporte de la app |
| `file_analysis_history_adapter.dart` | `FileAnalysisHistoryAdapter implements AnalysisHistoryPort`: un archivo JSON con como máximo 10 entradas |
| `analysis_result_json.dart` | Serialización de `AnalysisResult` y `HistoryEntry` (en infrastructure, según `code-style.md`) |
| `json_file.dart` | Lectura y escritura atómica (temporal + renombrado) de un archivo JSON; un archivo corrupto se lee como ausente |

### application/use_cases

| Archivo | Contenido |
|---|---|
| `search_symbol_use_case.dart` | `SearchSymbolUseCase`: valida el texto (sin espacios sobrantes y no vacío) y llama al port |
| `analyze_stock_use_case.dart` | `AnalyzeStockUseCase`: `fetchStockData` → `StockAnalyzer.analyze` con `referenceDate = now()` → guarda en el historial → devuelve la `HistoryEntry` |
| `load_history_use_case.dart` | `LoadHistoryUseCase`: devuelve las entradas, la más reciente primero |

Para poder testearlo, el reloj se inyecta en `AnalyzeStockUseCase` como `DateTime Function() now`.

### presentation

| Archivo | Contenido |
|---|---|
| `controllers/home_controller.dart` | `HomeController` (`ChangeNotifier`): texto buscado, resultados, historial, carga, error y `isApiKeyConfigured` |
| `controllers/analysis_controller.dart` | `AnalysisController`: resultado actual, paso en curso, error y actualización forzada que conserva el resultado anterior si falla |
| `screens/home_screen.dart` | Buscador arriba, historial debajo (criterio 0) |
| `screens/analysis_screen.dart` | Pantalla de resultado |
| `widgets/search_bar_section.dart`, `widgets/symbol_match_tile.dart`, `widgets/history_list.dart` | Piezas de la pantalla de inicio |
| `widgets/verdict_header.dart` | Nombre, símbolo, precio, fecha, perfil, veredicto, nota, confianza y versión del motor |
| `widgets/flags_section.dart`, `widgets/block_tile.dart`, `widgets/metric_row.dart`, `widgets/missing_data_section.dart` | Avisos, bloques plegables, métricas y datos que faltan |
| `widgets/analysis_progress.dart` | "Obteniendo balance, 3 de 6" |
| `widgets/educational_disclaimer.dart` | Aviso de fin educativo (criterio 14) |
| `formatters/metric_value_formatter.dart` | **Único** punto donde un valor se formatea (fracción ×100 → %, ratios con "x", importes con divisa) |
| `formatters/error_messages.dart` | Excepción de `domain/` → texto de la spec (criterios 22-27) |

### Composition root (`app/lib/app.dart`) y `app/lib/main.dart`

- Lee `String.fromEnvironment('ALPHA_VANTAGE_API_KEY')`.
- Construye `http.Client`, `FileCacheAdapter`, `FileAnalysisHistoryAdapter` y `AlphaVantageAdapter`, luego los use cases y después los controllers.
- Si la clave está vacía, `HomeController` recibe `isApiKeyConfigured = false` (criterio 27).
- Navegación con `Navigator.push` (solo hay dos pantallas, sin `go_router`).
- Tema básico de Material 3 en `app/lib/core/theme/app_theme.dart`.

## Decisiones técnicas no obvias

1. **La caché vive dentro del adapter, no en el use case.** Las caducidades son por
   endpoint de Alpha Vantage (6 h el histórico, 24 h el perfil, 7 días los estados y
   resultados, 30 días la búsqueda), un detalle del proveedor. El adapter recibe un
   `CachePort` y guarda cada respuesta correcta en cuanto llega. Así se cumple el criterio
   26 (un fallo a mitad no desperdicia lo ya obtenido) y el criterio 25 (los errores nunca
   se guardan). Implica ajustar una fila de la tabla de `hexagonal-architecture.md`: el use
   case orquesta "proveedor → motor → historial", no la caché.

2. **Se guarda en caché el JSON en crudo ya validado, no la entidad.** El parser se ejecuta
   siempre al leer. Si se corrige un bug del parser, basta con volver a analizar, sin
   vaciar la caché y sin gastar peticiones.

3. **El recuerdo de "el plan no permite `outputsize=full`"** se guarda en la misma caché
   (clave `av:plan:full_history_unavailable`, 30 días) para no gastar una petición en
   cada análisis (skill `datos-mercado`).

4. **Los valores se formatean en presentación, no en el motor.** La skill incluye un
   "valor formateado" en `AnalysisResult`. Aquí, en cambio, `MetricResult` lleva el valor
   en bruto y su `MetricFormat` (`percent`, `ratio`, `multiple`, `count`, `currency`), y
   presentation lo formatea en `metric_value_formatter.dart`. Así se respeta la regla de
   que solo presentación multiplica por 100 y el motor no depende de la configuración
   regional. Hay que actualizar esa línea de la skill `motor-analisis`.

5. **El historial caduca a las 6 horas.** Una entrada muestra "Datos de hace X"
   (criterio 18) si `analyzedAt` tiene más de 6 horas, la caducidad más corta de los datos
   de los que depende (el histórico diario).

6. **Pausa entre peticiones: 1.200 ms por defecto**, como parámetro del constructor del
   adapter (0 en los tests). Confirmado el 2026-09-30: la documentación solo publica 25
   peticiones al día; el límite de ráfaga del plan gratuito es de 1 petición por segundo
   (según su aviso), así que 1,2 s basta.

7. **La clave nunca aparece en logs ni en claves de caché.** Las claves de caché usan
   endpoint y símbolo (`av:OVERVIEW:AAPL`), nunca la URL completa.

8. **Los textos de los avisos los genera el motor** (skill `motor-analisis`, "Avisos"), en
   español. Es texto estático determinista, no contenido educativo, así que no depende
   de la futura feature educativa.

## Tests

Siguiendo `.claude/rules/testing-conventions.md`, en `app/test/features/analisis_accion/`:

| Qué | Cómo |
|---|---|
| `technical_indicators`, `fundamental_ratios`, `piecewise_scale` | Valores conocidos (RSI solo alcista = 100, plano = 50, SMA trivial, drawdown concreto, `null` si faltan datos) |
| `stock_analyzer` y `scoring/*` | Empresas sintéticas construidas en `test/.../domain/motor/synthetic_companies.dart`: una de calidad → `favorable`, una frágil → `desfavorable`, más los casos límite de la skill y el determinismo |
| `metric_rules` | Toda regla tiene `id` único y escala ordenada; los `id` coinciden con `references/metricas.md` |
| `alpha_vantage_parser`, `alpha_vantage_error_detector` | Fixtures reales en `app/test/fixtures/alpha_vantage/` |
| `alpha_vantage_adapter` | `MockClient` de `package:http/testing.dart` + un fake de `CachePort`: caché por endpoint, `forceRefresh`, progreso, fallo a mitad y errores sin guardar en caché |
| `file_cache_adapter`, `file_analysis_history_adapter` | Carpeta temporal (`Directory.systemTemp`): caducidad, máximo de 10 entradas, sin duplicados y orden |
| `analysis_result_json` | Ida y vuelta sin pérdidas |
| Use cases | Fakes escritos a mano en `application/fake_ports.dart` |
| Controllers | Transiciones de estado: carga → resultado, error que conserva el resultado anterior y clave ausente |
| `metric_value_formatter` | Fracción → %, `null` → "sin dato" |

Se verifica en dispositivo: una búsqueda y un análisis reales con clave, la persistencia
tras reiniciar la app y el mensaje de límite de peticiones.

## Cambios en la configuración asociados

- `hexagonal-architecture.md`: la fila "Orquestar caché → proveedor → motor → resultado"
  pasa a "Orquestar proveedor → motor → historial" y la caché se atribuye al adapter
  (decisión 1).
- Skill `motor-analisis`: `valor formateado` → `formato` (decisión 4).
- La entrada del contenido educativo por cada `id`, y su test, quedan para la feature
  educativa. El test de cobertura se añadirá entonces.
