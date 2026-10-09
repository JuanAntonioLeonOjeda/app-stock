# Plan: contenido_educativo

> Basado en `spec.md` (cerrada). Arquitectura en `.claude/rules/hexagonal-architecture.md`,
> estilo en `.claude/rules/code-style.md`, contenido en la skill `contenido-educativo`.
> Rutas relativas a `app/lib/features/contenido_educativo/` salvo que se indique otra cosa.

## Dependencias nuevas

Ninguna. Los textos se leen con `AssetBundle` de Flutter (solo en `infrastructure/`).
`app/pubspec.yaml` declara la carpeta `assets/contenido/`.

## Cómo se conecta con `analisis_accion`

La regla de dependencias prohíbe que una feature importe de otra. Se conectan en el
composition root (`app/lib/app.dart`) con **funciones que `analisis_accion` recibe sin saber
qué hay detrás**:

```dart
/// Abre la explicación del tema [topicId] (una métrica, un bloque o la guía).
typedef ShowInfo = void Function(BuildContext context, String topicId);
```

- `analisis_accion` define `ShowInfo` y se lo pasa de `AnalysisScreen` a `BlockTile` y a
  `MetricRow`. Si es `null`, no pinta ningún icono (así los widgets siguen valiendo sin
  contenido y los tests actuales no cambian).
- `HomeScreen` recibe además `VoidCallback? onOpenLearn` para el acceso "Aprender".
- `app.dart` implementa `ShowInfo` con las pantallas de `contenido_educativo`: la guía
  abre pantalla completa; métricas y bloques, una hoja inferior.

**Los ids de tema son un contrato de strings**, como ya lo son los ids de métricas:
`per`, `roic`... para métricas; `bloque_valoracion`, `bloque_salud`, `bloque_crecimiento`,
`bloque_tecnico`, `bloque_contexto` para bloques; `guia_diagnostico` para la guía.
`analisis_accion` traduce `Block` → id de tema en `presentation/formatters/labels.dart`.

## Elementos por capa

### domain/entities

| Archivo | Contenido |
|---|---|
| `metric_content.dart` | `MetricContent`: `id`, título, resumen, intuición, fórmula, ejemplo, cómo leerla, cuándo engaña, `combinesWith` (ids) y `CheckQuestion` |
| `check_question.dart` | `CheckQuestion`: texto, opciones, índice correcto y explicación |
| `block_content.dart` | `BlockContent`: `id`, título, resumen, qué pregunta responde, ids de sus métricas y cómo usarlo |
| `diagnosis_guide.dart` | `DiagnosisGuide`: secciones (título y texto) y la lista "Qué mirar antes de invertir" |
| `educational_content.dart` | `EducationalContent`: métricas por `id` (orden de bloque), bloques y guía; colecciones inmutables |

### domain/exceptions

| Archivo | Contenido |
|---|---|
| `educational_content_exception.dart` | `InvalidContentException`: el contenido no se ha podido leer o no cumple el formato |

### domain/content

Funciones puras.

| Archivo | Contenido |
|---|---|
| `glossary_search.dart` | `filterMetrics(List<MetricContent>, String query)`: por título o resumen, sin mayúsculas ni tildes (criterio 13) |

### domain/ports

| Archivo | Contenido |
|---|---|
| `educational_content_port.dart` | `EducationalContentPort`: `load()` → `EducationalContent`; lanza solo `InvalidContentException` |

### infrastructure/adapters

| Archivo | Contenido |
|---|---|
| `asset_educational_content_adapter.dart` | `AssetEducationalContentAdapter implements EducationalContentPort`: lee los 3 archivos con un `AssetBundle` inyectable, los traduce con el parser y guarda el resultado en memoria (se lee una vez) |
| `educational_content_parser.dart` | JSON → entidades. Valida campos obligatorios, tipos, pregunta (≥ 3 opciones, índice correcto válido) y `combinaCon` existentes; cualquier fallo → `InvalidContentException` con el campo |

