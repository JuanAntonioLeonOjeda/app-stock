---
description: Convenciones de testing (flutter_test) — estructura, naming, qué debe tener test y fakes escritos a mano.
---

# Convenciones de testing

## Estructura

`app/test/` refleja la estructura de `app/lib/`, feature por feature:

```
app/test/
  features/
    analisis_accion/
      domain/motor/...
      infrastructure/adapters/...
      application/
        fake_ports.dart
  fixtures/            # respuestas reales de la API guardadas (ver skill datos-mercado)
```

Un archivo de test por cada archivo de código, con el mismo nombre y el sufijo `_test.dart`.
No agrupar varios archivos de `lib/` en un solo test grande.

## Naming

- Archivo: `<nombre_del_archivo_original>_test.dart`.
- Cada `group()` lleva el nombre de la clase o función que se prueba.
- `test()` cuenta en lenguaje llano, y en español, el comportamiento esperado, no el nombre
  del método. Ej.: `'PER con beneficios negativos devuelve null con nota'`, no `'test per'`.

## Qué debe tener test (obligatorio) y qué no

**Siempre:**
- Todo el motor (`domain/motor/`): indicadores con valores conocidos, empresas sintéticas,
  casos límite y determinismo. La lista mínima está en la skill `motor-analisis`, sección
  "Tests".
- Parsers y normalización del proveedor (`infrastructure/adapters/`), con fixtures de
  respuestas reales: errores con HTTP 200, `"None"` → `null`, signos y orden.
- Use cases de `application/`.
- Controllers de `presentation/controllers/` (transiciones de estado).
- Que cada `id` de métrica del módulo de reglas tenga su entrada de contenido educativo
  (skill `contenido-educativo`).

**No obligatorio (a criterio):**
- Widgets puramente visuales sin lógica propia.

## Herramientas

- `flutter_test`. Los tests **no hacen llamadas de red**: usan datos sintéticos o fixtures.
- Sin framework de mocking. Los ports se sustituyen por **fakes escritos a mano**
  (`app/test/features/<feature>/application/fake_ports.dart`), no por mocks generados: no
  se mezclan dos enfoques.

## Comando

```bash
cd app && flutter test
```
