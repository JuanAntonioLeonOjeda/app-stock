---
name: datos-mercado
description: Cómo obtener datos bursátiles de forma programática para el motor de análisis: elección de proveedor, endpoints necesarios, particularidades de las respuestas, normalización a StockData, caché, límites de peticiones, errores y paso futuro a un backend propio. Úsala SIEMPRE que la tarea implique llamar a una API financiera, buscar un ticker, parsear respuestas, faltan datos en un análisis, falla una petición, se quiere cambiar de proveedor o se plantea añadir un backend.
---

# Datos de mercado

## Cómo se consultan los datos

Los datos se piden con **peticiones HTTP directas a la API REST del proveedor, escritas como código del proyecto** (cliente HTTP dentro del adapter del proveedor, en `infrastructure/adapters/`). No uses servidores MCP, conectores ni ninguna herramienta de IA para esto: el análisis debe funcionar sin Claude en ejecución, de forma reproducible y testeable.

Aunque en tu sesión de desarrollo tengas herramientas MCP de datos financieros disponibles, no las uses para implementar la funcionalidad. Como mucho, sirven para inspeccionar a mano una respuesta real y guardarla como fixture de test.

Origen de cada dato con el proveedor actual (TradingView):

| Origen | Métricas |
|---|---|
| Vienen ya calculadas por el proveedor | PER, PEG, P/VC, P/Ventas, EV/EBITDA, P/FCF, beta, rentabilidad por dividendo, ROE, ROIC, márgenes, deuda/patrimonio, liquidez, RSI, SMA50/200 y máx./mín. 52 semanas |
| Las calcula el código a partir de las series anuales y trimestrales | Crecimiento (CAGR), FCF positivo, margen operativo y bruto (si hay serie), TTM |
| No llegan (sin dato) | MACD, volatilidad, caída máxima, pendiente de la SMA200, cobertura de intereses, sorpresas de BPA, potencial hasta el precio objetivo, dilución, tendencia del margen |

Regla práctica: si el proveedor da el ratio ya calculado y su definición es fiable, úsalo; si no, calcúlalo tú para controlar la fórmula y poder testearla. Con TradingView es obligatorio usar su ratio donde el cálculo propio mezclaría monedas (ver "Particularidades").

## Interfaz de proveedor

Todo acceso a datos pasa por un único port, `MarketDataPort`, con dos operaciones:
- `searchSymbol(query)` → lista de coincidencias (símbolo, nombre, región, divisa, puntuación).
- `fetchStockData(symbol)` → `StockData` normalizado (contrato en la skill `motor-analisis`).

Errores tipados como excepciones de `domain/` (ver `.claude/rules/code-style.md`): `RateLimitException`, `NotFoundException`, `InvalidResponseException`, `NetworkException`. Cambiar de proveedor no debe tocar nada fuera de su adapter.

## Proveedor actual: TradingView

Elegido el 2026-10-06 porque cubre bolsas de todo el mundo (Tokio, Madrid...), da fundamentales y series, y no necesita clave ni tiene un cupo diario conocido. **Es no oficial**: son los endpoints de su propio buscador y screener. Pueden cambiar o cortarse sin aviso y sus condiciones de uso no amparan un producto público: vale para uso personal; antes de publicar en una tienda hace falta un proveedor con licencia (ver "Proveedores alternativos").

| Qué | Petición |
|---|---|
| Buscar | `GET https://symbol-search.tradingview.com/symbol_search/v3/?text=…&search_type=stock&start=0`, con la cabecera `Origin: https://www.tradingview.com` |
| Datos | `POST https://scanner.tradingview.com/global/scan` con `{"symbols":{"tickers":["TSE:7974"]},"columns":[…]}`: una sola petición devuelve todo |

La lista de campos pedidos está en `infrastructure/adapters/tradingview_fields.dart`. El símbolo completo es `BOLSA:TICKER` (`TSE:7974`, `BME:IBE`, `NASDAQ:AAPL`).

## Particularidades (causa habitual de bugs)

