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
- [x] T07. `domain/entities/stock_data.dart` (con `fetchedAt`; histórico ascendente e
      informes del más reciente al más antiguo, como invariante documentado).
- [x] T08. `domain/entities/symbol_match.dart` y `fetch_step.dart`.
- [x] T09. `domain/entities/analysis_result.dart` (`AnalysisResult`, `BlockResult`,
      `MetricResult` y los enums `Verdict`, `Confidence`, `CompanyProfile`, `Horizon`,
      `Block` y `MetricFormat`).
- [x] T10. `domain/entities/history_entry.dart`.
- [x] T11. `domain/exceptions/market_data_exception.dart` con sus 5 subtipos.

Motor (seguir la skill `motor-analisis` y `references/metricas.md`):

- [x] T12. `domain/motor/motor_version.dart`.
- [x] T13. `domain/motor/scoring/piecewise_scale.dart`: `ScorePoint`, interpolación,
      saturación y redondeo.
- [x] T14. `domain/motor/indicators/technical_indicators.dart`: SMA, EMA, RSI, MACD,
      pendiente de la SMA200, caída máxima y máximo de 52 semanas. Rentabilidades,
      volatilidad y mínimo de 52 semanas no se implementan: ninguna regla ni alarma los
      usa (se añaden con la métrica que los necesite).
- [x] T15. `domain/motor/indicators/fundamental_ratios.dart`: TTM, FCF, ratios de salud, márgenes, CAGR, ROIC (con el tipo impositivo de
      respaldo), ROE, dilución, dividendo/FCF, P/FCF y sorpresas de BPA.
- [x] T16. `domain/motor/rules/metric_rule.dart` (`MetricRule`, `MetricScoring`) e
      `indicators/metric_value.dart` (`MetricValue`: distingue "sin dato" de "no aplica").
- [x] T17. `domain/motor/rules/metric_rules.dart`: las 30 reglas de las secciones 2-6 de
      `metricas.md`, con perfiles y pesos.
- [x] T18. `domain/motor/rules/block_weights.dart`, `verdict_thresholds.dart`,
      `profile_criteria.dart` y `flag_rules.dart` (umbrales de avisos junto a su texto).
- [x] T19. `domain/motor/indicators/metric_values.dart`: valor de cada `id` a partir de
      `StockData`, respaldo del perfil si hay menos de 200 sesiones y notas explicativas
      cuando el valor es `null` por un motivo conocido.
- [x] T20. `domain/motor/scoring/profile_detector.dart`.
- [x] T21. `domain/motor/scoring/block_scorer.dart`: nota y cobertura.
- [x] T22. `domain/motor/scoring/verdict_calculator.dart`: nota global, veredicto,
      coherencia por salud y confianza.
- [x] T23. `domain/motor/scoring/flag_detector.dart`: alarmas de la sección 7, datos
      antiguos, histórico corto, veredicto limitado y resultados en 14 días o menos.
- [x] T24. `domain/motor/stock_analyzer.dart`: ensambla el `AnalysisResult` (con los
      datos que faltan y la versión del motor).

## Ports

- [x] T25. `domain/ports/market_data_port.dart` (con `forceRefresh` y `onProgress`).
- [x] T26. `domain/ports/cache_port.dart`.
- [x] T27. `domain/ports/analysis_history_port.dart`.

## Adapters

- [x] T28. Capturar fixtures reales en `app/test/fixtures/alpha_vantage/`: los 7
      endpoints para `IBM` con la clave `demo` de Alpha Vantage (no gasta cuota), una
      búsqueda sin resultados y respuestas de error (`Note`, `Information` y
      `Error Message`, además del aviso de `outputsize=full` premium). La clave
      nunca queda en los fixtures.
- [x] T29. `infrastructure/adapters/alpha_vantage_error_detector.dart`.
- [x] T30. `infrastructure/adapters/alpha_vantage_parser.dart`: números en texto,
      ausentes a `null`, signos, orden, deuda y caja con respaldo (las entidades las
      reciben ya resueltas).
- [x] T31. Confirmar en la documentación de Alpha Vantage el límite por minuto actual y
      ajustar la pausa por defecto (decisión 6 del plan).
