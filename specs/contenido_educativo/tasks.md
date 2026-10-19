# Tasks: contenido_educativo

> Derivadas de `plan.md`. Marcar cada una al completarla.
>
> **Cada tarea con comportamiento incluye su archivo de test** (`app/test/` refleja
> `app/lib/`); las entidades que solo guardan datos no llevan test. Ninguna tarea se da por
> terminada hasta que `flutter analyze` no da avisos y `flutter test` pasa. Rutas relativas
> a `app/lib/features/contenido_educativo/` salvo que se indique otra cosa.

## Setup

- [x] T01. Declarar `assets/contenido/` en `app/pubspec.yaml` y crear la carpeta con los 3
      archivos vacíos (`metricas.es.json`, `bloques.es.json`, `guia.es.json`).
- [x] T02. Estructura de carpetas de la feature (se crea con el primer archivo de cada una).

## Domain

- [x] T03. `domain/entities/`: `check_question.dart`, `metric_content.dart`,
      `block_content.dart`, `diagnosis_guide.dart` y `educational_content.dart`
      (colecciones inmutables).
- [x] T04. `domain/exceptions/educational_content_exception.dart`.
- [x] T05. `domain/content/glossary_search.dart` + test (mayúsculas, tildes, sin resultados,
      texto vacío).
- [x] T06. `domain/ports/educational_content_port.dart` (con doc comment).

## Infrastructure

- [x] T07. `infrastructure/adapters/educational_content_parser.dart` + test con JSON
      sintético: caso válido y un caso por cada validación del plan.
- [x] T08. `infrastructure/adapters/asset_educational_content_adapter.dart` + test con un
      `AssetBundle` falso (lee los 3 archivos, memoria, error de lectura).

## Application

- [x] T09. `application/use_cases/load_educational_content_use_case.dart` y
      `search_glossary_use_case.dart` + tests, y `fake_ports.dart` de la feature.

## Contenido

> Cada tarea: leer antes las escalas de ese bloque en `metric_rules.dart`, escribir las
> fichas con la estructura de la skill, revisar que el "cómo leerla" cuadra con las
> escalas y que ningún texto parece una recomendación. **El usuario revisa el contenido.**

- [x] T10. Valoración (6): `per`, `peg`, `ev_ebitda`, `p_fcf`, `p_ventas`, `p_vc`.
- [x] T11. Salud financiera (6): `deuda_ebitda`, `deuda_patrimonio`, `liquidez`,
      `cobertura_intereses`, `fcf_positivo`, `payout_fcf`.
- [x] T12. Crecimiento y rentabilidad (9): `ingresos_cagr3`, `ingresos_yoy`,
      `beneficio_cagr3`, `margen_operativo`, `margen_tendencia`, `margen_bruto`, `roic`,
      `roe`, `dilucion`.
- [x] T13. Técnico (5): `precio_sma200`, `pendiente_sma200`, `rsi`, `macd`, `dist_maximo`.
- [x] T14. Contexto (4): `sorpresas_bpa`, `potencial_analistas`, `beta`, `caida_maxima`.
- [x] T15. Los 5 bloques (`bloques.es.json`), incluyendo que el técnico no sirve para
      adivinar el momento.
- [x] T16. La guía del diagnóstico y "Qué mirar antes de invertir" (`guia.es.json`).
- [x] T17. `app/test/contenido_coverage_test.dart`: criterios 15, 16 y 17 con el contenido
      real, y una ficha de bloque por cada `Block`.

## Presentation

- [x] T18. `presentation/controllers/topic_sheet_controller.dart` + test (pila, atrás,
      respuesta que se borra al cambiar de tema, error de carga).
- [x] T19. `presentation/controllers/glossary_controller.dart` + test.
- [x] T20. Widgets: `educational_notice.dart`, `example_box.dart`,
      `check_question_card.dart`, `related_metrics.dart`, `metric_content_view.dart`,
      `block_content_view.dart` + tests de los que tienen lógica (pregunta, ejemplo).
- [x] T21. `presentation/widgets/topic_sheet.dart` con `showTopicSheet(...)` + test.
- [x] T22. `presentation/screens/glossary_screen.dart` + test (grupos por bloque, buscador).
- [x] T23. `presentation/screens/diagnosis_guide_screen.dart` + test (secciones, lista y
      aviso).

## Integración en `analisis_accion`

- [x] T24. `typedef ShowInfo` y `blockTopicId(Block)` en `labels.dart` + test.
- [x] T25. Icono de información en `MetricRow` y `BlockTile` (solo si hay `showInfo`) +
      tests con y sin callback.
