---
description: Convención de nombres para archivos, clases, variables, funciones e ids de métricas en este proyecto Flutter/Dart.
---

# Convención de nombres

El idioma de los identificadores (inglés, salvo los ids de métricas) está definido en
`code-style.md`.

## Archivos

- Siempre `snake_case.dart`, aunque la clase que contenga sea `PascalCase`. Ej.:
  `analysis_screen.dart`, `tradingview_adapter.dart`.
- El nombre del archivo describe su contenido principal, no su tipo genérico:
  `stock_data.dart`, no `models.dart`.
- Un archivo, una responsabilidad principal. Si un archivo empieza a acumular clases no
  relacionadas, toca dividirlo, no buscar un nombre que las abarque todas.

## Clases y tipos

- `PascalCase` para clases, enums, typedefs y extensiones: `StockData`, `AnalysisResult`.
- El sufijo indica el rol, no es decorativo: `...Screen` para pantallas completas,
  `...Sheet` para bottom sheets, `...Controller` para el estado de una pantalla, y
  `...Port`, `...Adapter` y `...UseCase` según `hexagonal-architecture.md`. No inventar
  sufijos nuevos sin una necesidad real.

## Variables, funciones y parámetros

- `camelCase` para variables, funciones y parámetros con nombre.
- Las constantes también van en `camelCase` (Effective Dart), no en
  `SCREAMING_SNAKE_CASE`.
- Privado: prefijo `_` para todo lo que no deba usarse fuera del archivo. Es la opción por
  defecto; lo público es la excepción.
- Booleanos como pregunta afirmativa: `isLoading`, `isStale`, no `loading`.

## Magnitudes en el nombre

El motor mezcla fracciones, precios, ratios y periodos (ver skill `motor-analisis`). Si una
variable puede ser ambigua, el nombre dice qué contiene:

- Los porcentajes se guardan siempre como fracción (0,025 = 2,5 %). Solo la capa de
  presentación los multiplica por 100, en un único punto de formateo.
- Los periodos llevan la unidad: `sessions63`, `years3`, `ttm`.
- Los importes llevan la divisa cuando pueda haber varias.

## Ids de métricas

Son estables, en `snake_case` y en español (`per`, `roic`, `deuda_ebitda`...). Enlazan el
motor, `references/metricas.md` y el contenido educativo: no se renombran.

## Widgets

- Un widget que solo compone otros widgets, sin lógica propia, puede quedarse como método
  privado (`_buildHeader()`) mientras sea pequeño. En cuanto tenga estado propio o se
  reutilice en más de una pantalla, pasa a ser su propia clase en `presentation/widgets/`
  (o en `app/lib/core/` si lo usa más de una feature).
