---
name: datos-mercado
description: Cómo obtener datos bursátiles de forma programática para el motor de análisis: elección de API, endpoints necesarios, particularidades de las respuestas, normalización a StockData, caché, límites de peticiones, errores, gestión de la clave y paso futuro a un backend propio. Úsala SIEMPRE que la tarea implique llamar a una API financiera, buscar un ticker, parsear respuestas, faltan datos en un análisis, falla una petición, se quiere cambiar de proveedor o se plantea añadir un backend.
---

# Datos de mercado

## Cómo se consultan los datos

Los datos se piden con **peticiones HTTP directas a la API REST del proveedor, escritas como código del proyecto** (cliente HTTP dentro del adapter del proveedor, en `infrastructure/adapters/`). No uses servidores MCP, conectores ni ninguna herramienta de IA para esto: el análisis debe funcionar sin Claude en ejecución, de forma reproducible y testeable.

Aunque en tu sesión de desarrollo tengas herramientas MCP de datos financieros disponibles, no las uses para implementar la funcionalidad. Como mucho, sirven para inspeccionar a mano una respuesta real y guardarla como fixture de test.

Origen de cada dato:

| Origen | Métricas |
|---|---|
| Vienen ya calculadas en `OVERVIEW` | PER, PER adelantado, PEG, P/VC, P/Ventas, EV/EBITDA, beta, rentabilidad por dividendo, precio objetivo de analistas, medias 50/200 y máx./mín. 52 semanas (estas últimas solo como respaldo) |
| Las calcula el código a partir del histórico (`TIME_SERIES_DAILY`) | SMA, RSI, MACD, pendiente de la media, rentabilidades, volatilidad, caída máxima, distancia al máximo |
| Las calcula el código a partir de los estados financieros | ROIC, ROE, deuda neta/EBITDA, deuda/patrimonio, liquidez, cobertura de intereses, márgenes, crecimiento (CAGR), FCF, precio/FCF, dilución, dividendo/FCF |
| Las calcula el código a partir de `EARNINGS` | Trimestres que baten estimaciones |

Regla práctica: si el proveedor da el ratio ya calculado y su definición es fiable, úsalo; si no, calcúlalo tú para controlar la fórmula y poder testearla.

## Interfaz de proveedor

Todo acceso a datos pasa por un único port, `MarketDataPort`, con dos operaciones:
- `searchSymbol(query)` → lista de coincidencias (símbolo, nombre, región, divisa, puntuación).
- `fetchStockData(symbol)` → `StockData` normalizado (contrato en la skill `motor-analisis`).

Errores tipados como excepciones de `domain/` (ver `.claude/rules/code-style.md`): `RateLimitException`, `NotFoundException`, `InvalidResponseException`, `NetworkException`. Cambiar de proveedor no debe tocar nada fuera de su adapter.

## Proveedor inicial: Alpha Vantage

Elegido por ofrecer fundamentales, precios y resultados en una sola API con plan gratuito. Límite diario del plan gratuito muy bajo (unas 25 peticiones; verificar el actual en su web). Límites y precios cambian: confirma siempre en la documentación oficial.

Endpoints para un análisis (6 peticiones sin caché):

| Endpoint | Aporta |
|---|---|
| `OVERVIEW` | Perfil y ratios: sector, capitalización, PER, PEG, P/VC, P/Ventas, EV/EBITDA, beta, dividendo, precio objetivo, medias 50/200, máx./mín. 52 semanas |
| `TIME_SERIES_DAILY` | Histórico diario |
| `INCOME_STATEMENT` | Cuenta de resultados anual y trimestral |
| `BALANCE_SHEET` | Balance anual y trimestral |
| `CASH_FLOW` | Flujo de caja anual y trimestral |
| `EARNINGS` | BPA real vs estimado y fecha de publicación |
| `SYMBOL_SEARCH` | Solo para resolver un nombre a ticker |

No pidas cotización aparte: el último cierre del histórico basta. Haz las peticiones en secuencia con una pausa configurable (el plan gratuito también limita por minuto).

## Particularidades (causa habitual de bugs)

