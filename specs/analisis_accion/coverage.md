# Cobertura de criterios: analisis_accion

> Qué test comprueba cada criterio de `spec.md` y qué hay que verificar en
> dispositivo (tareas T51-T53). Rutas relativas a `app/test/features/analisis_accion/`.
> Revisado el 2026-09-30 (T50).

## Navegación y búsqueda

| # | Criterio | Tests | Dispositivo |
|---|---|---|---|
| 0 | Inicio con buscador e historial; abre el resultado | `presentation/screens/home_screen_test.dart` (abrir desde búsqueda y desde historial) | T51 |
| 1 | Coincidencias con símbolo, nombre, región y divisa, por relevancia | `home_screen_test.dart`; `infrastructure/adapters/tradingview_adapter_test.dart` (orden por relevancia); `tradingview_parser_test.dart` (búsqueda real "tesco") | T51 |
| 2 | Sin petición hasta confirmar (botón o intro) | `home_screen_test.dart` (no busca al escribir; busca con botón y con intro) | |
| 3 | Misma búsqueda desde la caché 30 días | `tradingview_adapter_test.dart` (una sola petición, TTL 30 días); `file_cache_adapter_test.dart` (caducidad) | |
| 4 | "No se ha encontrado ninguna acción" | `home_screen_test.dart`; `home_controller_test.dart` | |

## Análisis

| # | Criterio | Tests | Dispositivo |
|---|---|---|---|
| 5 | Progreso "paso X de 6" | `analysis_screen_test.dart`; `tradingview_adapter_test.dart` (pasos en orden); `formatters/labels_test.dart` | T51 |
| 6 | Solo se pide lo caducado o que falta | `tradingview_adapter_test.dart` (todo en caché → 0 peticiones; solo lo caducado) | T51 (segundo análisis sin gastar cuota) |
| 7 | El resultado se guarda en el historial | `application/use_cases/analyze_stock_use_case_test.dart` | T51 |
| 8 | Mismo `StockData` → mismo resultado | `domain/motor/stock_analyzer_test.dart` (determinismo) | |

## Resultado

| # | Criterio | Tests | Dispositivo |
|---|---|---|---|
| 9 | Cabecera: nombre, símbolo, precio, fecha, perfil, veredicto, nota, confianza, avisos | `analysis_screen_test.dart` (cabecera; precio, fecha y perfil) | T51 |
| 10 | 5 bloques plegados con nota y cobertura | `analysis_screen_test.dart` (bloques plegados; cobertura); `stock_analyzer_test.dart` (5 bloques) | |
| 11 | Al desplegar: etiqueta, valor, nota, nota explicativa | `analysis_screen_test.dart` (desplegar bloque); `formatters/metric_value_formatter_test.dart` | |
| 12 | Sin dato → "sin dato" con su nota, nunca 0 | `analysis_screen_test.dart` ("sin dato · No aplica..."); `metric_value_formatter_test.dart`; `domain/motor/indicators/metric_values_test.dart` (nada es 0) | |
| 13 | Sección "Datos que faltan" | `analysis_screen_test.dart`; `stock_analyzer_test.dart` (histórico corto) | |
| 14 | Aviso educativo y versión del motor | `analysis_screen_test.dart` | |

## Historial

| # | Criterio | Tests | Dispositivo |
|---|---|---|---|
| 15 | 10 últimos, el más reciente primero, con símbolo, nombre, veredicto y fecha | `infrastructure/adapters/file_analysis_history_adapter_test.dart`; `use_cases/load_history_use_case_test.dart`; `home_screen_test.dart` | |
| 16 | Máximo 10, sin duplicados, el repetido sube | `file_analysis_history_adapter_test.dart` | |
| 17 | Abrir del historial sin recalcular ni pedir datos | `analysis_screen_test.dart`; `controllers/analysis_controller_test.dart`; `home_screen_test.dart` | |
| 18 | "Datos de hace X" si está caducado | `analysis_screen_test.dart`; `analysis_controller_test.dart` (6 h); `domain/entities/history_entry_test.dart` | |
| 19 | Persistencia tras reiniciar | `file_analysis_history_adapter_test.dart`, `file_cache_adapter_test.dart` (nueva instancia) | **T52** |

## Actualizar y errores