- [x] T32. `infrastructure/adapters/alpha_vantage_adapter.dart`: secuencia con pausa,
      caché por endpoint con su caducidad, JSON en crudo en caché, recuerdo de
      `full_history_unavailable`, `forceRefresh`, progreso, `MissingApiKeyException` y
      claves de caché sin la clave de la API.
- [x] T33. `infrastructure/adapters/file_cache_adapter.dart`.
- [x] T34. `infrastructure/adapters/analysis_result_json.dart`.
- [x] T35. `infrastructure/adapters/file_analysis_history_adapter.dart`: como máximo 10
      entradas, sin duplicados y la más reciente primero.

## Use cases

- [x] T36. `application/use_cases/search_symbol_use_case.dart`.
- [x] T37. `application/use_cases/analyze_stock_use_case.dart` (reloj inyectado).
- [x] T38. `application/use_cases/load_history_use_case.dart`.

## Presentation

- [x] T39. `presentation/formatters/metric_value_formatter.dart` y `error_messages.dart`.
- [x] T40. `presentation/controllers/home_controller.dart`.
- [x] T41. `presentation/controllers/analysis_controller.dart` (la actualización forzada
      conserva el resultado anterior si falla).
- [x] T42. Widgets de inicio: `search_bar_section.dart`, `symbol_match_tile.dart` e
      `history_list.dart`.
- [x] T43. Widgets de resultado: `verdict_header.dart`, `flags_section.dart`,
      `block_tile.dart`, `metric_row.dart`, `missing_data_section.dart`,
      `analysis_progress.dart` y `educational_disclaimer.dart`.
- [x] T44. `presentation/screens/home_screen.dart` y `analysis_screen.dart`.
- [x] T45. `app/lib/core/theme/app_theme.dart`, composition root en `app/lib/app.dart` y
      `app/lib/main.dart` (clave con `String.fromEnvironment`).

## Tests

- [x] T46. `test/.../domain/motor/synthetic_companies.dart`: empresa de calidad →
      `favorable` y empresa frágil → `desfavorable`.
- [x] T47. Casos límite del motor: PER con beneficios negativos, perfil financiero,
      salud < 4, datos vacíos → `datos_insuficientes`, datos antiguos → confianza `baja`
      y determinismo.
- [x] T48. `metric_rules`: `id` únicos, escalas ordenadas y coincidencia con los `id` de
      `metricas.md`.
- [x] T49. `test/.../application/fake_ports.dart` completos y compartidos por los
      tests de use cases y controllers.
- [x] T50. Repasar los 32 criterios de `spec.md` y anotar qué test cubre cada uno o si
      se verifica en dispositivo. Resultado en `coverage.md`.

## Verificación en dispositivo

- [ ] T51. Con clave real: una búsqueda, un análisis completo, un análisis repetido desde
      la caché y "Actualizar datos".
- [ ] T52. Persistencia del historial y de la caché tras cerrar la app y volver a
      abrirla.
- [ ] T53. Sin conexión y sin clave: mensajes correctos y el historial accesible.

## Revisión

- [ ] T54. `flutter-reviewer`
- [ ] T55. Actualizar `AGENTS.md` con las rutas nuevas.

---

## Revisión 2: proveedor TradingView

> Derivadas de la Revisión 2 de `plan.md`. Mismas reglas que arriba.

### Domain

- [x] T56. `CompanyOverview` con los ratios opcionales nuevos, `FetchStep.fetching` y
      sin `MissingApiKeyException`.
- [x] T57. `metric_values.dart` con el respaldo `calculado ?? ratio del proveedor` y
      `flag_detector.dart` con el aviso de "Sin histórico de precios"; `motorVersion`
      `1.1.0`. Tests del motor con una empresa sin barras diarias.

### Infrastructure

- [x] T58. Fixtures reales en `app/test/fixtures/tradingview/` (búsqueda "nintendo",
      scanner de `TSE:7974`, `TSE:9983`, `BME:IBE`, `NASDAQ:AAPL` y una respuesta sin
      filas).
- [x] T59. `tradingview_fields.dart` y `tradingview_parser.dart` con su test sobre las
      fixtures: nombres de campo reales, fechas de series, porcentajes → fracción,
      `null` por ausente, orden y monedas.
- [x] T60. `tradingview_adapter.dart` con su test (`MockClient` + fake de caché):
      caché 6 h, `forceRefresh`, errores tipados y sin guardar errores.