Las claves del JSON van en español (`titulo`, `comoLeerla`...) porque son datos de
contenido, como pide la skill; el parser las convierte a campos en inglés.

### application/use_cases

| Archivo | Contenido |
|---|---|
| `load_educational_content_use_case.dart` | `LoadEducationalContentUseCase`: llama al port |
| `search_glossary_use_case.dart` | `SearchGlossaryUseCase`: dado el contenido y un texto, devuelve las métricas agrupadas por bloque (criterios 12-13) |

### presentation

| Archivo | Contenido |
|---|---|
| `controllers/topic_controller.dart` | `TopicController` (`ChangeNotifier`, lo usan la hoja y la pantalla de la guía): contenido cargado, error, pila de temas visitados, tema actual, opción elegida en la pregunta. Abrir otro tema vacía la respuesta; "atrás" vuelve al anterior (criterios 3 y 5) |
| `controllers/glossary_controller.dart` | `GlossaryController`: contenido, texto buscado y métricas filtradas por bloque |
| `screens/glossary_screen.dart` | Guía arriba, buscador y métricas por bloque (criterios 11-14) |
| `screens/diagnosis_guide_screen.dart` | La guía, con "Qué mirar antes de invertir" y el aviso educativo (criterios 8-10) |
| `widgets/topic_sheet.dart` | Hoja inferior de un tema: ficha de métrica o de bloque, con `showTopicSheet(...)` |
| `widgets/topic_section.dart` | Título y texto de una sección de ficha |
| `open_topic.dart` | `openEducationalTopic(...)`: la guía a pantalla completa y el resto en hoja |
| `widgets/metric_content_view.dart` | Las secciones de una ficha de métrica |
| `widgets/block_content_view.dart` | La ficha de un bloque |
| `widgets/example_box.dart` | El ejemplo, siempre rotulado "Ejemplo inventado" (criterio 4) |
| `widgets/check_question_card.dart` | La pregunta: opciones, respuesta y explicación sin puntuar (criterio 5) |
| `widgets/related_metrics.dart` | "Con qué se combina" como chips que cambian de tema (criterio 3) |
| `widgets/educational_notice.dart` | El aviso "Análisis con fin educativo. No es una recomendación de inversión." |

El aviso se repite con el mismo texto que `analisis_accion`: duplicar una constante de una
línea cuesta menos que crear una dependencia entre features, y no se mueve a `core/`
hasta que una segunda feature lo necesite de verdad (regla del proyecto).

### Composition root (`app/lib/app.dart`)

- Crea `AssetEducationalContentAdapter(bundle: rootBundle)` y los dos use cases.
- Implementa `ShowInfo`: `guia_diagnostico` → `Navigator.push(DiagnosisGuideScreen)`;
  cualquier otro id → `showTopicSheet(...)`.
- Pasa `showInfo` a `AnalysisScreen` y `onOpenLearn` (push de `GlossaryScreen`) a
  `HomeScreen`.

### Cambios en `analisis_accion`

| Archivo | Cambio |
|---|---|
| `presentation/widgets/show_info.dart` | `typedef ShowInfo` |
| `presentation/widgets/metric_row.dart` | Icono de información que llama `showInfo(context, metric.id)` si hay callback (criterios 1-2) |
| `presentation/widgets/block_tile.dart` | Icono en `leading` con el tema del bloque (criterio 7) |
| `presentation/screens/analysis_screen.dart` | Botón "¿Cómo leer este diagnóstico?" que abre `guia_diagnostico` (criterio 8) |
| `presentation/screens/home_screen.dart` | Acción "Aprender" en la barra (criterio 11) |
| `presentation/formatters/labels.dart` | `blockTopicId(Block)` |

## Contenido (`app/assets/contenido/`)

| Archivo | Entradas |
|---|---|
| `metricas.es.json` | 30 métricas, una por `id` del motor |
| `bloques.es.json` | 5 bloques |
| `guia.es.json` | La guía y la lista de preguntas |

