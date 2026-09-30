---
name: motor-analisis
description: Diseño, construcción y mantenimiento del motor programático que analiza una acción: cálculo de indicadores técnicos y ratios fundamentales, reglas de puntuación, pesos por bloque, perfiles de empresa, veredicto y nivel de confianza. Úsala SIEMPRE que la tarea implique crear o modificar la lógica de análisis, añadir o cambiar una métrica, un umbral o un peso, investigar un resultado que parezca incorrecto, o escribir tests del análisis.
---

# Motor de análisis

El motor transforma datos de mercado en un diagnóstico sin intervención de IA. Debe ser **determinista, testeable y fácil de recalibrar**. Las fórmulas y umbrales detallados están en `references/metricas.md`.

## Arquitectura (por capas, cada una independiente)

1. **Proveedor de datos** → devuelve un objeto normalizado `StockData` (ver skill `datos-mercado`). El resto del motor no sabe de qué API vienen los datos.
2. **Cálculo** → funciones puras que producen valores numéricos:
   - Indicadores técnicos a partir del histórico diario.
   - Ratios fundamentales a partir de estados financieros.
   - Señales de alarma.
3. **Reglas** → un único módulo declarativo con cada métrica, su escala de puntuación, peso, bloque y perfiles a los que aplica. Aquí vive **toda** la opinión del motor.
4. **Puntuación** → aplica reglas, agrega por bloque, calcula veredicto y confianza.
5. **Resultado** → `AnalysisResult` serializable en JSON que la app pinta tal cual.

Por qué así: los criterios cambiarán a menudo mientras se calibra; separarlos de las matemáticas permite ajustar un umbral sin riesgo de romper un cálculo.

## Contrato de datos normalizado (`StockData`)

- Perfil: símbolo, nombre, sector, industria, divisa, capitalización, acciones en circulación, PER, PER adelantado, PEG, P/VC, P/Ventas, EV/EBITDA, beta, rentabilidad por dividendo, precio objetivo de analistas.
- Histórico diario: fecha, apertura, máximo, mínimo, cierre, volumen, en **orden cronológico ascendente**.
- Estados financieros anuales y trimestrales (del **más reciente al más antiguo**): cuenta de resultados, balance, flujo de caja.
- Resultados trimestrales: BPA real, BPA estimado, fecha de publicación.
- Fecha de obtención de los datos.

Convenciones obligatorias:
- Dato ausente = `null`. Nunca 0 ni NaN (un 0 se puntuaría como dato real).
- Porcentajes como fracción (0,025 = 2,5 %).
- Gastos (CAPEX, dividendos pagados, recompras) en positivo.

## Los 5 bloques

| Bloque | Pregunta | Peso largo plazo | Peso corto plazo |
|---|---|---|---|
| valoracion | ¿Está cara o barata? | 30 % | 20 % |
| salud | ¿Aguanta un mal año? | 20 % | 15 % |
| crecimiento | ¿El negocio mejora y es rentable? | 30 % | 20 % |
| tecnico | ¿Qué hace el precio ahora? | 10 % | 35 % |
| contexto | ¿Hay riesgos o eventos próximos? | 10 % | 10 % |

El horizonte por defecto es largo plazo (la app es para aprender a invertir, no a especular).

## Sistema de puntuación

- Cada regla define una **escala por tramos**: lista de puntos `(valor, nota)` ordenados por valor. Entre puntos se interpola linealmente; fuera del rango, se satura en el extremo. Nota final 0–10, redondeada a 1 decimal.
- "Menor es mejor" (PER, deuda) → notas descendentes. Óptimo intermedio (RSI, distancia a la media de 200) → notas que suben y bajan.
- Casos que no encajan en una escala (p. ej. MACD, que depende del signo y la tendencia del histograma) usan una función de puntuación propia, declarada igualmente en el módulo de reglas.
- **Nota de bloque** = media ponderada de las métricas con dato. **Cobertura** = peso con dato / peso total del bloque.
- Cada regla puede llevar una **nota explicativa** cuando el valor es null por un motivo conocido (p. ej. "PER no aplica: beneficios negativos").

## Perfiles de empresa