- [x] T61. Eliminar el adapter, parser, detector de errores y fixtures de Alpha Vantage.

### Presentation y composición

- [x] T62. Quitar la gestión de clave de `app.dart`, `main.dart`, controllers, pantallas y
      mensajes; progreso de un paso; ajustar los tests.
- [x] T63. Eliminar `config/secrets*.json`, la regla de `.gitignore` y las dependencias que
      sobren.

### Configuración y verificación

- [x] T64. Actualizar skills `datos-mercado` y `motor-analisis`, `metricas.md`,
      `project-policies.md` y `AGENTS.md`.
- [x] T65. `dart format`, `flutter analyze` y `flutter test` limpios.
- [ ] T66. En dispositivo: buscar "Nintendo", analizarla, repetir desde caché y
      "Actualizar datos"; Iberdrola y Fast Retailing; sin conexión.
- [x] T67. `flutter-reviewer`.

### Noticias recientes

- [x] T68. `LinkOpenerPort`, `OpenNewsUseCase` (con test de la URL), `UrlLauncherAdapter`,
      dependencia `url_launcher` y `<queries>` de Android.
- [x] T69. `AnalysisController.openNews()`, botón en `AnalysisScreen`, cableado en `app.dart`
      y tests del controller y de la pantalla.

---

## Revisión 3: histórico real y gráfica de precio

> Derivadas de la Revisión 3 de `plan.md`. Mismas reglas que arriba.

### Domain y application

- [x] T70. `ChartRange` y `price_series.dart` (`sliceRange`, `movingAverageSeries`, `downsample`,
      `closeExtremes`) + tests.
- [x] T71. `PriceHistoryPort` y `GetPriceHistoryUseCase` + test con fake.

### Infrastructure

- [x] T72. Capturar una transcripción real del WebSocket en `app/test/fixtures/tradingview/` y
      `tradingview_chart_protocol.dart` + tests (paquetes, latidos, serie, errores, velas
      incoherentes).
- [x] T73. `ChartConnection`, `IoChartConnection` y `TradingViewHistoryClient` + tests con
      conexión falsa.
- [x] T74. `TradingViewAdapter` implementa `PriceHistoryPort`: caché compacta de 6 h,
      peticiones unidas y fallback en `fetchStockData`; el parser acepta histórico + tests.

### Presentation

- [x] T75. Dependencia `fl_chart`; `PriceChartController` + tests.
- [x] T76. `PriceLineChart` y `PriceChartPanel` + tests de widget.
- [x] T77. `AnalysisScreen` con pestañas Resumen/Detalle (y "Actualizar datos" en ambas) +
      cableado en `app.dart`; actualizar los tests existentes.

### Motor y documentación

- [x] T78. `motorVersion` 1.2.0; test de una empresa con histórico largo (MACD, pendiente y
      caída máxima con valor, sin aviso); `metricas.md` y skill `datos-mercado`.

### Verificación

- [x] T79. `dart format`, `flutter analyze` y `flutter test` limpios; análisis en vivo de
      Nintendo, Fast Retailing e Iberdrola con gráfica y motor.
- [ ] T80. En el móvil: pestañas, periodos, medias, toque sobre la gráfica y fallo sin conexión.
- [x] T81. `flutter-reviewer`.

---

## Revisión 4: gráfica del día y de la última semana

- [x] T82. Dominio: `IntradayBar`, `IntradaySeries`, `IntradayResolution`, `ChartRange.day/week`,
      `sessions.dart`, `exchange_clock.dart` + tests (pausa de Tokio, fin de semana, cambio de
      hora de la UE y de EE. UU.).
- [x] T83. `IntradayHistoryPort` y `GetIntradayHistoryUseCase` + test.
- [x] T84. Capturar transcripciones reales de 5 y 30 minutos; protocolo con `Candle`,
      `symbol_resolved` y resolución + tests.
- [x] T85. Cliente (`fetchCandles`), caché compacta del intradía y adapter (5 minutos, descargas
      unidas) + tests.
- [x] T86. `PriceChartController` con intradía bajo demanda + tests.
- [x] T87. Gráfica (eje por orden, etiquetas de hora y día, tooltip) y panel (1D/1S, medias
      ocultas, pie, error propio) + tests.
