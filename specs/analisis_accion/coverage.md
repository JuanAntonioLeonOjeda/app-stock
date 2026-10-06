# Cobertura de criterios: analisis_accion

> Qué test comprueba cada criterio de `spec.md` y qué hay que verificar en
> dispositivo (tareas T51-T53). Rutas relativas a `app/test/features/analisis_accion/`.
> Revisado el 2026-09-30 (T50).

## Navegación y búsqueda

| # | Criterio | Tests | Dispositivo |
|---|---|---|---|
| 0 | Inicio con buscador e historial; abre el resultado | `presentation/screens/home_screen_test.dart` (abrir desde búsqueda y desde historial) | T51 |
| 1 | Coincidencias con símbolo, nombre, región y divisa, por relevancia | `home_screen_test.dart`; `infrastructure/adapters/alpha_vantage_adapter_test.dart` (orden por relevancia); `alpha_vantage_parser_test.dart` (búsqueda real "tesco") | T51 |
| 2 | Sin petición hasta confirmar (botón o intro) | `home_screen_test.dart` (no busca al escribir; busca con botón y con intro) | |
| 3 | Misma búsqueda desde la caché 30 días | `alpha_vantage_adapter_test.dart` (una sola petición, TTL 30 días); `file_cache_adapter_test.dart` (caducidad) | |
| 4 | "No se ha encontrado ninguna acción" | `home_screen_test.dart`; `home_controller_test.dart` | |

## Análisis

| # | Criterio | Tests | Dispositivo |
|---|---|---|---|
| 5 | Progreso "paso X de 6" | `analysis_screen_test.dart`; `alpha_vantage_adapter_test.dart` (pasos en orden); `formatters/labels_test.dart` | T51 |
| 6 | Solo se pide lo caducado o que falta | `alpha_vantage_adapter_test.dart` (todo en caché → 0 peticiones; solo lo caducado) | T51 (segundo análisis sin gastar cuota) |
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
| 20 | "Actualizar datos" ignora la caché | `analysis_controller_test.dart` (forceRefresh); `alpha_vantage_adapter_test.dart` (forceRefresh) | T51 |
| 21 | Si falla la actualización, el resultado anterior sigue | `analysis_screen_test.dart`; `analysis_controller_test.dart` | |
| 22 | Mensaje de límite de peticiones sin perder lo mostrado | `analysis_screen_test.dart`; `formatters/error_messages_test.dart`; `alpha_vantage_error_detector_test.dart` (textos de límite) | |
| 23 | "No hay datos para este símbolo" | `error_messages_test.dart`; `alpha_vantage_adapter_test.dart` y `alpha_vantage_error_detector_test.dart` (fixture real de símbolo inexistente) | |
| 24 | "Sin conexión" con reintentar; historial accesible | `analysis_screen_test.dart`; `alpha_vantage_adapter_test.dart` (fallo de conexión) | **T53** |
| 25 | Respuesta inesperada: mensaje y sin caché | `alpha_vantage_adapter_test.dart` (error y respuesta rechazada por el parser no se guardan); `error_messages_test.dart` | |
| 26 | Fallo a mitad: lo obtenido queda en caché | `alpha_vantage_adapter_test.dart` | |
| 27 | Sin clave: mensaje, sin peticiones, historial accesible | `home_screen_test.dart`; `home_controller_test.dart`; `analysis_controller_test.dart`; `alpha_vantage_adapter_test.dart` | **T53** |

## Casos del motor en la UI

| # | Criterio | Tests | Dispositivo |
|---|---|---|---|
| 28 | < 3 bloques → "Datos insuficientes" sin nota global | `analysis_screen_test.dart`; `stock_analyzer_test.dart`; `scoring/verdict_calculator_test.dart` | |
| 29 | Salud < 4 → como mucho neutral, con aviso | `verdict_calculator_test.dart`; `scoring/flag_detector_test.dart` | |
| 30 | Cierre de más de 7 días → confianza baja y aviso | `stock_analyzer_test.dart`; `verdict_calculator_test.dart`; `flag_detector_test.dart` | |
| 31 | Histórico corto → respaldo del perfil y aviso | `stock_analyzer_test.dart`; `alpha_vantage_parser_test.dart` (IBM real, 100 sesiones) | T51 (plan gratuito) |

## Resultado del repaso

- Todos los criterios tienen al menos un test automático.
- Huecos encontrados y cubiertos en T50: criterios 2 (intro), 9 (precio, fecha y
  perfil), 10 (cobertura), 12, 13 y 28 en pantalla.
- Solo se pueden comprobar del todo en dispositivo: 19 (reinicio real de la app), 24
  (sin conexión real) y 27 (compilación sin clave). La comunicación real con Alpha
  Vantage (T51) tampoco tiene test automático: los tests usan respuestas reales
  guardadas, no la red.