Cómo se escribe (skill `contenido-educativo`): intuición con una analogía, fórmula en
palabras con el estado financiero de origen, ejemplo con cifras redondas inventadas
rotulado, "cómo leerla" **coherente con las escalas de `metric_rules.dart`** pero
presentada como orientación, "cuándo engaña" (lo más valioso), pregunta con explicación.
Cada bloque de métricas se redacta leyendo antes las escalas de las reglas de ese bloque.

## Decisiones técnicas no obvias

1. **Callbacks en el composition root, no un tercer paquete en `core/`.** Mover el
   contenido a `core/` solo para que dos features lo vean contradice "no mover nada a
   `core/` por adelantado". Con `ShowInfo`, `analisis_accion` no depende de nada nuevo.
2. **La guía a pantalla completa y el resto en hoja.** La guía tiene varias secciones y
   una lista larga; una ficha cabe en una hoja y el usuario sigue viendo el resultado.
3. **Contenido cargado una vez y guardado en memoria.** Son decenas de KB; no hace falta
   caché ni invalidación. Un fallo de lectura no se guarda: se vuelve a intentar al abrir
   otra vez.
4. **Validación al leer, no al pintar.** El parser rechaza una ficha incompleta con el
   nombre del campo, de modo que un error de contenido falla en el test del criterio 16
   y nunca llega a la pantalla a medias.
5. **Sin estado persistente.** La respuesta de la pregunta vive solo en el controller de la
   hoja y se descarta al cambiar de tema o cerrar (spec: sin progreso guardado).
6. **Búsqueda sin tildes con tabla propia.** Un mapa de 12 caracteres (`áéíóúüñ` y
   mayúsculas) evita añadir `diacritic` por una función de 10 líneas.
7. **Cobertura entre features en `app/test/`.** El test que compara los `id` del motor con
   las fichas importa de las dos features; vive fuera de ellas y no rompe el aislamiento.

## Tests

Siguiendo `.claude/rules/testing-conventions.md`, en `app/test/features/contenido_educativo/`:

| Qué | Cómo |
|---|---|
| `educational_content_parser` | JSON sintético válido, y un caso por cada validación (campo ausente, pregunta con 2 opciones, índice fuera de rango, `combinaCon` desconocido, tipo erróneo) |
| `asset_educational_content_adapter` | `AssetBundle` falso escrito a mano: lee los 3 archivos, guarda en memoria, error de lectura → `InvalidContentException` |
| `glossary_search` | Mayúsculas, tildes, sin resultados, texto vacío |
| Use cases | Fake del port en `application/fake_ports.dart` |
| Controllers | Pila de temas, atrás, respuesta que se borra al cambiar de tema, error de carga |
| Pantallas y widgets | Ficha completa, ejemplo rotulado, pregunta con explicación, glosario con buscador, guía con el aviso |
| `analisis_accion` | `MetricRow` y `BlockTile` con y sin `showInfo`; botón de la guía; acción "Aprender" |
| `app/test/contenido_coverage_test.dart` | Con el contenido real: una ficha por `id` de `metricRules` y ninguna de más (15), campos completos y `combinaCon` válidos (16), sin frases de recomendación (17), cada `Block` tiene su ficha de bloque |

## Cambios en la configuración asociados

- `.claude/rules/reglas-motor.md`: añadir "Si cambias un umbral o una escala, revisa el
  `comoLeerla` de esa métrica" (criterio 18). Ya dice que una métrica nueva necesita su
  ficha; ahora además hay un test que lo exige.
- `AGENTS.md`: filas de `plan.md` y `tasks.md` de esta feature.
- Skill `contenido-educativo`: ruta real de los archivos (`app/assets/contenido/`, tres
  archivos) y los ids de bloque y guía.

## Revisión: explicación desplegable en la propia fila (2026-10-06)

> Cambia los criterios 1, 2b, 3 y 7. Sustituye a la hoja inferior como forma principal de
> ver una métrica o un bloque en el resultado; la hoja se queda para el glosario y para los
> enlaces "Se combina con".

### Conexión entre features

`analisis_accion` define un segundo hueco, junto a `ShowInfo` (que sigue abriendo la guía):

