---
description: Ramas permanentes (main, develop), convención de nombres de rama, de dónde sale cada una y cuándo crear una nueva, en este proyecto.
---

# Convención de ramas

## Ramas permanentes

| Rama | Para qué |
|---|---|
| `main` | Versión estable. Solo recibe merges desde `develop`; nunca commits directos. |
| `develop` | Rama de integración. De ella salen todas las ramas de trabajo y a ella vuelven. |

```
main ← develop ← feature/<feature>
               ← fix/<descripción>
               ← chore/<descripción>
```

## Naming

| Tipo de trabajo | Rama | Ejemplo |
|---|---|---|
| Feature nueva (tiene su carpeta en `specs/`) | `feature/<nombre-de-la-feature>` | `feature/analisis_accion` |
| Fix de un bug | `fix/<descripción-corta-en-kebab-case>` | `fix/rsi-sin-bajadas` |
| Cambio de config/tooling (`.claude/`, `AGENTS.md`, `app/pubspec.yaml`, `app/analysis_options.yaml`) | `chore/<descripción-corta>` | `chore/hexagonal-architecture` |

El nombre de la feature en la rama coincide siempre con el nombre de su carpeta en
`specs/<feature>/`: una rama `feature/analisis_accion` se corresponde 1:1 con
`specs/analisis_accion/`, sin tener que buscar la relación.

## Origen y destino

- Las ramas `feature/`, `fix/` y `chore/` **salen de `develop`** (actualizada) y se
  fusionan de vuelta en `develop`.
- `develop` se fusiona en `main` cuando está en un estado estable: tests en verde,
  `flutter analyze` sin avisos y, si hay features, probada en dispositivo.

## Cuándo crear una rama nueva

- **Siempre** antes de empezar una feature nueva (primer paso del workflow
  `spec-driven-feature`, incluso antes de escribir `spec.md`, para que la spec también
  quede versionada en su propia rama).
- **Siempre** para un fix, por pequeño que sea: nunca se hace commit de un fix
  directamente en `develop` ni en `main`.
- Los cambios triviales de un solo archivo dentro de un trabajo ya en curso (ej. una
  errata mientras implementas `analisis_accion`) no necesitan su propia rama: van en la
  misma rama de la feature.

## Qué NO hacer

- No hacer commits directos en `main` ni en `develop`.
- No crear ramas de trabajo a partir de `main`.
- No trabajar features distintas en la misma rama: cada `specs/<feature>/` tiene su
  rama `feature/<feature>` correspondiente.
- No reutilizar una rama de fix para varios fixes no relacionados: una rama, un propósito.