- **Un campo desconocido llega como `null` sin error.** Un nombre mal escrito no falla: sale "sin dato" para siempre. Los nombres se validan contra una respuesta real guardada (`tradingview_parser_test.dart`), no contra la API.
- **Escalares en USD, series en la moneda de reporte.** Capitalización, deuda neta, EBITDA TTM, patrimonio... (`*_ttm`, `*_fq`, `market_cap_basic`) vienen **convertidos a USD** (`fundamental_currency_code`), aunque el precio esté en JPY o EUR. Las series `*_fy_h` (20 años) y `*_fq_h` (32 trimestres) vienen en la moneda de reporte de la empresa. Nunca dividas un escalar entre una serie ni precio entre un importe: usa los ratios del proveedor, que no tienen unidad. Por eso la capitalización no se pasa al motor.
- **Porcentajes en %**, no en fracción: `return_on_equity = 16,9`. El parser divide entre 100 (`dividends_yield`, `operating_margin_ttm`...). `debt_to_equity_fq`, `current_ratio_fq` y el resto de ratios ya son cocientes.
- **Las series no traen fechas.** Se fechan restando 12 (anual) o 3 (trimestral) meses a `fiscal_period_end_fy` y `fiscal_period_end_current`, que son epoch en segundos. Las series vienen del más reciente al más antiguo y pueden contener `null` sueltos.
- **No hay histórico diario de precios.** Solo el último cierre (`close`, `open`, `high`, `low`, `volume`, fecha en `time`): el adapter entrega una única `DailyBar`. RSI, SMA50/200 y máx./mín. 52 semanas llegan ya calculados y el motor los usa como respaldo.
- **FCF vacío en algunas empresas** (comprobado con Nintendo e Iberdrola). El proveedor solo da el FCF ya restado: se guarda como flujo operativo con CAPEX 0.
- **No llegan** resultado operativo, EBIT, intereses ni impuestos por periodo, patrimonio ni caja por periodo, precio objetivo de analistas, PER a futuro ni BPA estimado.
- **ADR (`type = dr`):** la moneda de reporte de las series es desconocida, así que el adapter no la declara (`reportedCurrency = null`). Una cotización local (`type = stock`) usa la del precio. La búsqueda pone primero la cotización de origen y los ADR detrás.
- **Errores:** HTTP 429 o 403 → `RateLimitException`; 5xx y fallos de conexión → `NetworkException`; sin fila en `data` o sin precio → `NotFoundException`; JSON que no es el esperado o un campo con otro tipo → `InvalidResponseException`. Nunca guardes en caché una respuesta de error.
- **Comprobado con respuestas reales (2026-10-06, fixtures en `app/test/fixtures/tradingview/`):** Nintendo (`TSE:7974`), Fast Retailing (`TSE:9983`), Iberdrola (`BME:IBE`) y Apple devuelven datos completos salvo lo listado arriba. Capturar fixtures nuevas: `app/tool/capture_tradingview_fixtures.sh`.

## Validación tras normalizar

Avisar (no fallar) si: último cierre > 5 días hábiles; último trimestre > 6 meses; capitalización difiere > 10 % de precio × acciones; divisa del informe distinta de la de cotización.

## Caché

Port de caché clave-valor con caducidad (`CachePort`), implementable en memoria (tests) o persistente en el dispositivo (app), y en un almacén compartido si algún día hay backend. Se guarda el JSON en crudo ya validado, nunca un error. Con TradingView todo viene en una sola petición, así que hay una sola caducidad: **6 horas** para búsquedas y datos (`tv:v1:search:<texto>`, `tv:v1:scan:<símbolo>`; subir la versión de la clave si cambia el formato guardado). Una entrada que ya no se puede interpretar se ignora y se vuelve a pedir.

## Arquitectura para la app

**Fase actual (uso personal, sin backend):**

```
App (presentation → use case → motor) → MarketDataPort → TradingViewAdapter → TradingView
                                         └── CachePort (persistente en el dispositivo)
```

- No hay clave de API. Si un proveedor futuro la necesita, se inyecta al compilar con `--dart-define-from-file` (archivo no versionado) y se lee con `String.fromEnvironment`; nunca en el código.
- La fuente actual no es oficial: solo es aceptable mientras la app no se publique.

**Antes de publicar la app, backend obligatorio:**

```
App → Backend propio (p. ej. GET /analisis/{ticker}) → Motor → Proveedor → API
              └── caché compartida + análisis guardados
```

- Las credenciales del proveedor pasan a variables de entorno del backend.
- En la app solo cambia el adapter: un `BackendAnalysisAdapter` sustituye al de TradingView. El motor es Dart puro (`domain/`) y un backend en Dart puede reutilizarlo tal cual.
- Caché compartida: el límite de peticiones se reparte entre todos los usuarios en vez de multiplicarse.
- Traducir errores: `rate_limit` → 503 con reintento; `not_found` → 404.
- Revisar términos de uso: muchos planes gratuitos prohíben uso comercial o mostrar datos a terceros.

## Proveedores alternativos

Ya probados y descartados: **Yahoo Finance y otras fuentes gratuitas no oficiales** (mala calidad) y **Alpha Vantage gratuito** (25 peticiones al día, y sin fundamentales de Tokio ni Madrid: `OVERVIEW` vacío para `7974`, `9983` e `IBE`; comprobado 2026-10-06). Alpha Vantage sigue siendo una opción para acciones de EE. UU.

| Proveedor | Fuerte en | Uso sugerido |
|---|---|---|
| Financial Modeling Prep | Fundamentales profundos, ratios, históricos largos | Producción, foco fundamental |
| Finnhub | Cobertura global, noticias, calendario de resultados | Complemento: fecha real de resultados |
| Massive (antes Polygon.io) | Precios de EE. UU. en tiempo real | Solo si hace falta tiempo real |
| Twelve Data / EODHD | Bolsas internacionales | Acciones europeas |

Para añadir uno: implementar la misma interfaz, mismas convenciones de normalización, tests con respuestas reales guardadas como fixtures, y comparar métricas clave con TradingView sobre la misma empresa (diferencias > 5 % suelen ser definiciones distintas, p. ej. qué cuenta como deuda).