```dart
/// Construye la explicación del tema [topicId] para mostrarla en el sitio.
typedef InfoBuilder = Widget Function(BuildContext context, String topicId);
```

`app.dart` lo implementa con el widget de `contenido_educativo`, que sale de `analisis_accion`
sin que esta lo importe.

### Cambios

| Dónde | Cambio |
|---|---|
| `analisis_accion/.../widgets/info_builder.dart` | `typedef InfoBuilder` |
| `analisis_accion/.../widgets/metric_row.dart` | Pasa a `StatefulWidget`: el icono muestra u oculta, bajo la fila, lo que devuelve `buildInfo(context, metric.id)` (`AnimatedSize`, empieza oculto) |
| `analisis_accion/.../widgets/block_tile.dart` | Pasa a `StatefulWidget`: el icono despliega el bloque y muestra arriba `buildInfo(context, blockTopicId)`; al volver a pulsarlo se oculta |
| `analisis_accion/.../screens/analysis_screen.dart` | Recibe `buildInfo` y se lo pasa a bloques y métricas; `showInfo` queda solo para la guía |
| `contenido_educativo/.../widgets/topic_inline_view.dart` | `TopicInlineView`: crea su `TopicController` al montarse, carga el contenido la primera vez que se despliega y muestra la ficha de métrica o de bloque (sin cabecera, volver ni aviso grande). Libera el controller al ocultarse |
| `contenido_educativo/.../widgets/metric_content_view.dart` y `block_content_view.dart` | Sin cambios: las reutiliza |
| `app.dart` | `buildInfo: (context, id) => TopicInlineView(...)` con `onOpenTopic` que abre la hoja |

### Decisiones

1. **La pregunta funciona dentro de la fila**: su estado vive en el `TopicController` del
   `TopicInlineView`; al ocultar la explicación se descarta (no se guarda nada).
2. **Se carga al desplegar, no antes**: el contenido se lee una vez (el adapter lo guarda en
   memoria) y las filas que nadie despliega no cuestan nada.
3. **Los chips "Se combina con" abren la hoja**: esa métrica puede estar en otro bloque
   plegado; navegar al sitio exigiría desplegar y desplazar otra parte de la lista.
4. **Sin cambios en la guía ni en el glosario**: no son la explicación de un dato concreto.

### Tests

`topic_inline_view_test` (carga al mostrarse, ficha de métrica y de bloque, error con
reintento, pregunta, chips); `metric_row_test`, `block_tile_test` y `analysis_screen_test`
(con y sin `buildInfo`; mostrar y ocultar; empieza oculto; cada fila por separado).

---

## Revisión: conceptos de la gráfica de precio (2026-10-08)

> Basada en los criterios 68-71 de `spec.md`.

### Cambios

| Dónde | Cambio |
|---|---|
| `assets/contenido/conceptos.es.json` | Tres explicaciones, con la estructura de una métrica: `media_50`, `media_200` y `grafico_precio` |
| `domain/entities/educational_content.dart` | `concepts` (lista de `MetricContent`) y `explanationById(id)`, que busca en métricas y en conceptos; `metricById` solo en métricas |
| `infrastructure/adapters/educational_content_parser.dart` | Lee `conceptos.es.json`; los `combinaCon` de métricas y de conceptos pueden apuntar a ambos; un `id` de concepto no puede coincidir con el de una métrica |
| `infrastructure/adapters/asset_educational_content_adapter.dart` | Lee el cuarto archivo |
| `presentation/` | `TopicController`, la hoja y la vista en línea resuelven el tema con `explanationById`, así que un concepto se ve igual que una métrica |

### Decisiones

1. **Conceptos separados de las métricas**: el test "una ficha por cada métrica del motor y
   ninguna de más" sigue valiendo tal cual, y los conceptos tienen su propia comprobación.
2. **Los ids son un contrato de strings**, como los de bloque: `analisis_accion` los define
   (`labels.dart`) y el test de `app/test/` comprueba que existen en el contenido.

