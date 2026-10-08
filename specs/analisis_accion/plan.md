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
| `formatters/labels.dart` | Nombres visibles de veredicto, confianza, perfil, bloque y pasos de progreso |
| `widgets/verdict_badge.dart`, `widgets/error_notice.dart` | Veredicto con color y aviso de error con "Reintentar" opcional (usados en las dos pantallas) |

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

---

## Revisión 2: proveedor TradingView (2026-10-06)

> Implementada (T56-T65). Basada en la Revisión 2 de `spec.md`. Sustituye al adapter de Alpha Vantage. El motor
> sigue siendo el mismo; solo cambian sus datos de entrada. Rutas relativas a
> `app/lib/features/analisis_accion/`.

### Qué hay en TradingView (comprobado 2026-10-06)

- **Búsqueda**: `GET https://symbol-search.tradingview.com/symbol_search/v3/?text=…&search_type=stock`
  (cabecera `Origin: https://www.tradingview.com`). Cada resultado trae `symbol`,
  `exchange`, `description` (con `<em>` de resaltado), `currency_code`, `country`, `type`
  (`stock`/`dr`) e `is_primary_listing`. El símbolo completo es `EXCHANGE:SYMBOL`
  (`TSE:7974`).
- **Datos**: `POST https://scanner.tradingview.com/global/scan` con
  `{"symbols":{"tickers":["TSE:7974"]},"columns":[…]}`. Una sola petición devuelve todo.
  Un campo desconocido se devuelve como `null` sin error, así que **los nombres de campo
  se validan con un test contra una fixture real**, no con la propia API.
- **Escalares en USD, series en moneda de reporte.** Capitalización, deuda, patrimonio y
  similares (`*_ttm`, `*_fq`) vienen **convertidos a USD** (`fundamental_currency_code`);
  las series `*_fy_h` (20 años) y `*_fq_h` (32 trimestres), más reciente primero, vienen en
  la moneda de reporte (JPY para Nintendo). Los ratios (PER, ROE, P/FCF...) no tienen
  unidad.
- **Fechas de las series**: no vienen con la serie; se derivan de `fiscal_period_end_fy`
  (cierre del último ejercicio) y `fiscal_period_end_current` (cierre del último
  trimestre publicado) restando 12 o 3 meses por posición.
- **Fecha del último cierre**: campo `time` (epoch en segundos).

### Decisiones técnicas

1. **Reglas de moneda.** El motor nunca mezcla un escalar en USD con una serie en la
   moneda de reporte. Donde el cálculo propio exigiría mezclarlos (P/FCF con la
   capitalización, ROE con el patrimonio, ROIC, deuda neta/EBITDA con la caja), el motor
   usa el **ratio ya calculado del proveedor** (campos nuevos de `CompanyOverview`),
   como respaldo cuando el cálculo propio da `null`. Con las series (todas en la misma
   moneda) sí calcula: CAGR, tendencias de margen, FCF positivo, margen operativo y bruto.
2. **Una barra sintética.** Sin histórico diario, el adapter entrega una única `DailyBar`
   con el cierre actual (`close`, `open`, `high`, `low`, `volume`) y la fecha de `time`.
   Así el precio y la fecha del último cierre siguen funcionando (criterio 9 y 30).
   RSI, SMA200 y máximo de 52 semanas salen de los campos ya calculados
   (`CompanyOverview.rsi14`, `movingAverage200`, `week52High`), que el motor ya usa como
   respaldo con histórico corto.
3. **`FetchStep` se reduce a `fetching`** (una sola petición). `onProgress` se mantiene
   en el port (otros proveedores sí tienen varios pasos).
4. **Caché de la respuesta cruda validada**, como hasta ahora, con 6 h de caducidad
   para búsqueda y datos (criterio 38). El parser se ejecuta siempre al leer.
5. **Errores**: HTTP 429 o 403 → `RateLimitException`; 5xx y fallos de conexión →
   `NetworkException`; fila ausente en `data` → `NotFoundException`; JSON que no es el
   esperado → `InvalidResponseException`. Se elimina `MissingApiKeyException` y toda la
   gestión de la clave (`secrets.json`, `String.fromEnvironment`, `isApiKeyConfigured`).
