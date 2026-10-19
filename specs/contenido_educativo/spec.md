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


---

## Revisión 2: fichas visuales y actividades (2026-10-19)

> Estado: cerrada (2026-10-19).

### Qué cambia y por qué

Cada ficha es hoy un bloque de seis textos seguidos y una pregunta tipo test. Cuesta
digerirlo: hay que leerlo todo para llegar a lo útil y lo único que se practica es
elegir una opción. Esta revisión rehace las fichas para que se aprendan **viéndolas y
haciendo algo**: la ficha se recorre en pasos cortos, la fórmula y la escala se dibujan,
la analogía lleva una ilustración y cada ficha tiene actividades además del test.

Afecta a las 30 fichas de métrica y a los 3 conceptos de la gráfica (`media_50`,
`media_200` y `grafico_precio`). Los ejemplos siguen siendo **inventados** y rotulados
(criterio 4 vigente): se decidió no usar cifras reales.

### Fuera de alcance (añade a los de arriba)

- Lecciones y ruta de aprendizaje: siguen en su propia spec futura, que reutilizará estos
  formatos.
- Ejemplos con cifras reales, ya sean históricos o de la empresa analizada.
- Rehacer las fichas de bloque, la guía del diagnóstico y el glosario (solo cambia lo
  que abren).
- Guardar progreso, rachas o puntuaciones: sigue sin guardarse nada.
- Animaciones complejas o vídeo.

### Criterios de aceptación

#### Recorrido por pasos

72. **Dado** una ficha, **cuando** la abro, **entonces** la veo como una secuencia de
    tarjetas cortas (la idea → cómo se calcula → cómo leerla → cuándo engaña →
    actividades → comprueba lo que has aprendido), cada una con una sola idea y un
    indicador de en qué paso estoy.
73. **Dado** el recorrido, **cuando** deslizo o pulso "Siguiente"/"Anterior", **entonces**
    paso de tarjeta, y puedo saltar a cualquier paso desde el indicador sin tener que
    hacer los anteriores.
74. **Dado** una tarjeta, **cuando** la leo, **entonces** su texto principal ocupa como
    máximo unas 60 palabras (lo comprueba un test sobre el contenido real); lo que no
    quepa se reparte en otra tarjeta o se convierte en visual.

#### Visual

75. **Dado** la tarjeta de la idea, **cuando** la veo, **entonces** la analogía va con una
    ilustración sencilla propia de esa métrica, legible en tema claro y oscuro.
76. **Dado** la tarjeta "Cómo se calcula", **cuando** la veo, **entonces** la fórmula se
    dibuja por piezas (p. ej. precio ÷ beneficio por acción), cada pieza dice de dónde
    sale (mercado, cuenta de resultados, balance, flujo de caja o histórico de precios)
    y debajo va el ejemplo inventado resuelto con esas mismas piezas.
77. **Dado** una métrica que el motor puntúa con una escala por tramos, **cuando** veo
    "Cómo leerla", **entonces** hay una barra con los tramos coloreados (nota alta,
    media y baja) y sus valores frontera, y el texto los presenta como orientación que
    depende del sector (criterio 19).
78. **Dado** que cambia la escala de una métrica en el motor, **cuando** abro su ficha,
    **entonces** la barra muestra la escala nueva sin tocar el contenido: la barra sale
    del motor, no de una copia en el contenido.
79. **Dado** una métrica sin escala por tramos (MACD) o un concepto de la gráfica,
    **cuando** veo "Cómo leerla", **entonces** hay un visual equivalente (p. ej. qué
    significa cada signo o cruce) en vez de la barra.

#### Actividades

80. **Dado** una ficha, **cuando** llego a "Actividades", **entonces** hay al menos una
    actividad interactiva distinta de la pregunta tipo test; entre todas las fichas
    aparecen los cuatro tipos de los criterios 81-84.
