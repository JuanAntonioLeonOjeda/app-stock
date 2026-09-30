---
description: Convención de nombres de rama y cuándo crear una nueva, en este proyecto.
---

# Convención de ramas

## Naming

| Tipo de trabajo | Rama | Ejemplo |
|---|---|---|
| Feature nueva (tiene su carpeta en `specs/`) | `feature/<nombre-de-la-feature>` | `feature/analisis_accion` |
| Fix de un bug | `fix/<descripción-corta-en-kebab-case>` | `fix/rsi-sin-bajadas` |
| Cambio de config/tooling (`.claude/`, `AGENTS.md`, `app/pubspec.yaml`, `app/analysis_options.yaml`) | `chore/<descripción-corta>` | `chore/hexagonal-architecture` |

El nombre de la feature en la rama coincide siempre con el nombre de su carpeta en
`specs/<feature>/` — así una rama `feature/analisis_accion` se corresponde 1:1 con
`specs/analisis_accion/`, sin tener que buscar la relación.

## Cuándo crear una rama nueva

- **Siempre** antes de empezar una feature nueva (primer paso del workflow
  `spec-driven-feature`, incluso antes de escribir `spec.md` — así el spec en sí también
  queda versionado en su propia rama).
- **Siempre** para un fix, por pequeño que sea — nunca commitear un fix directo a `main`.
- Cambios triviales de un solo archivo dentro de trabajo ya en curso en una rama (ej. un
  typo mientras implementas `analisis_accion`) no necesitan su propia rama — van en la misma rama
  de la feature.

## Qué NO hacer

- No trabajar features distintas en la misma rama — cada `specs/<feature>/` tiene su
  rama `feature/<feature>` correspondiente.
- No reutilizar una rama de fix para varios fixes no relacionados — una rama, un propósito.