6. **La búsqueda prioriza listados primarios** (`is_primary_listing`), luego `stock` antes
   que `dr`. Se pide `search_type=stock` y se filtran los que no son acciones.
7. **Motor**: `motorVersion` pasa a `1.1.0` (cambia de qué datos se calcula cada métrica;
   los resultados guardados llevan su versión, criterio 17).

### Cambios por capa

| Capa | Cambio |
|---|---|
| `domain/entities/company_overview.dart` | Campos opcionales nuevos: `priceToFreeCashFlow`, `returnOnEquity`, `returnOnInvestedCapital`, `netDebtToEbitda`, `debtToEquity`, `currentRatio`, `operatingMargin`, `grossMargin`, `rsi14` (fracciones, no %) |
| `domain/entities/fetch_step.dart` | Un solo paso: `fetching` |
| `domain/exceptions/market_data_exception.dart` | Elimina `MissingApiKeyException` |
| `domain/motor/indicators/metric_values.dart` | `calculado ?? overview.<ratio>` en `per`, `p_fcf`, `deuda_ebitda`, `deuda_patrimonio`, `liquidez`, `margen_operativo`, `margen_bruto`, `roic`, `roe`, `rsi` |
| `domain/motor/scoring/flag_detector.dart` | Aviso "Sin histórico de precios" (criterio 35) en lugar del de histórico corto cuando solo hay una barra |
| `infrastructure/adapters/tradingview_fields.dart` | Lista de campos pedidos al scanner |
| `infrastructure/adapters/tradingview_parser.dart` | Búsqueda y scanner → `SymbolMatch` y `StockData`: fechas de series, % → fracción, USD vs moneda de reporte, `null` para lo ausente |
| `infrastructure/adapters/tradingview_adapter.dart` | `TradingViewAdapter implements MarketDataPort`: caché, errores y cabeceras |
| `infrastructure/adapters/alpha_vantage_*.dart` | Se eliminan (Alpha Vantage queda en el historial de git) |
| `presentation/` | Sin aviso de clave; progreso de un paso; el resto igual |
| `app.dart`, `main.dart` | Construye `TradingViewAdapter`; sin clave |

### Cambios en la configuración asociados

- Skill `datos-mercado`: proveedor TradingView (endpoints, campos, reglas de moneda,
  riesgos), eliminada la parte de Alpha Vantage y de clave.
- `project-policies.md`: secretos (ya no hay clave) y la regla "No llamar a la API fuera
  de su adapter" sigue igual.
- Skill `motor-analisis` y `references/metricas.md`: respaldo con ratios del proveedor.
- `app/config/secrets.example.json` y `--dart-define-from-file` dejan de hacer falta.

### Noticias recientes (criterios 41-43)

| Capa | Cambio |
|---|---|
| `domain/ports/link_opener_port.dart` | `LinkOpenerPort`: `open(Uri)` → `bool` (si se pudo abrir) |
| `application/use_cases/open_news_use_case.dart` | `OpenNewsUseCase`: construye `https://www.google.com/search?q=<nombre> <ticker>&tbm=nws&tbs=sbd:1` a partir del `AnalysisResult` y llama al port |
| `infrastructure/adapters/url_launcher_adapter.dart` | `UrlLauncherAdapter implements LinkOpenerPort` con el paquete `url_launcher` (nueva dependencia, solo en infrastructure); un `PlatformException` se traduce a `false` |
| `presentation/` | `AnalysisController.openNews()`; botón "Ver noticias recientes" al final del resultado; `SnackBar` si falla |
| `AndroidManifest.xml` | `<queries>` con la intención `VIEW` de `https`, necesaria en Android 11+ para que `canLaunchUrl` funcione |

El ticker sin bolsa (`7974`, no `TSE:7974`) y el nombre van en la búsqueda; el texto se
codifica con `Uri` (sin concatenar a mano).

---

## Revisión 3: histórico real y gráfica de precio (2026-10-08)

> Basada en la Revisión 3 de `spec.md`. Rutas relativas a `app/lib/features/analisis_accion/`.

### Qué hay en el canal de gráficos de TradingView (comprobado 2026-10-08)