- [x] T88. `dart format`, `flutter analyze` y `flutter test`; prueba en vivo con Nintendo,
      Iberdrola y Apple; `flutter-reviewer`.
- [ ] T89. En el móvil: 1D y 1S con mercado abierto y cerrado.

---

## Revisión 5: búsqueda sin versiones duplicadas

- [x] T90. `SymbolMatch` ampliado, `CompanyListings` y `group_listings.dart` + tests.
- [x] T91. Fixtures reales de la búsqueda ("nintendo", "iberdrola", "inditex" y su ISIN) y
      parser de búsqueda con los campos nuevos + tests.
- [x] T92. `searchSymbol` del adapter con complementación por ISIN, fallo aislado, límite y caché + tests.
- [x] T93. `SearchSymbolUseCase` devuelve empresas agrupadas + test.
- [x] T94. Scanner: columnas `isin`, `exchange`, `is_primary` (ampliar las fixtures existentes);
      `CompanyOverview`, `AnalysisResult` y su JSON + tests.
- [x] T95. `HomeController`, `company_listings_tile.dart` y `HomeScreen` + tests.
- [x] T96. Cabecera del resultado con bolsa, ISIN y principal + test.
- [x] T97. `dart format`, `flutter analyze`, `flutter test`; prueba en vivo ("nintendo",
      "inditex", ISIN); `flutter-reviewer`; skill `datos-mercado`.
- [ ] T98. En el móvil: buscar "Inditex", "Nintendo" y un ISIN.

---

## Revisión 6: conversor a euros

- [x] T99. Dominio: `ExchangeRateSeries`, `QuoteCurrency`/`resolveQuoteCurrency` y `euro_conversion.dart`
      + tests (arrastre, antes del primer tipo, GBX/ZAC/ILA, euro).
- [x] T100. `ExchangeRatePort` y `GetExchangeRatesUseCase` + test.
- [x] T101. Capturar respuestas reales (BCE y CSV recortado del BdE) y parsers + tests.
- [x] T102. Adapters del BCE y del BdE + tests con cliente falso.
- [x] T103. `FallbackExchangeRateAdapter` y `CachedExchangeRateAdapter` + tests.
- [x] T104. `DisplayCurrencyController` + tests.
- [x] T105. `PriceChartController` con valores convertidos + tests.
- [x] T106. `CurrencySwitch`, cabecera y panel con la moneda mostrada + tests.
- [x] T107. `AnalysisScreen` y composition root; historial en euros.
- [x] T108. `dart format`, `flutter analyze`, `flutter test`; prueba en vivo con Nintendo,
      Tesco (GBX) y una moneda sin tipo; `flutter-reviewer`; skill `datos-mercado`.
- [ ] T109. En el móvil: selector, gráficas en euros y sin conexión.

---

## Revisión 7: orientación didáctica

- [x] T110. `metric_guidance.dart` (esenciales, Trade Republic, semáforo) + tests.
- [x] T111. `EssentialsCard` + tests.
- [x] T112. Etiquetas en `MetricRow`; tarjeta en Resumen + tests.
- [x] T113. `dart format`, `flutter analyze`, `flutter test`; `flutter-reviewer`; `coverage.md`.
- [ ] T114. En el móvil: la tarjeta, los colores y las etiquetas.
- [x] T115. Lista de Trade Republic tomada de su ayuda oficial (PER, P/VC y beta).

---

## Revisión 8: aspecto, favoritas y últimas consultas

- [x] T116. Fuentes empaquetadas, `app_theme.dart` y `signal_colors.dart`; semáforo del tema.
- [x] T117. Cabecera rediseñada y `ScoreScale`.
- [x] T118. `Favorite`, `FavoritesPort`, casos de uso, `FileFavoritesAdapter` y `clear()` del historial + tests.
- [x] T119. `FavoriteController`, estrella en `AnalysisScreen` + tests.
- [x] T120. `HomeController`, `FavoritesList`, `RecentQueriesSection` y pantalla principal + tests.
- [ ] T121. `dart format`, `flutter analyze`, `flutter test` (el usuario; lo escrito aún no se ha compilado).
- [ ] T122. Revisión con `flutter-reviewer` y prueba en el móvil (claro y oscuro).

