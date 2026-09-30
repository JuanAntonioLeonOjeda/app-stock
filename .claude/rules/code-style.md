---
description: Estilo de código Dart/Flutter — idioma, formato, lints, entidades inmutables, errores, estado de la UI y comentarios.
---

# Estilo de código

Complementa a `naming-conventions.md`, `import-conventions.md` y
`atomic-functions-solid.md`; lo que ya está allí no se repite aquí.

## Idioma

- **Identificadores en inglés**: clases, funciones, variables y archivos
  (`fetchStockData()`, `AnalyzeStockUseCase`, `stock_data.dart`).
- **Excepciones en español**: los `id` de métricas (`per`, `deuda_ebitda`...), que son
  estables y enlazan con el contenido educativo, y todo texto visible para el usuario.
- **Comentarios, doc comments y mensajes de commit en español.**

## Formato

- `dart format` con la longitud de línea por defecto (80). No se configura otra.
- Comas finales en listas de argumentos y colecciones de varias líneas, para que el
  formateador las rompa una por línea (lo exige `require_trailing_commas`).
- El código se entrega formateado y con `flutter analyze` sin avisos.

## Lints

`app/analysis_options.yaml` parte de `flutter_lints` y añade:

```yaml
analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
linter:
  rules:
    - always_use_package_imports
    - prefer_final_locals
    - require_trailing_commas
    - avoid_dynamic_calls
```

No se silencian avisos con `// ignore:` salvo justificación en el mismo comentario.

## Tipado y null-safety

- Tipos de retorno siempre explícitos, también en funciones privadas.
- Sin `dynamic` fuera del parseo de JSON, y se convierte a tipos concretos en el propio
  adapter.
- `null` significa "dato ausente" (ver skill `motor-analisis`): no usar `!` para esquivarlo.
  Si un valor puede faltar, el tipo es nullable y quien lo consume decide qué hacer.
- `final` por defecto; `var` solo si la variable se reasigna.

## Entidades inmutables

- Clases con todos los campos `final` y constructor `const` cuando sea posible.
- `copyWith`, `==`/`hashCode` y `fromJson`/`toJson` se escriben a mano, **solo** cuando
  hacen falta. Sin generación de código (`freezed`, `json_serializable`).
- La serialización JSON vive en `infrastructure/`, no en las entidades de `domain/`.
- Las colecciones que exponen las entidades son inmutables (`List.unmodifiable`).

## Errores

- Los errores esperados son **excepciones tipadas** con una jerarquía propia definida en
  `domain/` (p. ej. `MarketDataException` y sus subtipos `RateLimitException`,
  `NotFoundException`, `InvalidResponseException`, `NetworkException`, como en la skill
  `datos-mercado`).
- Los adapters traducen los errores del paquete externo a esa jerarquía; nunca dejan
  escapar excepciones de `http` o de otras librerías.
- `presentation/` las captura y las convierte en mensajes para el usuario.
- Nunca un `catch` vacío ni un `catch (e)` genérico que se trague el error.

## Estado de la UI

- Un controller por pantalla que extiende `ChangeNotifier`, llama a los use cases y
  expone estado inmutable. La pantalla escucha con `ListenableBuilder`.
- Sin librerías de estado (`riverpod`, `bloc`, `provider`) ni de DI: el controller recibe
  los use cases por constructor (ver `hexagonal-architecture.md`).
- Los widgets no contienen lógica de negocio: solo pintan el estado y reenvían eventos al
  controller.

## Comentarios

- Se comenta el **porqué**, nunca el qué: decisiones no obvias, rarezas de la API
  (ej. errores con HTTP 200) y fórmulas, enlazando con `references/metricas.md`.
- Doc comment (`///`) obligatorio en ports y use cases; en el resto, solo si aporta.
- Sin código comentado: para eso está git.
- `TODO` solo con contexto suficiente para retomarlo (`// TODO: qué y por qué`).