| # | Criterio | Tests | Dispositivo |
|---|---|---|---|
| 20 | "Actualizar datos" ignora la caché | `analysis_controller_test.dart` (forceRefresh); `tradingview_adapter_test.dart` (forceRefresh) | T51 |
| 21 | Si falla la actualización, el resultado anterior sigue | `analysis_screen_test.dart`; `analysis_controller_test.dart` | |
| 22 | Mensaje de límite de peticiones sin perder lo mostrado | `analysis_screen_test.dart`; `formatters/error_messages_test.dart`; `tradingview_adapter_test.dart` (HTTP 429 y 403) | |
| 23 | "No hay datos para este símbolo" | `error_messages_test.dart`; `tradingview_adapter_test.dart` y `tradingview_parser_test.dart` (fixture real de símbolo inexistente) | |
| 24 | "Sin conexión" con reintentar; historial accesible | `analysis_screen_test.dart`; `tradingview_adapter_test.dart` (fallo de conexión) | **T53** |
| 25 | Respuesta inesperada: mensaje y sin caché | `tradingview_adapter_test.dart` (error y respuesta rechazada por el parser no se guardan); `error_messages_test.dart` | |
| 26 | Fallo a mitad: lo obtenido queda en caché | `tradingview_adapter_test.dart` | |
| 27 | Sin clave: mensaje, sin peticiones, historial accesible | `home_screen_test.dart`; `home_controller_test.dart`; `analysis_controller_test.dart`; `tradingview_adapter_test.dart` | **T53** |

## Casos del motor en la UI

| # | Criterio | Tests | Dispositivo |
|---|---|---|---|
| 28 | < 3 bloques → "Datos insuficientes" sin nota global | `analysis_screen_test.dart`; `stock_analyzer_test.dart`; `scoring/verdict_calculator_test.dart` | |
| 29 | Salud < 4 → como mucho neutral, con aviso | `verdict_calculator_test.dart`; `scoring/flag_detector_test.dart` | |
| 30 | Cierre de más de 7 días → confianza baja y aviso | `stock_analyzer_test.dart`; `verdict_calculator_test.dart`; `flag_detector_test.dart` | |
| 31 | Histórico corto → respaldo del perfil y aviso | `stock_analyzer_test.dart`; `tradingview_parser_test.dart` (IBM real, 100 sesiones) | T51 (plan gratuito) |

## Resultado del repaso

- Todos los criterios tienen al menos un test automático.
- Huecos encontrados y cubiertos en T50: criterios 2 (intro), 9 (precio, fecha y
  perfil), 10 (cobertura), 12, 13 y 28 en pantalla.
- Solo se pueden comprobar del todo en dispositivo: 19 (reinicio real de la app), 24
  (sin conexión real) y 27 (compilación sin clave). La comunicación real con Alpha
  Vantage (T51) tampoco tiene test automático: los tests usan respuestas reales
  guardadas, no la red.

---

## Revisión 2: proveedor TradingView (2026-10-06)

Sustituye a los criterios 5, 22 (causa), 27 y 31 y reescribe las filas que mencionaban
Alpha Vantage: 3 (caché de 6 h en vez de 30 días), 6 (una sola petición) y 26 (ya no
hay varias respuestas parciales). Los nombres de test de las tablas de arriba se han
actualizado a los archivos de TradingView.

| # | Criterio | Tests | Dispositivo |
|---|---|---|---|
| 32 | Progreso de un solo paso | `presentation/formatters/labels_test.dart`; `screens/analysis_screen_test.dart`; `tradingview_adapter_test.dart` (avisa del paso) | T66 |
| 33 | Bloqueo (429/403) → mensaje de límite | `tradingview_adapter_test.dart`; `error_messages_test.dart` | |
| 34 | Sin aviso de clave | Eliminado el código de clave; `home_screen_test.dart` ya no tiene el caso | |
| 35 | Sin histórico → aviso y métricas "sin dato" | `scoring/flag_detector_test.dart` (una barra); `indicators/metric_values_test.dart` (respaldos) | |
| 36 | Cotización de origen primero con su divisa | `tradingview_parser_test.dart` (búsqueda real "nintendo") | T66 |
| 37 | Sin mezclar monedas | `tradingview_parser_test.dart` (capitalización nula, ADR sin moneda de reporte); `metric_values_test.dart` (ratios del proveedor) | |
| 38 | Caché de 6 h, una petición por análisis | `tradingview_adapter_test.dart` | |
| 39 | Sin fila → "No hay datos para este símbolo" | `tradingview_parser_test.dart`; `tradingview_adapter_test.dart` | T66 |
| 40 | Formato cambiado → respuesta inesperada y sin caché | `tradingview_parser_test.dart` (campo con otro tipo, fila de otro tamaño); `tradingview_adapter_test.dart` (HTML en lugar de JSON) | |

Comprobado además en vivo (2026-10-06, sin test automático porque los tests no usan la
red): búsqueda de Nintendo, Fast Retailing e Iberdrola, análisis de `TSE:7974`, `TSE:9983`
y `BME:IBE`, y `NotFoundException` para un símbolo inexistente.

---