81. **Simulador.** **Dado** una métrica que se calcula con datos que se pueden mover
    (p. ej. PER, deuda/EBITDA, margen), **cuando** muevo los deslizadores de sus piezas,
    **entonces** veo al momento el valor resultante y su posición en la barra de tramos.
    El simulador no da nota ni veredicto: dice en qué tramo cae.
82. **Detectar la trampa.** **Dado** una empresa inventada con 4-6 datos, uno de ellos
    engañoso, **cuando** pulso el que creo que engaña, **entonces** se me explica por qué
    es (o no es) la trampa, y puedo seguir probando.
83. **Comparar dos empresas.** **Dado** dos empresas inventadas del mismo sector con 4-5
    métricas, **cuando** respondo a una pregunta sobre ellas (p. ej. "¿cuál aguanta mejor
    su deuda?"), **entonces** se me explica la respuesta a partir de sus datos, sin
    decir cuál conviene comprar.
84. **Predecir y ordenar.** **Dado** una pregunta de predicción ("¿el margen de un
    supermercado es alto o bajo?") o una lista de 3-5 empresas inventadas para ordenar
    por una métrica, **cuando** respondo, **entonces** veo la solución y su explicación.
85. **Dado** cualquier actividad, **cuando** respondo, **entonces** siempre hay una
    explicación, no solo "correcto/incorrecto", sin tono burlón; puedo repetirla y no se
    guarda nada (como el criterio 5).

#### Calidad del contenido

86. **Dado** el contenido real, **cuando** se ejecutan los tests, **entonces** cada ficha
    tiene ilustración, fórmula por piezas y al menos una actividad válida (índices
    correctos dentro de rango, un único dato trampa, rangos de deslizador con mínimo <
    valor inicial < máximo), y los cuatro tipos de actividad aparecen.
87. **Dado** el simulador de una métrica, **cuando** se ejecutan los tests, **entonces**
    con los valores iniciales de sus piezas da el mismo resultado que el ejemplo
    inventado de la ficha.
88. **Dado** los textos nuevos (actividades incluidas), **cuando** se ejecutan los tests,
    **entonces** siguen aplicando los criterios 4, 17 y 19: sin empresas reales, sin
    frases de recomendación y sin reglas orientativas presentadas como ley.

### Decisiones

- **Ejemplos inventados (2026-10-19)**: se valoró usar casos históricos fechados o el
  dato real de la empresa analizada, y se descartó: el foco de esta revisión es la forma,
  no el origen de los datos.
- **La barra de tramos sale del motor**: `contenido_educativo` no puede importar de
  `analisis_accion`, así que la escala se le pasa desde el composition root (igual que
  `ShowInfo`). Copiar los umbrales al JSON los desincronizaría al primer cambio.
- **Una actividad mínima por ficha, no cuatro**: no todas las métricas admiten todos los
  tipos (el simulador necesita una fórmula con piezas que se puedan mover). Se elige la
  que mejor enseña cada métrica.

#### Dónde se abre

89. **Dado** un resultado, **cuando** pulso el icono de información de una métrica,
    **entonces** la fila despliega una versión corta (resumen y barra de tramos, o su
    visual equivalente) con un botón "Aprender paso a paso" que abre el recorrido a
    pantalla completa. Sustituye a la ficha completa desplegada del criterio 1; el
    mostrar/ocultar del criterio 2b se mantiene.
90. **Dado** el glosario, una métrica de "se combina con" o un concepto de la gráfica,
    **cuando** lo abro, **entonces** se abre directamente el recorrido a pantalla
    completa (sustituye a la hoja inferior del criterio 3, con el mismo botón para volver).

### Preguntas abiertas

Ninguna. Decisiones al cerrar (2026-10-19):

- **Versión corta en la fila y recorrido a pantalla completa**: las tarjetas con
  deslizadores no caben bien dentro de una lista con scroll, y la versión corta mantiene
  la explicación rápida en el sitio, que fue lo que se pidió el 2026-10-06.
- **Ilustraciones de línea dibujadas en código**: una por ficha (33), con los colores del
  tema para que funcionen en modo oscuro, sin imágenes ni paquetes nuevos.