- **Conexión:** WebSocket `wss://data.tradingview.com/socket.io/websocket` con la cabecera
  `Origin: https://www.tradingview.com`. Sin clave.
- **Formato:** cada mensaje va enmarcado como `~m~<longitud>~m~<json>`, y un mismo paquete
  puede traer varios. El servidor manda latidos `~h~<n>` que hay que devolver tal cual.
- **Secuencia que funciona:** `set_auth_token ["unauthorized_user_token"]` →
  `chart_create_session [sesión, ""]` → `resolve_symbol [sesión, "sds_sym_1",
  "={\"symbol\":\"TSE:7974\",\"adjustment\":\"splits\"}"]` → `create_series [sesión,
  "sds_1", "s1", "sds_sym_1", "D", 6000, ""]`.
- **Respuesta:** un `timescale_update` con `p[1].sds_1.s`, una lista de `{i, v:[t, o, h, l,
  c, v]}` con `t` en segundos. Un `symbol_error` o `critical_error` indica un símbolo
  inexistente o un fallo.
- **Alcance:** hasta ~6.000 velas (24 años). Precios ajustados por splits.

### Elementos por capa

#### domain

| Archivo | Contenido |
|---|---|
| `ports/price_history_port.dart` | `PriceHistoryPort`: `fetchPriceHistory(symbol, {forceRefresh})` → `List<DailyBar>` ascendente; solo lanza `MarketDataException` |
| `chart/chart_range.dart` | `ChartRange` (`month1`, `months3`, `months6`, `year1`, `years5`, `all`) con los días de cada uno |
| `chart/price_series.dart` | Funciones puras: `ChartPoint`, `sliceRange`, `movingAverageSeries` (`null` donde no hay datos suficientes), `downsample` (agrupa conservando máximo y mínimo por tramo), `closeExtremes` |

#### application/use_cases

| Archivo | Contenido |
|---|---|
| `get_price_history_use_case.dart` | `GetPriceHistoryUseCase`: llama al port |

#### infrastructure/adapters

| Archivo | Contenido |
|---|---|
| `tradingview_chart_protocol.dart` | Funciones puras del protocolo: enmarcar y partir paquetes, construir los mensajes de la petición, detectar latidos y errores, y convertir la serie a `DailyBar` descartando velas incoherentes (criterio 57) |
| `tradingview_chart_connection.dart` | `ChartConnection` (interfaz interna: mensajes, enviar, cerrar), `ChartConnector` y `IoChartConnection` con `dart:io WebSocket` |
| `tradingview_history_client.dart` | `TradingViewHistoryClient`: abre la conexión, envía la petición, devuelve los latidos y espera la serie con un tiempo máximo; traduce los fallos a `MarketDataException` |
| `tradingview_adapter.dart` | Además implementa `PriceHistoryPort`; cachea el histórico (6 h, formato compacto), evita dos peticiones simultáneas del mismo símbolo y, en `fetchStockData`, usa el histórico si llega y, si falla, la barra única de siempre |
| `tradingview_parser.dart` | `parseTradingViewScan` acepta un histórico opcional en lugar de la barra única |

#### presentation

| Archivo | Contenido |
|---|---|
| `controllers/price_chart_controller.dart` | `PriceChartController` (`ChangeNotifier`): carga, error, periodo, interruptores de medias y los datos ya recortados y agrupados que pinta la gráfica |
| `widgets/price_chart_panel.dart` | Selector de periodo, interruptores, gráfica, pie de fuente y estado de error con "Reintentar" |
| `widgets/price_line_chart.dart` | Línea de cierres con `fl_chart`: marcadores de máximo y mínimo, medias, y la ficha de fecha y precio al tocar |
| `screens/analysis_screen.dart` | Con controller de gráfica: `TabBar` Resumen (por defecto) / Detalle; sin él, como ahora |
| `app.dart` | Crea el `PriceChartController` de cada resultado |

#### motor

`motorVersion = '1.2.0'`. El motor no cambia de código: ya trabaja con `dailyBars`. Con histórico
real, `macd`, `pendiente_sma200`, `caida_maxima`, `precio_sma200` y `dist_maximo` se calculan
con datos reales, y `references/metricas.md` lo refleja.

### Decisiones técnicas no obvias