- [x] T26. Botón "¿Cómo leer este diagnóstico?" en `AnalysisScreen` y acción "Aprender" en
      `HomeScreen` + tests.
- [x] T27. Composition root en `app/lib/app.dart`: adapter, use cases, `showInfo` y
      `onOpenLearn`.

## Documentación

- [x] T28. `reglas-motor.md` (revisar `comoLeerla` al cambiar un umbral), `AGENTS.md` y la
      skill `contenido-educativo` (rutas y ids de tema).

## Verificación

- [x] T29. `dart format`, `flutter analyze` y `flutter test` limpios.
- [ ] T30. En dispositivo: abrir una ficha desde el resultado, navegar por "con qué se
      combina", responder una pregunta, abrir la guía y el glosario sin conexión.
- [ ] T31. Revisión de contenido por el usuario (T10-T16): que el "cómo leerla" cuadra con
      cómo piensa la métrica y que el tono ayuda a aprender.

## Revisión

- [x] T32. `flutter-reviewer` (con atención a que ninguna feature importe de la otra).

## Revisión: explicación desplegable en la propia fila

- [x] T33. `typedef InfoBuilder` y `TopicInlineView` en `contenido_educativo` + tests.
- [x] T34. `MetricRow` y `BlockTile` desplegables con `buildInfo`, y `AnalysisScreen` + tests
      (empieza oculto, mostrar/ocultar, cada fila por separado, sin `buildInfo`).
- [x] T35. Cableado en `app.dart`; `dart format`, `flutter analyze` y `flutter test` limpios.
- [ ] T36. Probar en el móvil que la explicación se despliega bien en la lista.

## Revisión: conceptos de la gráfica de precio

- [x] T37. `conceptos.es.json` con `media_50`, `media_200` y `grafico_precio`.
- [x] T38. Parser, entidad `concepts`/`explanationById`, adapter y vistas resuelven conceptos + tests.
- [x] T39. Test de cobertura en `app/test/`: los conceptos que referencia `analisis_accion` existen,
      sin frases de recomendación ni empresas reales.


## Revisión 2: fichas visuales y actividades

### Domain

- [x] T40. Entidades: `FormulaDiagram`, `LearningActivity`, `ReadingScale`/`ScaleBand`,
      `LegendRow`; `MetricContent` con los campos nuevos.
- [x] T41. `formula_evaluation.dart`, `scale_bands.dart` y `activity_grading.dart` + tests.
- [x] T42. `MetricScalePort` y `GetMetricScaleUseCase` + test con fake.

### Infrastructure

- [x] T43. Parser de los campos nuevos y sus validaciones + tests (las fichas actuales se
      migran en T47-T52; hasta entonces los campos nuevos son opcionales en el parser y T53 los exige en el
      contenido real).
- [x] T44. `MotorMetricScaleAdapter` en `app/lib/composition/` + test.

### Presentation

- [x] T45. `ScaleBar`, `FormulaDiagramView`, `ReadingLegendView`, `MetricQuickView` e
      `illustrationFor` (el enganche, con el registro vacío: cada bloque añade las suyas en
      T47-T52) + tests.
- [x] T46. `LessonController`, `lessonStepsFor`, `MetricLessonScreen` y los cinco widgets
      de actividad; `openEducationalTopic` y `TopicInlineView` usan lo nuevo; cableado en
      `app.dart` + tests.

### Contenido (por bloques; revisión del usuario al final de cada uno)

- [x] T47. Valoración (6): JSON nuevo e ilustraciones. Pendiente de tu revisión (T31).
- [x] T48. Salud financiera (6): JSON nuevo, ilustraciones y `paso` en las piezas movibles
      (para que un deslizador de años avance de 1 en 1). Pendiente de tu revisión (T31).
- [x] T49. Crecimiento y rentabilidad (9). Pendiente de tu revisión (T31).
- [ ] T50. Técnico (5), incluida la leyenda de MACD.
- [ ] T51. Contexto (4).
- [ ] T52. Conceptos de la gráfica (3), con leyenda.
- [ ] T53. Test de cobertura ampliado (criterios 74, 75, 79, 80, 86-88); borrar
      `MetricContentView`.

### Cierre

- [ ] T54. Skill `contenido-educativo` y `AGENTS.md` con el formato nuevo.
- [ ] T55. `dart format`, `flutter analyze` y `flutter test` limpios.
- [ ] T56. `flutter-reviewer` (atención a `app/lib/composition/` y a que ninguna feature
      importe de la otra).
- [ ] T57. En dispositivo: recorrido, simulador, ordenar arrastrando y modo oscuro.
