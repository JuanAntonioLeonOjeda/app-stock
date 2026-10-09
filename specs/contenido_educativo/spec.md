# Spec: contenido_educativo

> Estado: cerrada (2026-10-06). Implementada; falta la revisión de contenido por el usuario (T31).

## Qué resuelve

Quiero aprender a invertir, no solo ver un veredicto. Hoy la app me enseña una nota por
bloque y el valor de cada métrica (`analisis_accion`), pero no me explica qué mide cada
una, cómo se lee ni cuándo engaña, así que no sé en qué fijarme ni por qué. Esta feature
añade ese contenido didáctico: una ficha por cada métrica del motor, una explicación de
cada bloque, una guía para leer el diagnóstico (veredicto, nota, confianza, avisos) y un
glosario para consultarlo sin tener que analizar una acción.

Los textos se escriben una vez durante el desarrollo, se revisan y se guardan como datos
estáticos (skill `contenido-educativo`). La app explica; no recomienda comprar ni vender,
y tampoco dice "este es buen momento": enseña qué preguntas hacerse.

## Fuera de alcance

- **Lecciones y ruta de aprendizaje** (fundamentos, leer una empresa, psicología del
  inversor...): es una segunda entrega con su propia spec. Esta primera cubre lo que
  responde a "en qué me fijo en este resultado".
- Ejercicios guiados (detectar la trampa, comparar dos empresas, predecir antes de mirar).
- Fiscalidad y productos financieros de España (cuentas de valores, plusvalías,
  doble imposición): exige revisión legal; cuando se haga, remitirá a AEAT y CNMV.
- Conceptos generales no ligados al motor (qué es una acción, interés compuesto...).
- Guardar progreso, puntuaciones o respuestas del usuario.
- Contenido generado con IA en tiempo de ejecución, o que cambie según la empresa
  analizada. El contenido es el mismo para todas.
- Resumir o interpretar las noticias (el enlace a Google ya existe en `analisis_accion`).
- Idiomas distintos del español.
- Mostrar en la ficha en qué tramo cae el valor actual de la empresa.

## Contenido a escribir

| Qué | Cuántas | Notas |
|---|---|---|
| Ficha de métrica | 30 (una por `id` del motor) | 6 valoración, 6 salud, 9 crecimiento y rentabilidad, 5 técnico, 4 contexto |
| Ficha de bloque | 5 | Qué pregunta responde, qué métricas usa y cómo usarlo |
| Guía del diagnóstico | 1 | Veredicto, nota, confianza, avisos, datos que faltan y límites |
| "Qué mirar antes de invertir" | 1 lista dentro de la guía | Preguntas para hacerse, no consejos |

Cada ficha de métrica tiene: título, resumen de una frase, intuición (analogía
cotidiana), fórmula en palabras (de qué estado financiero sale cada dato), ejemplo con
cifras redondas inventadas, cómo leerla, cuándo engaña, con qué se combina y una
pregunta de comprobación con su explicación.

## Criterios de aceptación

### Ficha de métrica

1. **Dado** un resultado de análisis, **cuando** veo una métrica y pulso su icono de
   información, **entonces** se despliega justo debajo de esa fila su explicación (título,
   resumen, intuición, fórmula, ejemplo, cómo leerla, cuándo engaña, con qué se combina y
   la pregunta), sin salir de la pantalla.
2. **Dado** una métrica "sin dato" o "no aplica", **cuando** pulso su icono, **entonces**
   puedo leer igualmente su explicación (dice qué hace falta para calcularla).
2b. **Dado** una explicación desplegada, **cuando** vuelvo a pulsar el icono, **entonces** se
    oculta; cada métrica se despliega y se oculta por separado y empiezan ocultas.
3. **Dado** la sección "con qué se combina", **cuando** pulso una métrica relacionada,
   **entonces** se abre su ficha en una hoja inferior (con botón para volver a la
   anterior), porque esa métrica puede estar en otro bloque o no tener fila en pantalla.
4. **Dado** el ejemplo de la ficha, **cuando** lo leo, **entonces** pone "Ejemplo
   inventado" y no usa cifras ni nombres de empresas reales.
5. **Dado** la pregunta de comprobación, **cuando** elijo una opción, **entonces** veo si
   acierto y siempre una explicación de por qué; puedo elegir otra opción y no se guarda
   nada.
6. **Dado** que no hay conexión, **cuando** abro cualquier ficha, **entonces** se muestra
   igual (el contenido va dentro de la app).

### Bloques y guía del diagnóstico

7. **Dado** un resultado, **cuando** pulso el icono de información de un bloque (valoración,
   salud, crecimiento, técnico o contexto), **entonces** el bloque se despliega y muestra
   arriba qué pregunta responde, qué métricas lo forman y cómo usarlo, incluyendo que el
   bloque técnico habla de la tendencia del precio y no sirve para adivinar el momento.
   Al pulsarlo otra vez, esa explicación se oculta.
8. **Dado** un resultado, **cuando** pulso "¿Cómo leer este diagnóstico?", **entonces** abro
   una guía que explica el veredicto y sus cuatro valores, la nota global, la confianza,
   los avisos y la sección "Datos que faltan".
9. **Dado** la guía, **cuando** llego a "Qué mirar antes de invertir", **entonces** veo una
   lista de preguntas para hacerse (¿entiendo cómo gana dinero?, ¿puede aguantar su
   deuda?, ¿el precio es razonable frente a lo que gana?, ¿qué dicen las noticias
   recientes?, ¿es dinero que no necesitaré pronto?, ¿cuánto de mi cartera sería?), sin
   decirme qué decidir.