## Revisión 3: histórico real y gráfica de precio (2026-10-08)

Sustituye al criterio 35 (sin histórico → aviso). Rutas relativas a `app/test/features/analisis_accion/`.

| # | Criterio | Tests | Dispositivo |
|---|---|---|---|
| 44 | Pestañas Resumen (por defecto) y Detalle | `presentation/screens/analysis_screen_test.dart` (grupo "con pestañas") | T80 |
| 45 | El estado de Detalle se conserva; "Actualizar datos" actúa sobre las dos | `analysis_screen_test.dart` | T80 |
| 46 | Línea de cierres del último año con selector de periodo | `widgets/price_chart_panel_test.dart`; `controllers/price_chart_controller_test.dart` | T80 |
| 47 | El periodo redibuja; histórico corto muestra todo | `price_chart_panel_test.dart`; `price_chart_controller_test.dart`; `domain/chart/price_series_test.dart` | |
| 48 | Máximo y mínimo marcados con valor y fecha | `price_chart_panel_test.dart`; `price_series_test.dart` | T80 |
| 49 | Fecha y precio al tocar | Sin test automático (tooltip de `fl_chart`) | **T80** |
| 50 | Medias de 50 y 200: desactivadas, sin inventar | `price_chart_controller_test.dart`; `price_chart_panel_test.dart`; `price_series_test.dart` | |
| 51 | Agrupado de puntos conservando máximos y mínimos | `price_series_test.dart`; `price_chart_controller_test.dart` | T80 (fluidez) |
| 52 | Pie de fuente | `price_chart_panel_test.dart` | |
| 53 | Sin histórico: error con Reintentar y Detalle intacto | `price_chart_panel_test.dart`; `analysis_screen_test.dart`; `infrastructure/adapters/tradingview_adapter_test.dart` | **T80** |
| 54 | Caché de 6 h; "Actualizar datos" la vuelve a pedir | `tradingview_adapter_test.dart`; `tradingview_history_client_test.dart` | |
| 55 | Con ≥ 252 sesiones, MACD, pendiente y caída máxima con valor y sin aviso | `domain/motor/stock_analyzer_test.dart` | T79 (en vivo) |
| 56 | Un fallo del histórico nunca impide analizar | `tradingview_adapter_test.dart` (fallback a la barra única); `stock_analyzer_test.dart` | |
| 57 | Velas incoherentes descartadas | `infrastructure/adapters/tradingview_chart_protocol_test.dart` | |

Los tests del canal de gráficos usan una transcripción real guardada (`chart_tse_7974`,
`chart_unknown_symbol`), no la red.

---

## Revisión 4: gráfica del día y de la última semana (2026-10-08)

Rutas relativas a `app/test/features/analisis_accion/`.

| # | Criterio | Tests | Dispositivo |
|---|---|---|---|
| 58 | Selector con 1D y 1S delante; 1A por defecto | `presentation/widgets/price_chart_panel_test.dart`; `presentation/formatters/labels_test.dart` | T89 |
| 59 | 1D: última sesión en velas de 5 minutos, eje en horas de la bolsa | `price_chart_panel_test.dart`; `price_chart_controller_test.dart`; `infrastructure/adapters/tradingview_adapter_test.dart` | **T89** |
| 60 | 1S: 5 sesiones pegadas, con el día de cada una | `price_chart_panel_test.dart`; `price_chart_controller_test.dart`; `domain/chart/sessions_test.dart` | **T89** |
| 61 | Máximo y mínimo con día y hora | `price_chart_panel_test.dart` | |
| 62 | Tooltip con día, hora y precio | `price_chart_panel_test.dart` (contenido del tooltip) | T89 (el toque) |
| 63 | Medias ocultas en 1D y 1S y recordadas | `price_chart_panel_test.dart`; `price_chart_controller_test.dart` | |
| 64 | Pie con sesión, horas de la bolsa o del dispositivo, y retraso | `price_chart_panel_test.dart`; `domain/chart/exchange_clock_test.dart` (cambios de hora de la UE y de EE. UU.) | |
| 65 | Caché de 5 minutos; "Actualizar datos" la vuelve a pedir | `tradingview_adapter_test.dart`; `price_chart_controller_test.dart` | |
| 66 | Un fallo del intradía solo afecta a esa vista | `price_chart_panel_test.dart`; `price_chart_controller_test.dart` | |
| 67 | Con menos sesiones de las pedidas, las que haya | `sessions_test.dart`; `price_chart_controller_test.dart` | |

Los tests del canal usan transcripciones reales guardadas (`chart_intra5_bme_ibe`,
`chart_intra30_tse_7974`). Comprobado además en vivo el 2026-10-08 con Nintendo, Fast Retailing,
Iberdrola y Apple: sesiones bien cortadas y horas de cada bolsa correctas.