1. **Un fallo del histórico nunca impide analizar.** `fetchStockData` lo captura (solo
   `MarketDataException`) y cae a la barra única. La gráfica, en cambio, sí muestra el error
   (criterio 53).
2. **El histórico tiene su propia caché y petición**, no va dentro de `StockData`. El
   `AnalysisResult` guardado en el historial no lleva velas (serían cientos de KB por entrada).
   Abrir una entrada antigua pide el histórico a la caché o a la red.
3. **Peticiones simultáneas del mismo símbolo se unen** en un único `Future`: al abrir un
   análisis nuevo, el análisis y la gráfica piden el histórico a la vez.
4. **Formato compacto en caché**: lista de `[t, o, h, l, c, v]` en lugar de objetos, unos 45
   bytes por vela (~270 KB para 6.000), con la clave `tv:v1:history:<símbolo>`.
5. **La conexión se abstrae (`ChartConnection`)** para probar el cliente con una transcripción
   real guardada, sin red.
6. **Agrupar puntos al dibujar, no al guardar**: la caché conserva las velas completas (el
   motor las necesita); solo la gráfica reduce a unos 500 puntos.
7. **`fl_chart` solo en `presentation/`**; el dominio no sabe que existe.

### Tests

| Qué | Cómo |
|---|---|
| `price_series`, `chart_range` | Valores conocidos: recorte por periodo, medias con huecos, agrupado conserva máximo y mínimo, extremos |
| `tradingview_chart_protocol` | Transcripción real guardada en `test/fixtures/tradingview/`: partir paquetes, latidos, serie, error de símbolo, velas incoherentes |
| `tradingview_history_client` | `ChartConnection` falso escrito a mano: éxito, latidos devueltos, símbolo inexistente, cierre prematuro, tiempo agotado |
| `tradingview_adapter` | Caché 6 h, `forceRefresh`, peticiones simultáneas unidas, fallback a la barra única |
| `price_chart_controller` | Carga, error y reintento, cambio de periodo, interruptores |
| Widgets y pantalla | Selector, marcadores, pestañas (Resumen por defecto, Detalle intacto), error con reintento |
| Motor | Empresa con 300 sesiones: MACD, pendiente y caída máxima con valor, sin aviso |

### Cambios en la configuración asociados

- Skill `datos-mercado`: el histórico diario sí llega (protocolo, secuencia, riesgos); caché.
- `references/metricas.md`: con histórico real, las métricas técnicas se calculan.
- Dependencia `fl_chart` en `app/pubspec.yaml`.

---

## Revisión 4: gráfica del día y de la última semana (2026-10-08)

> Basada en la Revisión 4 de `spec.md`. Rutas relativas a `app/lib/features/analisis_accion/`.

### Qué da el canal de gráficos (comprobado 2026-10-08)

- La misma petición `create_series`, cambiando la resolución: `"5"` y `"30"` (minutos) en vez
  de `"D"`. Cada vela es `[t, o, h, l, c, v]` con `t` en segundos.
- `symbol_resolved` trae `timezone` (IANA: `Asia/Tokyo`, `Europe/Madrid`, `America/New_York`) y,
  según la bolsa, `delay` en segundos (Tokio 1200, Madrid 900).
- Solo sesión regular: 09:00-17:38 en Madrid, 09:30-16:00 en Nueva York, 09:00-15:31 en Tokio
  con pausa de la comida.

### Elementos por capa

#### domain

| Archivo | Contenido |
|---|---|
| `entities/intraday_bar.dart` | `IntradayBar`: instante (UTC) y cierre |
| `entities/intraday_series.dart` | `IntradaySeries`: velas ascendentes, zona horaria de la bolsa y retraso |
| `ports/intraday_history_port.dart` | `IntradayHistoryPort`: `fetchIntraday(symbol, resolution, {forceRefresh})` |
| `chart/intraday_resolution.dart` | `IntradayResolution` (`minutes5`, `minutes30`) con su número de velas pedidas |
| `chart/chart_range.dart` | Añade `day` y `week`, con `isIntraday` |
| `chart/sessions.dart` | `splitSessions` (rachas sin hueco de más de 3 h) y `lastSessions(n)` |
| `chart/exchange_clock.dart` | `exchangeWallClock(instante, zona)`: la hora local de la bolsa con una tabla de zonas y las reglas de cambio de hora de la UE y de EE. UU.; `null` si la zona no se conoce |