10. **Dado** la guía y las fichas de bloque, **cuando** las leo, **entonces** queda claro
    que el análisis no es una recomendación, con el mismo aviso que el resultado.

### Glosario

11. **Dado** que abro la app, **cuando** estoy en la pantalla de inicio, **entonces** hay
    un acceso "Aprender" que abre el glosario, sin tener que analizar ninguna acción.
12. **Dado** el glosario, **cuando** lo abro, **entonces** veo las 30 métricas agrupadas
    por bloque, cada una con su título y su resumen, y la guía del diagnóstico arriba.
13. **Dado** el glosario, **cuando** escribo en el buscador, **entonces** se filtran las
    métricas por título o resumen, sin tener en cuenta mayúsculas ni tildes.
14. **Dado** una métrica del glosario, **cuando** la pulso, **entonces** se abre su ficha
    (criterio 1).

### Calidad del contenido

15. **Dado** el módulo de reglas del motor, **cuando** se ejecutan los tests, **entonces**
    cada `id` de métrica tiene su ficha y no hay fichas de `id` que no existan. Una
    métrica nueva sin ficha hace fallar el test.
16. **Dado** cada ficha, **cuando** se ejecutan los tests, **entonces** tiene todos sus
    campos rellenos, su pregunta tiene al menos 3 opciones con un índice correcto válido y
    cada `combinaCon` apunta a un `id` existente.
17. **Dado** todo el contenido, **cuando** se ejecutan los tests, **entonces** ningún texto
    contiene frases de recomendación ("buena compra", "compra ya", "te recomendamos",
    "deberías comprar/vender").
18. **Dado** que cambia un umbral o una escala en el motor, **cuando** se hace el cambio,
    **entonces** se revisa el "cómo leerla" de esa métrica (regla en
    `.claude/rules/reglas-motor.md`).
19. **Dado** una regla orientativa en un texto (p. ej. un PER alto o bajo), **cuando** se
    escribe, **entonces** se presenta como orientación que depende del sector y del
    momento, nunca como ley.

## Preguntas abiertas

Ninguna. Decisiones tomadas al cerrar el spec:

- **Explicación en la propia fila (2026-10-06)**: se pidió tenerla desplegable en cada
  parámetro en vez de en una vista aparte. Las métricas y los bloques se explican en el
  sitio; la guía del diagnóstico y el glosario siguen siendo pantallas porque sirven para
  cosas distintas (leer el diagnóstico entero y consultar sin analizar una acción).

- **Primera entrega pequeña**: fichas, bloques, guía y glosario. Las lecciones quedan para
  otra spec porque son contenido nuevo (unas 8 lecciones), no una explicación de lo que
  el motor ya muestra.
- **Un ejemplo y una pregunta por métrica**: cuestan escribir 30 pequeños textos pero son
  lo que convierte la ficha en aprendizaje, no en una definición de diccionario.
- **Sin progreso guardado**: la pregunta es para pensar, no para puntuar.

## Notas para el plan

- Es una feature aparte (`app/lib/features/contenido_educativo/`) y, por la regla de
  dependencias, **no puede importar de `analisis_accion`** ni al revés. Se conectan en el
  composition root (`app/lib/app.dart`): la pantalla de resultado recibe una función que
  abre la ficha de un `id`, sin saber de dónde viene el contenido.
- El test del criterio 15 necesita conocer el módulo de reglas de otra feature; por eso
  vive en `app/test/` (nivel raíz), no dentro de la feature.
- Los textos van en un archivo de datos por idioma (`app/assets/contenido/`), con la
  estructura de la skill `contenido-educativo`.

---

## Revisión: conceptos de la gráfica de precio (2026-10-08)

La gráfica del resumen (spec `analisis_accion`, Revisión 3) tiene cosas que se entienden mal sin
una explicación, sobre todo las medias de 50 y 200 sesiones. Se añaden explicaciones del mismo
tipo que las de las métricas, pero para **conceptos de la gráfica**, que no son métricas del
motor.

### Criterios

68. **Dado** la pestaña Resumen, **cuando** veo los interruptores "Media 50" y "Media 200",
    **entonces** cada uno tiene un icono de información que despliega, justo debajo, su
    explicación (qué es, cómo se calcula, cómo leerla, cuándo engaña, con qué se combina y una
    pregunta); al pulsarlo otra vez se oculta.
69. **Dado** la gráfica de precio, **cuando** pulso el icono junto a su título, **entonces**
    se despliega cómo leerla: qué es cada línea, qué marcan el máximo y el mínimo, qué significa
    "ajustado por splits" y cómo usar los periodos.
70. **Dado** una explicación de concepto, **cuando** la leo, **entonces** tiene la misma
    estructura que la de una métrica, usa un ejemplo inventado y rotulado, y no recomienda
    nada.
71. **Dado** el contenido real, **cuando** se ejecutan los tests, **entonces** existe una
    explicación para cada concepto que la gráfica referencia (`media_50`, `media_200`,
    `grafico_precio`), sus `combinaCon` apuntan a métricas o conceptos existentes y ningún
    concepto se confunde con una métrica del motor.

### Decisiones

- Los conceptos viven en su propio archivo (`conceptos.es.json`) y no cuentan como métricas: el
  test que exige una ficha por cada métrica del motor sigue igual.
- No aparecen en el glosario "Aprender" de esta revisión (el glosario es por bloques del motor).
  La fase 3 del panel decidirá si se agrupan en un apartado de gráficas.

