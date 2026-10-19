---
name: contenido-educativo
description: Crea y revisa el contenido didáctico de la app (explicación de cada métrica del motor, lecciones, preguntas de práctica) y explica conceptos de inversión al usuario (PER, ROIC, EV/EBITDA, RSI, medias móviles, dividendos, diversificación, riesgo). Úsala SIEMPRE que haya que escribir o editar textos educativos de la app, cuando se añada una métrica nueva al motor (necesita explicación), o cuando el usuario pregunte "¿qué es...?", "¿cómo se calcula...?" o "¿por qué importa...?".
---

# Contenido educativo

La app no genera textos con IA en tiempo de ejecución. Las explicaciones se escriben una vez durante el desarrollo, se revisan y se guardan como datos estáticos que la app muestra junto al resultado de cada métrica.

## Enlace con el motor

Cada métrica tiene un `id` estable (ver `motor-analisis`: `per`, `roic`, `rsi`...). El contenido vive en `app/assets/contenido/` (feature `contenido_educativo`), en cuatro archivos por idioma: `metricas.es.json` (una entrada por `id` de métrica del motor), `conceptos.es.json` (conceptos de la gráfica de precio que no son métricas: `media_50`, `media_200`, `grafico_precio`), `bloques.es.json` (los 5 bloques, ids `bloque_valoracion`, `bloque_salud`, `bloque_crecimiento`, `bloque_tecnico`, `bloque_contexto`) y `guia.es.json` (la guía del diagnóstico, id de tema `guia_diagnostico`).

Una métrica o concepto se aprende en un **recorrido de tarjetas cortas** (idea → cálculo → lectura → una tarjeta por trampa → actividades → pregunta), y en la fila del resultado se ve una versión corta con la barra de tramos. Por eso cada tarjeta tiene **una sola idea y como máximo 60 palabras** (lo comprueba `app/test/contenido_coverage_test.dart`). Campos de cada entrada:

- `titulo`: nombre completo.
- `resumen`: una frase para la vista compacta.
- `intuicion`: analogía cotidiana. Lleva una ilustración (ver «Ilustraciones»).
- `formula`: en palabras, indicando de qué estado financiero sale cada dato.
- `formulaVisual`: la fórmula dibujada por piezas (ver «Fórmula por piezas»).
- `ejemplo`: contexto con cifras redondas inventadas; sin prefijo, la app lo rotula «Ejemplo inventado». Sus cifras salen de `formulaVisual`.
- `comoLeerla`: cómo se lee en cualitativo, **sin copiar umbrales del motor** (los pone la barra de tramos, que sale de `metricRules`; si el texto citara cifras se desincronizaría al cambiar una escala).
- `leyenda`: filas `{condicion, significado, tono}` (2-4, `tono` = `positivo`/`neutro`/`negativo`). **Obligatoria si y solo si el motor no tiene escala por tramos** para esa métrica (MACD) y siempre en los conceptos; en las demás no va.
- `cuandoEngana`: **lista** de 1-3 trampas, una por tarjeta (la parte más valiosa).
- `combinaCon`: lista de `id` de métricas o conceptos relacionados.
- `actividades`: al menos una (ver «Actividades»).
- `pregunta`: `texto`, `opciones` (al menos 3), `correcta` (índice) y `explicacion`.

El parser (`educational_content_parser.dart` y `lesson_content_parser.dart`) rechaza una ficha mal formada indicando el archivo, el `id` y el campo. El test de cobertura exige una entrada por cada `id` del módulo de reglas, y todos los requisitos de arriba, para que ninguna métrica llegue a la app sin explicación completa. Si cambia un umbral en el motor, revisa `comoLeerla` (aunque no cite cifras) y los ejemplos.

### Fórmula por piezas

`formulaVisual.tipo` elige cómo se dibuja:

- `cociente`: `numerador` ÷ `denominador` (PER, márgenes, ratios de deuda...).
- `crecimiento`: `inicial`, `final` y `anios` (crecimiento anual compuesto).
- `variacion`: `actual` y `referencia`, `actual / referencia − 1` (precio frente a su media, distancia al máximo...).
- `pasos`: de 2 a 4 pasos con `nombre` y `descripcion`, para lo que no es una cuenta simple (RSI, MACD...). No tiene simulador.

Cada pieza lleva `clave`, `nombre`, `origen` (`mercado`, `cuenta_resultados`, `balance`, `flujo_caja`, `historico_precios`), `ejemplo` y, opcionales, `unidad`, `min`/`max` (la hacen movible en el simulador; `min < ejemplo < max`) y `paso` (salto del deslizador, p. ej. 1 para años enteros). El `resultado` lleva `nombre`, `unidad` opcional y `ejemplo`. Con unidad `%` el valor es una **fracción** (0,10 = 10 %). El resultado del `ejemplo` debe ser el que da la fórmula con los valores de las piezas: lo comprueba un test.

### Ilustraciones

