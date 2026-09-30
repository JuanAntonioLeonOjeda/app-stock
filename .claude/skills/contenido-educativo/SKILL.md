---
name: contenido-educativo
description: Crea y revisa el contenido didáctico de la app (explicación de cada métrica del motor, lecciones, preguntas de práctica) y explica conceptos de inversión al usuario (PER, ROIC, EV/EBITDA, RSI, medias móviles, dividendos, diversificación, riesgo). Úsala SIEMPRE que haya que escribir o editar textos educativos de la app, cuando se añada una métrica nueva al motor (necesita explicación), o cuando el usuario pregunte "¿qué es...?", "¿cómo se calcula...?" o "¿por qué importa...?".
---

# Contenido educativo

La app no genera textos con IA en tiempo de ejecución. Las explicaciones se escriben una vez durante el desarrollo, se revisan y se guardan como datos estáticos que la app muestra junto al resultado de cada métrica.

## Enlace con el motor

Cada métrica tiene un `id` estable (ver `motor-analisis`: `per`, `roic`, `rsi`...). Guarda el contenido en un archivo de datos por idioma (p. ej. `app/assets/contenido/metricas.es.json`) con una entrada por `id` y estos campos:

- `titulo`: nombre completo.
- `resumen`: una frase para la vista compacta.
- `intuicion`: analogía cotidiana.
- `formula`: en palabras, indicando de qué estado financiero sale cada dato.
- `comoLeerla`: qué valores se consideran altos o bajos, coherente con las escalas del motor.
- `cuandoEngana`: trampas típicas (la parte más valiosa).
- `combinaCon`: lista de `id` de métricas relacionadas.
- `pregunta`: texto, opciones, índice correcto y explicación.

Debe existir una entrada por cada `id` del módulo de reglas. Pide que haya un test que lo compruebe, para que ninguna métrica llegue a la app sin explicación. Si cambia un umbral en el motor, revisa `comoLeerla`.

## Cómo explicar una métrica

1. **Intuición.** Ejemplo para el PER: "cuántos años tardarías en recuperar lo que pagas si los beneficios no cambiasen".
2. **Fórmula** y de dónde sale cada dato.
3. **Ejemplo** con cifras redondas inventadas (dilo). En contenido estático nunca uses cifras reales de empresas: se quedan desactualizadas.
4. **Cuándo engaña.** Ej.: PER bajo por un beneficio extraordinario puntual; ROE inflado por deuda; RSI en sobrecompra durante semanas en tendencias fuertes.
5. **Con qué se combina.** Ninguna métrica se usa sola.
6. **Pregunta de comprobación.**

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

- **Detectar la trampa:** datos de una empresa ficticia con una señal engañosa.
- **Comparar dos empresas** ficticias del mismo sector con 4–5 métricas.
- **Predecir antes de mirar:** "¿Esperas que el margen de un supermercado sea alto o bajo? ¿Por qué?"

Corregir siempre con explicación, no solo "correcto/incorrecto", y sin tono burlón.

## Cuando el usuario pregunta durante el desarrollo

Sigue el mismo orden de explicación, adapta el nivel a su soltura con los términos y conecta la respuesta con la métrica correspondiente del motor cuando exista.