---

## Revisión 5: búsqueda sin versiones duplicadas (2026-10-08)

Sustituye al criterio 1. Rutas relativas a `app/test/features/analisis_accion/`.

| # | Criterio | Tests | Dispositivo |
|---|---|---|---|
| 72 | Una fila por empresa, con la principal etiquetada | `domain/search/group_listings_test.dart`; `presentation/widgets/company_listings_tile_test.dart`; `presentation/screens/home_screen_test.dart`; `infrastructure/adapters/tradingview_parser_test.dart` (búsquedas reales de Nintendo e Iberdrola) | T98 |
| 73 | "Otras cotizaciones (n)" plegado, euros primero | `group_listings_test.dart`; `company_listings_tile_test.dart` | T98 |
| 74 | Pulsar la empresa analiza la principal; otra cotización, esa | `company_listings_tile_test.dart`; `home_screen_test.dart` | T98 |
| 75 | ADR ocultos con "Mostrar certificados ADR (n)" | `controllers/home_controller_test.dart`; `home_screen_test.dart`; `company_listings_tile_test.dart` | |
| 76 | Sin ISIN, no aparece | `group_listings_test.dart`; `tradingview_parser_test.dart` (Apple real) | |
| 77 | Completar por ISIN cuando falta la principal ("Inditex" → `BME:ITX`) | `infrastructure/adapters/tradingview_adapter_test.dart`; `tradingview_parser_test.dart` (búsqueda real de "inditex" y de su ISIN) | **T98** |
| 78 | Buscar por ISIN agrupa todas sus cotizaciones | `tradingview_adapter_test.dart`; `tradingview_parser_test.dart` | T98 |
| 79 | Orden por relevancia, principal primero | `group_listings_test.dart` | |
| 80 | La cabecera muestra bolsa, ISIN y principal/otra | `presentation/widgets/verdict_header_test.dart`; `tradingview_parser_test.dart`; `domain/motor/stock_analyzer_test.dart` | T98 |
| 81 | Un análisis antiguo se ve igual, sin esa línea | `infrastructure/adapters/analysis_result_json_test.dart`; `verdict_header_test.dart` | |
| 82 | Si falla la búsqueda complementaria, se ven los resultados de la primera | `tradingview_adapter_test.dart` | |
| 83 | Misma búsqueda en 6 h sale de la caché (complementaria incluida) | `tradingview_adapter_test.dart` | |

Comprobado además en vivo el 2026-10-08: "nintendo" (1 empresa principal + ADR ocultos), "inditex"
(`BME:ITX` principal con 20 cotizaciones; antes solo OTC), `JP3756600007` (1 empresa), "iberdrola",
"apple" y "santander".

## Revisión 6: conversor a euros (criterios 84-97)

| Criterios | Tests |
|---|---|
| 84-86 Euros por defecto, selector a la divisa original, sin selector en euros | `presentation/widgets/currency_switch_test.dart`; `controllers/display_currency_controller_test.dart` |
| 87-89 Cierres, extremos y medias convertidos con el tipo de cada día; día y semana con el último | `controllers/price_chart_controller_test.dart` (grupo "en euros") |
| 90 Aviso de gráfica convertida | `price_chart_panel.dart` (`convertedChartCaption`) |
| 91-93 Tipos del BCE con respaldo del BdE, arrastre de fin de semana, GBX/ZAC/ILA | `domain/currency/*_test.dart`; `infrastructure/adapters/{ecb_rate_parser,bde_rate_parser,ecb_exchange_rate_adapter,fallback_and_cached_exchange_rate_adapter}_test.dart` |
| 94-95 Caché de 6 h y "Actualizar datos" | `fallback_and_cached_exchange_rate_adapter_test.dart`; `display_currency_controller_test.dart` |
| 96-97 Estados cargando / sin tipo / fallo y tipo antiguo | `currency_switch_test.dart` |

Comprobado en vivo el 2026-10-08: BCE JPY (177,05) y GBP; SAR sin tipo (NotFound); BdE JPY (176,85 del día 7).

## Revisión 7: orientación didáctica (criterios 98-105)

| Criterios | Tests |
|---|---|
| 98-102 Tarjeta "Lo esencial", semáforo, apertura de la explicación y casos sin métricas | `presentation/widgets/essentials_card_test.dart` |
| 100 Cortes del semáforo | `essentials_card_test.dart` (`signalForScore`) |
| 103-104 Etiquetas "Trade Republic" y "Esencial" | `essentials_card_test.dart`; `metric_row_test.dart` |
| 105 No recomienda | texto fijo de la tarjeta (revisión) |

