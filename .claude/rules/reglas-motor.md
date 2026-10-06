---
paths:
  - "app/lib/features/analisis_accion/domain/motor/**"
  - "app/test/features/analisis_accion/domain/motor/**"
---

# Reglas al editar el motor de análisis

- Antes de modificar nada aquí, consulta la skill `motor-analisis`.
- Umbrales, pesos y escalas van solo en el módulo de reglas. Si ves un número "mágico" en
  una función de cálculo, muévelo allí.
- Dato ausente = `null`. Nunca devolver 0 o NaN para indicar que un dato no está disponible.
- Funciones de cálculo puras: sin llamadas de red, sin reloj del sistema y sin aleatoriedad.
- Cualquier cambio que altere resultados obliga a actualizar los tests, subir la versión
  del motor y actualizar `references/metricas.md`.
- Una métrica nueva necesita también su entrada de contenido educativo con el mismo `id`
  (`app/assets/contenido/metricas.es.json`); el test `app/test/contenido_coverage_test.dart`
  falla si falta. Si cambias un umbral o una escala, revisa el `comoLeerla` de esa métrica:
  el texto debe seguir cuadrando con lo que puntúa el motor.
- No des una tarea por terminada si los tests no pasan.
- Nunca escribas claves de API en el código ni en archivos versionados.