- **Errores con HTTP 200.** Los errores llegan en el cuerpo JSON en campos `Error Message`, `Note` o `Information`. Detecta el límite de peticiones por el texto y conviértelo en `RateLimitException`. Nunca guardes en caché una respuesta de error.
- **Números como texto** y `"None"`, `"-"` o vacío para ausentes → convertir a `null`.
- **Signos:** CAPEX, dividendos y recompras pueden venir negativos o positivos según el campo → normalizar a positivo.
- **Deuda total:** usar `shortLongTermDebtTotal`; si falta, sumar `shortTermDebt` + `longTermDebt`.
- **Caja:** `cashAndShortTermInvestments`, o `cashAndCashEquivalentsAtCarryingValue` si falta.
- **Gastos financieros:** normalizar a positivo.
- **Histórico completo** (`outputsize=full`) puede ser función de pago. Si la respuesta indica que es premium, reintenta con `compact` (~100 sesiones) y **recuerda en caché** que el plan no lo permite, para no gastar una petición en cada análisis. El motor usará las medias precalculadas del `OVERVIEW` como respaldo.
- **Orden:** el histórico viene como objeto por fechas → ordenar ascendente. Los informes financieros → ordenar del más reciente al más antiguo.
- **Tickers no estadounidenses** llevan sufijo de bolsa; resolverlos con `SYMBOL_SEARCH`. La cobertura de fundamentales fuera de EE. UU. es limitada: marcar datos faltantes, no inventarlos.

## Validación tras normalizar

Avisar (no fallar) si: último cierre > 5 días hábiles; último trimestre > 6 meses; capitalización difiere > 10 % de precio × acciones; divisa del informe distinta de la de cotización.

## Caché

Port de caché clave-valor con caducidad (`CachePort`), implementable en memoria (tests) o persistente en el dispositivo (app), y en un almacén compartido si algún día hay backend. Con el límite diario del plan gratuito, la caché persistente es imprescindible. Caducidades orientativas:
- Histórico diario: 6 horas.
- Perfil: 24 horas.
- Estados financieros y resultados: 7 días.
- Búsqueda de símbolos: 30 días.
- Resultado final del análisis: unas horas.

## Arquitectura para la app

**Fase actual (uso personal, sin backend):**

```
App (presentation → use case → motor) → MarketDataPort → AlphaVantageAdapter → API
                                         └── CachePort (persistente en el dispositivo)
```

- La clave se inyecta al compilar con `--dart-define-from-file=config/secrets.json` (no versionado) y se lee con `String.fromEnvironment`. Nunca en el código.
- Una clave compilada en la app **se puede extraer del binario**: solo es aceptable mientras la app no se publique.

**Antes de publicar la app, backend obligatorio:**

```
App → Backend propio (p. ej. GET /analisis/{ticker}) → Motor → Proveedor → API
              └── caché compartida + análisis guardados
```

- La app deja de contener la clave; esta pasa a variables de entorno del backend.
- En la app solo cambia el adapter: un `BackendAnalysisAdapter` sustituye al de Alpha Vantage. El motor es Dart puro (`domain/`) y un backend en Dart puede reutilizarlo tal cual.
- Caché compartida: el límite de peticiones se reparte entre todos los usuarios en vez de multiplicarse.
- Traducir errores: `rate_limit` → 503 con reintento; `not_found` → 404.
- Revisar términos de uso: muchos planes gratuitos prohíben uso comercial o mostrar datos a terceros.

## Proveedores alternativos

| Proveedor | Fuerte en | Uso sugerido |
|---|---|---|
| Financial Modeling Prep | Fundamentales profundos, ratios, históricos largos | Producción, foco fundamental |
| Finnhub | Cobertura global, noticias, calendario de resultados | Complemento: fecha real de resultados |
| Massive (antes Polygon.io) | Precios de EE. UU. en tiempo real | Solo si hace falta tiempo real |
| Twelve Data / EODHD | Bolsas internacionales | Acciones europeas |

Para añadir uno: implementar la misma interfaz, mismas convenciones de normalización, tests con respuestas reales guardadas como fixtures, y comparar métricas clave con Alpha Vantage sobre la misma empresa (diferencias > 5 % suelen ser definiciones distintas, p. ej. qué cuenta como deuda).