#### application/use_cases

| Archivo | Contenido |
|---|---|
| `get_intraday_history_use_case.dart` | `GetIntradayHistoryUseCase` |

#### infrastructure/adapters

| Archivo | Contenido |
|---|---|
| `tradingview_chart_protocol.dart` | Pasa a leer velas con su instante (`Candle`) y reconoce `symbol_resolved` (zona y retraso); `buildHistoryRequest` recibe la resolución. Las velas diarias se convierten a `DailyBar` como hasta ahora |
| `tradingview_history_client.dart` | `fetchCandles(ticker, resolution, bars)` devuelve velas + zona + retraso; `fetch` (diario) se apoya en él |
| `tradingview_history_cache.dart` | Formato compacto del intradía `{tz, delay, bars:[[t, cierre]]}` |
| `tradingview_adapter.dart` | Implementa también `IntradayHistoryPort`: caché de 5 minutos, descargas simultáneas unidas por resolución |

#### presentation

| Archivo | Contenido |
|---|---|
| `controllers/price_chart_controller.dart` | Carga el intradía bajo demanda al elegir 1D o 1S (estado y error propios); `PriceChartView` añade `isIntraday`, el `ExchangeClock` y el retraso; las medias no aplican |
| `widgets/price_line_chart.dart` | En intradía el eje X es el orden de las velas, con etiquetas de hora (1D) o de día (1S) en la hora de la bolsa; tooltip con día y hora |
| `widgets/price_chart_panel.dart` | Selector con 1D y 1S; oculta las medias en intradía; pie con la sesión, el retraso y la zona horaria; error propio del intradía |
| `formatters/` | Etiquetas de hora y de día de la semana en español |

### Decisiones técnicas no obvias

1. **Sesiones por huecos de más de 3 horas**, no por fecha: no depende de la zona horaria y
   resiste la pausa de la comida de Tokio (1 h).
2. **Eje por orden de velas** en 1D y 1S: sin huecos de noche y de fin de semana.
3. **Tabla de zonas con reglas de cambio de hora en vez de un paquete de zonas horarias**: unas
   15 zonas cubren las bolsas habituales y, si la zona no está, se usa la del dispositivo y se
   avisa. Evita meter la base de datos completa de zonas.
4. **El intradía no entra en `StockData` ni en el motor**: solo alimenta la gráfica.
5. **Caché de 5 minutos**: los datos llegan con 15-20 min de retraso; pedirlos más a menudo no
   da datos nuevos.
6. **Conceptos educativos (`contenido_educativo`)**: `analisis_accion` ya recibe un
   `InfoBuilder`; el panel de la gráfica lo usa también para las medias y el título de la
   gráfica con los ids `media_50`, `media_200` y `grafico_precio`.

### Tests

Recorte de sesiones (con la pausa de Tokio y fines de semana), reglas de cambio de hora en las
fechas de cambio de la UE y de EE. UU., transcripciones reales de 5 y 30 minutos, cliente con
conexión falsa, adapter (caché de 5 minutos, descargas unidas, fallo aislado), controller
(carga bajo demanda, error propio, medias recordadas), gráfica (etiquetas, tooltip, marcadores)
y panel (selector, medias ocultas, pie).

---

## Revisión 5: búsqueda sin versiones duplicadas (2026-10-08)

> Basada en la Revisión 5 de `spec.md`. Rutas relativas a `app/lib/features/analisis_accion/`.

### Qué da TradingView (comprobado 2026-10-08)

- **Buscador:** cada resultado trae `isin`, `is_primary_listing`, `type` (`stock`/`dr`), `exchange`,
  `source2.name` (nombre de la bolsa), `country` y `currency_code`. Una búsqueda devuelve hasta
  ~50 resultados sin paginar. Buscar un ISIN completo devuelve todas sus cotizaciones
  (`found_by_isin`).
- **Scanner:** columnas `isin`, `exchange` e `is_primary` por símbolo.
- **Huecos:** por nombre, "Inditex" solo trae versiones OTC; la principal (`BME:ITX`) sale por
  ticker, nombre legal o ISIN.

