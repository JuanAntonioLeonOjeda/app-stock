---
description: Arquitectura hexagonal (ports & adapters) — cómo se organiza cada feature de app/lib/features/ en domain/application/infrastructure/presentation y la regla de dependencia entre capas.
---

# Arquitectura hexagonal (ports & adapters)

Cada feature en `app/lib/features/<nombre>/` sigue la misma estructura de 4 capas. Ejemplo
con la feature que contiene el motor:

```
app/lib/features/analisis_accion/
  domain/
    entities/        # StockData, AnalysisResult (contratos de la skill motor-analisis)
    motor/           # cálculo, reglas y puntuación: funciones puras
    ports/           # MarketDataPort, CachePort
  application/
    use_cases/       # AnalyzeStockUseCase, SearchSymbolUseCase
  infrastructure/
    adapters/        # TradingViewAdapter, caché en memoria / local
  presentation/
    controllers/     # ChangeNotifier por pantalla (ver code-style.md)
    screens/
    widgets/
```

## La regla de dependencia (la que de verdad importa)

**Las dependencias siempre apuntan hacia dentro, nunca hacia fuera:**

```
presentation → application → domain ← infrastructure
```

- **`domain/`** no depende de nada: ni de Flutter, ni de `http`, ni de ningún paquete
  externo. Solo Dart puro. Un `import 'package:flutter/...'` o
  `import 'package:http/...'` dentro de `domain/` viola la arquitectura y es un hallazgo
  de alta prioridad para `flutter-reviewer`. Gracias a esto el motor se puede ejecutar
  también fuera de la app (tests, script de línea de comandos o un futuro backend en Dart).
- **`domain/ports/`** define interfaces abstractas: qué necesita el dominio, no cómo se
  consigue. Ej.: el motor necesita "una forma de obtener `StockData` para un símbolo". Eso
  es un port; TradingView no lo es.
- **`infrastructure/adapters/`** implementa esos ports con los paquetes reales (`http`,
  almacenamiento local). Es la única capa que puede importar paquetes con I/O o de
  plataforma.
- **`application/use_cases/`** orquesta: recibe los ports inyectados (nunca instancia un
  adapter directamente), llama al dominio y decide el flujo.
- **`presentation/`** (controllers, pantallas y widgets) llama a use cases, nunca a
  adapters ni a paquetes externos directamente.

## Naming

- Port: sufijo `Port`, siempre `abstract interface class`. Ej.: `MarketDataPort`,
  `CachePort`.
- Adapter: sufijo `Adapter`, implementa un port. Ej.:
  `TradingViewAdapter implements MarketDataPort`.
- Use case: sufijo `UseCase` y un verbo de negocio. Ej.: `AnalyzeStockUseCase`, no
  `StockService` (ese nombre genérico es justo lo que esta arquitectura reemplaza).
- Entity: sin sufijo. Ej.: `StockData`, `AnalysisResult`.

## Inyección de dependencias

De momento no hay librería de DI (`get_it`, `riverpod`, etc.). Los adapters concretos se
construyen en un composition root (`app/lib/app.dart`) y se pasan por constructor al use
case; los use cases, a su vez, se pasan al controller de la pantalla. Si el número de
dependencias crece y esto se vuelve incómodo, se valora añadir `get_it`, pero no antes.

## Código que conecta dos features: `app/lib/composition/`

Una feature nunca importa de otra. Cuando una necesita algo que solo sabe la otra, lo
pide con un port propio y el adapter que lo implementa vive en `app/lib/composition/`,
la única carpeta (junto con `app/lib/app.dart`) que puede importar de varias features. Ej.:
`contenido_educativo` define `MetricScalePort` para dibujar la escala de una métrica, y
`MotorMetricScaleAdapter` lee las escalas reales de `analisis_accion`. Sus tests viven en
`app/test/composition/`. No es un cajón de sastre: solo adapters que unen features.

## Dónde va cada cosa

| Concepto | Capa |
|---|---|
| `StockData`, `AnalysisResult` | `domain/entities/` |
| Indicadores, ratios, reglas, puntuación y veredicto | `domain/motor/` (puro, sin I/O ni reloj) |
| Jerarquía de excepciones (`MarketDataException`...) | `domain/` |
| Interfaces "obtener datos de mercado" y "caché" | `domain/ports/` |
| Cliente de TradingView, parser JSON, normalización y caché | `infrastructure/adapters/` |
| Orquestar "proveedor → motor → historial" | `application/use_cases/` |
| Estado de la pantalla | `presentation/controllers/` |
| Pantallas y widgets | `presentation/screens/`, `presentation/widgets/` |

## Cuándo NO aplicar esto al pie de la letra

En `app/lib/core/` (tema visual, widgets base compartidos) esta separación no aplica: es
código transversal simple, no una feature con lógica de negocio propia.
