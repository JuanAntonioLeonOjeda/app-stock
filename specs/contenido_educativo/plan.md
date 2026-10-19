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


---

## Revisión 2: fichas visuales y actividades (spec, criterios 72-90)

### Dependencias nuevas

Ninguna. Las ilustraciones y la barra de tramos se dibujan con `CustomPainter`; el
recorrido usa `PageView` y la actividad de ordenar, `ReorderableListView`, todo de
Flutter.

### La barra de tramos sale del motor (criterios 77-78)

`contenido_educativo` no puede importar el motor, así que pide la escala a un port:

```dart
/// Escala con la que el motor puntúa una métrica, para dibujarla en su ficha.
abstract interface class MetricScalePort {
  /// `null` si la métrica no tiene escala por tramos (MACD) o no existe.
  ReadingScale? scaleFor(String metricId);
}
```

- `ReadingScale` (entidad de `contenido_educativo`): puntos `(valor, nota)` en el
  mismo orden que el motor, más la unidad (`ScaleUnit`: múltiplo, fracción o decimal).
- **El adapter vive fuera de las dos features**, en
  `app/lib/composition/motor_metric_scale_adapter.dart`: es el único sitio, aparte de
  `app.dart`, que importa de ambas (lee `metricRules` y traduce `ScaleScoring` y
  `MetricFormat`). Se saca de `app.dart` para poder testearlo
  (`app/test/composition/`), igual que el test de cobertura ya vive en `app/test/`.
- `domain/content/scale_bands.dart` (puro) convierte los puntos en tramos de color: nota
  ≥ 7 alta, de 4 a 7 media y < 4 baja. Las fronteras se interpolan donde la escala
  lineal cruza 7 y 4. Así la barra no copia ningún umbral (criterio 78).

### Formato del contenido

Se mantiene `metricas.es.json` / `conceptos.es.json`, una entrada por `id`. Cambios
por ficha (la skill `contenido-educativo` se actualiza con este formato). La ilustración
no va en el JSON: se busca por `id` en presentación.

| Campo | Cambio |
|---|---|
| `formulaVisual` | **Nuevo.** `tipo`: `cociente` (numerador ÷ denominador), `crecimiento` (valor inicial → final en N años), `variacion` (actual ÷ referencia − 1, para precio frente a su media o al máximo) o `pasos` (2-4 pasos con flecha, para RSI, MACD o medias). Cada pieza: `nombre`, `origen` (`mercado`, `cuenta_resultados`, `balance`, `flujo_caja`, `historico_precios`), `ejemplo` y, si es movible, `min`/`max` y, si procede, `paso` (salto del deslizador, p. ej. 1 para años enteros). `resultado`: `nombre`, `unidad` y `ejemplo` |
| `ejemplo` | Pasa a ser una frase de contexto («Una tienda de muebles inventada…»); las cifras salen de `formulaVisual`, así el ejemplo y el simulador no pueden contradecirse (criterio 87) |
| `comoLeerla` | ≤ 60 palabras (criterio 74) |
| `cuandoEngana` | Pasa de texto a lista de 1-3 trampas, ≤ 60 palabras cada una: una tarjeta por trampa |
| `leyenda` | **Nuevo, obligatorio solo sin escala de motor** (MACD y conceptos): 2-4 filas `{condicion, significado, tono}` con `tono` ∈ `positivo`/`neutro`/`negativo` (criterio 79) |
| `actividades` | **Nuevo.** Lista de ≥ 1 (criterio 80), ver tipos abajo |
| `pregunta` | Sin cambios: va en el último paso |

Tipos de actividad (`tipo`):

- `simulador`: `enunciado`. Usa las piezas movibles de `formulaVisual`; solo es válido
  con `cociente` o `crecimiento`.
- `trampa`: `empresa`, `datos: [{etiqueta, valor, esTrampa, explicacion}]` (4-6, una
  sola trampa).
- `comparar`: `sector`, `empresas: [nombreA, nombreB]`, `filas: [{etiqueta, a, b}]`
  (4-5), `pregunta: {texto, correcta: 0|1, explicacion}`.
- `predecir`: `texto`, `opciones`, `correcta`, `explicacion` y `revelacion` (el dato
  que confirma la respuesta, mostrado después).
- `ordenar`: `enunciado`, `elementos: [{nombre, valor}]` (3-5) y `explicacion`; el orden
  correcto es de menor a mayor `valor`, y la app los baraja con una semilla fija por
  `id` para que no salgan ya ordenados ni cambie entre aperturas.

### Elementos por capa

#### domain/entities

| Archivo | Cambio |
|---|---|
| `metric_content.dart` | `MetricContent` añade `formulaDiagram`, `legend` (nullable), `activities`; `whenItMisleads` pasa a `List<String>` |
| `formula_diagram.dart` | `sealed class FormulaDiagram` → `RatioFormula`, `GrowthFormula`, `StepsFormula`; `FormulaPiece` y `DataSource` |
| `learning_activity.dart` | `sealed class LearningActivity` → `SimulatorActivity`, `SpotTrapActivity`, `CompareActivity`, `PredictActivity`, `OrderActivity` |
| `reading_scale.dart` | `ReadingScale`, `ScalePoint`, `ScaleUnit`, y `ScaleBand` (desde/hasta, tono) |
| `reading_legend.dart` | `LegendRow` y `Tone` |