Una por métrica o concepto, dibujada en código con `CustomPainter` (sin imágenes ni paquetes) y los colores del tema, para que sirva en claro y en oscuro. Se registran por `id` en el archivo del bloque (`presentation/illustrations/<bloque>_illustrations.dart`) y en `illustration_for.dart`. Cada una lleva una descripción para lectores de pantalla. Dibuja la analogía de `intuicion`, no un gráfico decorativo.

### Actividades

Cada ficha tiene al menos una, además de la pregunta. Tipos (`tipo`):

- `simulador`: `enunciado`. Mueve las piezas de `formulaVisual` y ve en qué tramo cae el resultado; necesita piezas con `min` y `max`, así que no sirve con `pasos`. No da nota ni veredicto.
- `trampa`: `empresa`, `enunciado` y de 4 a 6 `datos` `{etiqueta, valor, esTrampa, explicacion}` con **exactamente un** dato trampa.
- `comparar`: `sector`, `empresas` (2), 4-5 `filas` `{etiqueta, a, b}` y una `pregunta` con `correcta` 0 o 1. Nunca dice cuál conviene comprar.
- `predecir`: `texto`, `opciones`, `correcta`, `explicacion` y `revelacion` (el dato que lo confirma).
- `ordenar`: `enunciado`, de 3 a 5 `elementos` `{nombre, valor, mostrar}` con valores distintos y `explicacion`; el orden correcto es de menor a mayor `valor`.

Elige la que mejor enseña cada métrica: no todas admiten todos los tipos. Entre todas las fichas deben aparecer los cinco.

## Cómo explicar una métrica

1. **Intuición.** Ejemplo para el PER: "cuántos años tardarías en recuperar lo que pagas si los beneficios no cambiasen".
2. **Fórmula** y de dónde sale cada dato, dibujada por piezas.
3. **Ejemplo** con cifras redondas inventadas (dilo). En contenido estático nunca uses cifras reales de empresas: se quedan desactualizadas.
4. **Cómo leerla**, en cualitativo y como orientación que depende del sector.
5. **Cuándo engaña**, una trampa por tarjeta. Ej.: PER bajo por un beneficio extraordinario puntual; ROE inflado por deuda; RSI en sobrecompra durante semanas en tendencias fuertes.
6. **Actividades** que practiquen justo esa trampa o ese cálculo.
7. **Con qué se combina.** Ninguna métrica se usa sola.
8. **Pregunta de comprobación.**

## Ruta de aprendizaje (estructura de lecciones)

1. Fundamentos: qué es una acción, capitalización, revalorización y dividendos, riesgo, diversificación, interés compuesto, comisiones.
2. Leer una empresa: cuenta de resultados, balance, flujo de caja.
3. Calidad del negocio: márgenes, ROE, ROIC, crecimiento, ventaja competitiva.
4. Salud financiera: deuda, liquidez, cobertura de intereses.
5. Valoración: PER, PEG, EV/EBITDA, P/FCF; relativa e histórica.
6. Precio y momento: medias móviles, RSI, MACD, volumen. El técnico complementa, no sustituye.
7. Psicología y proceso: sesgos (FOMO, aversión a pérdidas, confirmación), tamaño de posición, aportaciones periódicas, escribir la tesis antes de comprar.
8. Producto y fiscalidad (España): cuentas de valores, fondos indexados vs acciones, tributación de plusvalías y dividendos, doble imposición. Máxima prudencia; remitir a AEAT y CNMV.

## Estilo

- Español claro, frases cortas, una idea nueva por pantalla.
- Ejemplos en euros y con empresas europeas además de estadounidenses (en lecciones, sin cifras reales).
- Nunca presentar una regla orientativa como ley ("PER < 15 = barata" es falso en general).
- Reforzar hábitos sanos: diversificación, horizonte largo, no invertir dinero que se necesitará pronto, desconfiar de promesas de rentabilidad rápida.
- Los textos explican qué mide cada métrica y cómo leerla; no afirman que una acción concreta sea buena compra.

## Ejercicios

Los tipos de actividad de arriba son los ejercicios de la app. Ideas de planteamiento:

- **Detectar la trampa:** datos de una empresa ficticia con una señal engañosa (un beneficio extraordinario, un EBITDA de año récord, una base hundida).
- **Comparar dos empresas** ficticias del mismo sector con 4–5 datos.
- **Predecir antes de mirar:** "¿Esperas que el margen de un supermercado sea alto o bajo? ¿Por qué?"
- **Mover los datos:** el simulador deja ver que el mismo resultado cambia de tramo al mover una pieza.

Corregir siempre con explicación, no solo "correcto/incorrecto", y sin tono burlón. Los ejercicios no se puntúan ni se guardan.

## Cuando el usuario pregunta durante el desarrollo

Sigue el mismo orden de explicación, adapta el nivel a su soltura con los términos y conecta la respuesta con la métrica correspondiente del motor cuando exista.