### Elementos por capa

#### domain

| Archivo | Contenido |
|---|---|
| `entities/symbol_match.dart` | Añade `isin`, `exchange`, `exchangeName`, `isPrimaryListing` e `isDepositaryReceipt` |
| `entities/company_listings.dart` | `CompanyListings`: una empresa con su `defaultListing`, si la principal está confirmada (`hasConfirmedPrimary`), `others` y si es ADR |
| `search/group_listings.dart` | Funciones puras: `groupListings` (por ISIN, sin ISIN descartado, principal primero, otras con euros primero, grupos por relevancia y ADR al final) y `isinsMissingPrimary` (qué ISIN hay que completar) |
| `entities/company_overview.dart` | Añade `isin`, `exchange` e `isPrimaryListing` |
| `entities/analysis_result.dart` | `AnalysisResult` lleva `isin`, `exchange` e `isPrimaryListing` (opcionales) |
| `motor/stock_analyzer.dart` | Copia esos datos del `overview` al resultado (sin cambiar ningún cálculo, así que el motor no sube de versión) |

#### application

| Archivo | Contenido |
|---|---|
| `use_cases/search_symbol_use_case.dart` | Devuelve `List<CompanyListings>` agrupadas con `groupListings`; la complementación por ISIN la hace el adapter |

#### infrastructure

| Archivo | Contenido |
|---|---|
| `tradingview_parser.dart` | La búsqueda rellena los campos nuevos de `SymbolMatch` y conserva ADR; el scanner rellena `isin`, `exchange` e `is_primary` |
| `tradingview_fields.dart` | Tres columnas nuevas, **al final** de la lista |
| `tradingview_adapter.dart` | `searchSymbol` completa los grupos sin principal buscando por su ISIN (máximo 3), tolera que falle y cachea cada búsqueda 6 h |
| `analysis_result_json.dart` | Guarda y lee los campos nuevos; ausentes en entradas antiguas = `null` |

#### presentation

| Archivo | Contenido |
|---|---|
| `controllers/home_controller.dart` | `companies` en lugar de `matches`; contador y estado de "Mostrar certificados ADR" |
| `widgets/company_listings_tile.dart` | Sustituye a `symbol_match_tile.dart`: fila de la empresa con "Principal" y desplegable "Otras cotizaciones (n)" |
| `screens/home_screen.dart` | Lista de empresas y el botón de ADR |
| `widgets/verdict_header.dart` | Línea con bolsa, ISIN y "Cotización principal" / "Otra cotización" |

### Decisiones técnicas no obvias

1. **Agrupar en `domain/`, completar en `infrastructure/`:** agrupar y ordenar es regla de
   presentación de resultados (pura y testeable); completar por ISIN es una estrategia propia
   de TradingView, así que vive en su adapter.
2. **Las columnas nuevas del scanner van al final de la lista** para poder ampliar las fixtures
   reales ya guardadas sin recapturarlas (los tests dependen de sus precios y fechas).
3. **El motor no sube de versión:** solo se copian tres datos de identificación.
4. **`hasConfirmedPrimary`:** la etiqueta "Principal" solo sale si el proveedor la marcó.
5. **La relevancia es el orden de entrada, no una puntuación.** Las puntuaciones de la búsqueda
   por nombre y las de las búsquedas por ISIN que la completan no son comparables (cada una
   empieza en 1,0). `groupListings` ordena las empresas por la posición de su primera
   coincidencia en la lista ya unida, así que una principal recuperada por ISIN no adelanta a
   empresas que el proveedor puso antes, y no hay empates (el orden de `List.sort` no está
   garantizado). Un certificado ADR nunca se etiqueta como principal.

### Tests

Agrupación (varias bolsas, sin ISIN, ADR, empates, sin principal, euros primero, orden de grupos),
parser con la búsqueda real de "nintendo", "iberdrola" e "inditex", búsqueda complementaria
(caso Inditex con transcripción real, fallo aislado, límite de 3, caché), `HomeController`
(agrupa, ADR ocultos y mostrados), tile (principal, desplegable, tap), pantalla de inicio,
cabecera del resultado, JSON con y sin los campos nuevos.

