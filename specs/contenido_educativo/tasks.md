# Tasks: contenido_educativo

> Derivadas de `plan.md`. Marcar cada una al completarla.
>
> **Cada tarea con comportamiento incluye su archivo de test** (`app/test/` refleja
> `app/lib/`); las entidades que solo guardan datos no llevan test. Ninguna tarea se da por
> terminada hasta que `flutter analyze` no da avisos y `flutter test` pasa. Rutas relativas
> a `app/lib/features/contenido_educativo/` salvo que se indique otra cosa.

## Setup

- [ ] T01. Declarar `assets/contenido/` en `app/pubspec.yaml` y crear la carpeta con los 3
      archivos vacíos (`metricas.es.json`, `bloques.es.json`, `guia.es.json`).
- [ ] T02. Estructura de carpetas de la feature (se crea con el primer archivo de cada una).

## Domain

- [ ] T03. `domain/entities/`: `check_question.dart`, `metric_content.dart`,
      `block_content.dart`, `diagnosis_guide.dart` y `educational_content.dart`
      (colecciones inmutables).
- [ ] T04. `domain/exceptions/educational_content_exception.dart`.
- [ ] T05. `domain/content/glossary_search.dart` + test (mayúsculas, tildes, sin resultados,
      texto vacío).
- [ ] T06. `domain/ports/educational_content_port.dart` (con doc comment).

## Infrastructure

- [ ] T07. `infrastructure/adapters/educational_content_parser.dart` + test con JSON
      sintético: caso válido y un caso por cada validación del plan.
- [ ] T08. `infrastructure/adapters/asset_educational_content_adapter.dart` + test con un
      `AssetBundle` falso (lee los 3 archivos, memoria, error de lectura).

## Application

- [ ] T09. `application/use_cases/load_educational_content_use_case.dart` y
      `search_glossary_use_case.dart` + tests, y `fake_ports.dart` de la feature.

## Contenido

> Cada tarea: leer antes las escalas de ese bloque en `metric_rules.dart`, escribir las
> fichas con la estructura de la skill, revisar que el "cómo leerla" cuadra con las
> escalas y que ningún texto parece una recomendación. **El usuario revisa el contenido.**

- [ ] T10. Valoración (6): `per`, `peg`, `ev_ebitda`, `p_fcf`, `p_ventas`, `p_vc`.
- [ ] T11. Salud financiera (6): `deuda_ebitda`, `deuda_patrimonio`, `liquidez`,
      `cobertura_intereses`, `fcf_positivo`, `payout_fcf`.
- [ ] T12. Crecimiento y rentabilidad (9): `ingresos_cagr3`, `ingresos_yoy`,
      `beneficio_cagr3`, `margen_operativo`, `margen_tendencia`, `margen_bruto`, `roic`,
      `roe`, `dilucion`.
- [ ] T13. Técnico (5): `precio_sma200`, `pendiente_sma200`, `rsi`, `macd`, `dist_maximo`.
- [ ] T14. Contexto (4): `sorpresas_bpa`, `potencial_analistas`, `beta`, `caida_maxima`.
- [ ] T15. Los 5 bloques (`bloques.es.json`), incluyendo que el técnico no sirve para
      adivinar el momento.
- [ ] T16. La guía del diagnóstico y "Qué mirar antes de invertir" (`guia.es.json`).
- [ ] T17. `app/test/contenido_coverage_test.dart`: criterios 15, 16 y 17 con el contenido
      real, y una ficha de bloque por cada `Block`.

## Presentation

- [ ] T18. `presentation/controllers/topic_sheet_controller.dart` + test (pila, atrás,
      respuesta que se borra al cambiar de tema, error de carga).
- [ ] T19. `presentation/controllers/glossary_controller.dart` + test.
- [ ] T20. Widgets: `educational_notice.dart`, `example_box.dart`,
      `check_question_card.dart`, `related_metrics.dart`, `metric_content_view.dart`,
      `block_content_view.dart` + tests de los que tienen lógica (pregunta, ejemplo).
- [ ] T21. `presentation/widgets/topic_sheet.dart` con `showTopicSheet(...)` + test.
- [ ] T22. `presentation/screens/glossary_screen.dart` + test (grupos por bloque, buscador).
- [ ] T23. `presentation/screens/diagnosis_guide_screen.dart` + test (secciones, lista y
      aviso).

## Integración en `analisis_accion`

- [ ] T24. `typedef ShowInfo` y `blockTopicId(Block)` en `labels.dart` + test.
- [ ] T25. Icono de información en `MetricRow` y `BlockTile` (solo si hay `showInfo`) +
      tests con y sin callback.
- [ ] T26. Botón "¿Cómo leer este diagnóstico?" en `AnalysisScreen` y acción "Aprender" en
      `HomeScreen` + tests.
- [ ] T27. Composition root en `app/lib/app.dart`: adapter, use cases, `showInfo` y
      `onOpenLearn`.

## Documentación

- [ ] T28. `reglas-motor.md` (revisar `comoLeerla` al cambiar un umbral), `AGENTS.md` y la
      skill `contenido-educativo` (rutas y ids de tema).

## Verificación

- [ ] T29. `dart format`, `flutter analyze` y `flutter test` limpios.
- [ ] T30. En dispositivo: abrir una ficha desde el resultado, navegar por "con qué se
      combina", responder una pregunta, abrir la guía y el glosario sin conexión.
- [ ] T31. Revisión de contenido por el usuario (T10-T16): que el "cómo leerla" cuadra con
      cómo piensa la métrica y que el tono ayuda a aprender.

## Revisión

- [ ] T32. `flutter-reviewer` (con atención a que ninguna feature importe de la otra).
