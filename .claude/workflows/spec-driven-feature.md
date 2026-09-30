---
name: spec-driven-feature
description: Proceso completo para implementar o modificar una feature en este proyecto — spec, plan, tasks, implementación por capas hexagonales, tests, revisión. Úsalo al empezar una feature nueva o un cambio sustancial en una existente.
---

# Spec-Driven Feature Workflow

Este proyecto no escribe código directamente a partir de una petición: primero pasa por
`specs/<feature>/`. La arquitectura de cada capa está en
`.claude/rules/hexagonal-architecture.md`.

## Pasos

0. **Rama.** Crear `feature/<feature>` (ver `.claude/workflows/git-workflow.md`) antes de
   tocar el spec.

1. **Spec.** Completar o actualizar `specs/<feature>/spec.md`: qué resuelve, qué queda
   fuera de alcance y criterios de aceptación con el formato dado/cuando/entonces. No
   avanzar si quedan preguntas abiertas.

2. **Plan.** Con el spec ya cerrado, completar `specs/<feature>/plan.md`: qué entidades,
   ports, use cases, adapters, controllers y pantallas hacen falta, y cualquier decisión
   técnica no obvia con su porqué.

3. **Tasks.** Derivar `specs/<feature>/tasks.md` del plan: una checklist ordenada,
   domain → ports → adapters → use cases → presentation → tests, siguiendo el orden que ya
   trae la plantilla del archivo.

4. **Implementar tarea por tarea** y marcar cada una al completarla. Si aparece algo que
   `plan.md` no contemplaba, actualizar primero `plan.md` (o `spec.md`) antes de seguir: no
   improvisar arquitectura directamente en el código. Si la tarea toca el motor, datos de
   mercado o contenido educativo, seguir la skill correspondiente.

5. **Tests.** Cubrir `domain/` y `application/` según
   `.claude/rules/testing-conventions.md`, más los parsers del proveedor con fixtures y los
   controllers.

6. **Revisión.** Antes de dar la feature por cerrada, pasar el subagente
   `flutter-reviewer`, con especial atención a que ninguna capa viole la regla de
   dependencia hexagonal (ej. `domain/` importando paquetes externos).

## Cuándo saltarse pasos

Para un cambio trivial (una errata, un ajuste visual sin lógica) no hace falta pasar por
spec, plan y tasks: este workflow es para features nuevas o cambios de comportamiento no
triviales, no para cualquier edición.