El perfil cambia **pesos** de métricas, nunca fórmulas. Detección en este orden:
1. `financiera`: sector o industria de banca, seguros o servicios financieros. Desactiva deuda/EBITDA, deuda/patrimonio, liquidez, márgenes operativos, ROIC y EV/EBITDA; activa P/VC y ROE con peso alto.
2. `crecimiento`: beneficio de los últimos 12 meses ≤ 0, o ingresos creciendo > 20 % anual en 3 años. Reduce peso del PER y del crecimiento del beneficio; activa P/Ventas y margen bruto.
3. `dividendo`: rentabilidad por dividendo ≥ 3 %. Activa dividendo/FCF en salud.
4. `general`: el resto.

## Veredicto

- Nota global = media ponderada de bloques con nota (renormalizando pesos si falta alguno).
- ≥ 7 `favorable` · ≥ 5 `neutral` · < 5 `desfavorable`.
- Menos de 3 bloques con nota → `datos_insuficientes`.
- **Regla de coherencia:** si salud < 4, el veredicto máximo es `neutral` (una empresa frágil y barata puede seguir abaratándose). Añade aviso.
- **Confianza:** `alta` si cobertura ponderada ≥ 80 % y los 5 bloques tienen nota; `media` si ≥ 60 %; si no, `baja`. Datos de precio con más de 7 días → siempre `baja`.

## Avisos (flags)

Textos listos para mostrar: señales de alarma de `references/metricas.md`, datos antiguos, histórico corto, veredicto limitado por salud, y resultados trimestrales probablemente en ≤ 14 días (estimación: último informe + 91 días, si la API no da la fecha real).

## Resultado (`AnalysisResult`)

Símbolo, nombre, fecha del último cierre, último periodo fiscal, precio, perfil, horizonte, veredicto, nota global, confianza, bloques (cada uno con nota, peso, cobertura y sus métricas: `id`, etiqueta, valor, valor formateado, nota, peso, nota explicativa), avisos, datos faltantes y **versión del motor**.

El `id` de cada métrica es estable (snake_case: `per`, `roic`, `rsi`...) porque la app lo usa para mostrar la explicación educativa.

## Invariantes

1. Funciones de cálculo puras; sin umbrales dentro.
2. Sin reloj del sistema ni aleatoriedad en el cálculo: la fecha de referencia se recibe como parámetro.
3. Cambio en reglas que altere resultados → subir versión del motor (semver: umbral = patch, métrica nueva = minor, cambio de escala global o veredicto = major).
4. El motor es Dart puro en `domain/motor/`: no depende de Flutter ni de la API concreta, así que se puede ejecutar en la app, en tests, en un script de línea de comandos o en un futuro backend en Dart.

## Cómo añadir una métrica

1. Si requiere un dato nuevo: ampliar `StockData` y el parser del proveedor.
2. Función de cálculo pura + test.
3. Regla en el módulo de reglas con `id`, bloque, etiqueta, formato, peso, escala y perfiles.
4. Actualizar `references/metricas.md`.
5. Añadir su explicación (skill `contenido-educativo`).
6. Tests y versión.

## Tests (obligatorios)

- Indicadores con valores conocidos: RSI de una serie solo alcista = 100, serie plana = 50; SMA trivial; drawdown de una serie concreta; null con datos insuficientes.
- **Empresas sintéticas** generadas en los tests (sin red): una "de calidad" en tendencia alcista debe salir `favorable` y una "frágil" (deuda alta, dilución, ventas cayendo, tendencia bajista) `desfavorable`.
- Casos límite: PER con beneficios negativos no puntúa; perfil financiero desactiva métricas de deuda; salud débil impide `favorable`; datos vacíos → `datos_insuficientes`; datos antiguos → confianza baja.
- Determinismo: analizar dos veces los mismos datos da un resultado idéntico.
- Cada bug encontrado con datos reales → guardar la respuesta real de la API como fixture y añadir test de regresión.

## Depurar un resultado raro

1. Ejecuta el análisis en modo JSON y localiza la métrica con nota inesperada.
2. ¿Problema de datos (parser, signo, unidades, periodo) o de umbral?
3. Datos → corregir en el proveedor. Umbral → consultarlo con el usuario antes de cambiarlo, porque afecta a todas las acciones.

## Mejoras futuras

Valoración frente al histórico propio (PER medio 5 años), comparación con el sector, fuerza relativa frente a un índice, fecha real de resultados.