#### domain/content (funciones puras)

| Archivo | Contenido |
|---|---|
| `formula_evaluation.dart` | `evaluateFormula(FormulaDiagram, Map<String, double>)`: valor o `null` (denominador 0, `pasos`) |
| `scale_bands.dart` | `bandsFor(ReadingScale)` y `bandOf(ReadingScale, double)` |
| `activity_grading.dart` | Corrección de `trampa`, `comparar`, `predecir` y `ordenar`, y `shuffledOrder(id, n)` determinista |

#### domain/ports

`metric_scale_port.dart`: `MetricScalePort` (arriba).

#### application/use_cases

`get_metric_scale_use_case.dart`: `GetMetricScaleUseCase(MetricScalePort)`. Doc comment
obligatorio.

#### infrastructure/adapters

`educational_content_parser.dart` lee los campos nuevos y rechaza, indicando archivo e
`id`: `formulaVisual` incoherente (rangos `min < ejemplo < max`, simulador sobre
`pasos`), actividades mal formadas (índices fuera de rango, ninguna o varias trampas,
menos elementos de los exigidos) y `leyenda` vacía.

#### presentation

| Archivo | Contenido |
|---|---|
| `controllers/lesson_controller.dart` | Un controller para el recorrido (criterios 72-73, 85, 90): carga, paso actual, pila de temas para volver, valores del simulador y respuesta de cada actividad. Se descarta al cerrar (no se guarda nada) |
| `screens/metric_lesson_screen.dart` | Recorrido a pantalla completa: `PageView`, indicador de pasos que permite saltar, «Anterior»/«Siguiente» |
| `lesson_steps.dart` | `lessonStepsFor(MetricContent)`: lista de pasos en orden (idea, fórmula, cómo leerla, una por trampa, una por actividad, pregunta) |
| `widgets/metric_quick_view.dart` | Versión corta de la fila (criterio 89): resumen, barra o leyenda y botón «Aprender paso a paso». `TopicInlineView` la usa para métricas y conceptos; los bloques no cambian |
| `widgets/scale_bar.dart` | Barra de tramos con fronteras y un marcador opcional (el del simulador) |
| `widgets/formula_diagram_view.dart` | Fórmula por piezas con su origen y el ejemplo resuelto (criterio 76) |
| `widgets/reading_legend_view.dart` | Leyenda por tono (criterio 79) |
| `widgets/activities/*.dart` | Un widget por tipo de actividad; solo pintan y reenvían al controller |
| `illustrations/illustration_for.dart` | `Widget? illustrationFor(String id)` |
| `illustrations/<bloque>_illustrations.dart` | Los `CustomPainter` de cada bloque (valoración, salud, crecimiento, técnico, contexto y gráfica), con colores del `ColorScheme` |

`MetricContentView` y la hoja de métricas desaparecen: los sustituyen el recorrido y la
versión corta. `openEducationalTopic` abre las métricas y los conceptos en
`MetricLessonScreen`; los bloques siguen en hoja y la guía, en su pantalla. El glosario
ya llama a `openTopic`, así que no cambia.

### Cableado (`app/lib/app.dart`)

Construye `MotorMetricScaleAdapter` → `GetMetricScaleUseCase` y lo pasa a
`openEducationalTopic` y a `TopicInlineView`. `analisis_accion` no cambia: sigue
recibiendo `showInfo` y `buildInfo`.

### Tests

- `domain/content`: evaluación de fórmulas (cociente, crecimiento, denominador 0),
  tramos (escala creciente y decreciente, fronteras interpoladas) y corrección de cada
  actividad, más el barajado determinista.
- Parser: cada campo nuevo, y un error con archivo e `id` por cada regla de validación.
- `app/test/composition/motor_metric_scale_adapter_test.dart`: la escala del PER coincide
  con `metricRules`; MACD devuelve `null`.
- `LessonController`: avanzar, saltar, volver a un tema anterior, responder y repetir.
- Widgets: recorrido (pasos e indicador), versión corta con su botón y una prueba por
  tipo de actividad.
- `app/test/contenido_coverage_test.dart` amplía: ≤ 60 palabras por tarjeta (criterio
  74), ilustración para cada `id` (75), leyenda si y solo si el motor no da escala (79),
  los cuatro tipos de actividad presentes (80), simulador = `resultado.ejemplo` (87) y
  las reglas de textos sobre las actividades (88).

### Riesgos

- **El contenido es la mayor parte del trabajo**: reescribir 33 fichas con fórmula,
  trampas y actividades, y dibujar 33 ilustraciones. Se hace por bloques (tasks
  T47-T52) y el usuario revisa cada bloque antes de seguir con el siguiente.
- La fórmula de algunas métricas no cabe en `cociente`/`crecimiento` (RSI, MACD,
  pendiente de la SMA200, sorpresas de BPA): van con `pasos` y sin simulador; su
  actividad será otra.
