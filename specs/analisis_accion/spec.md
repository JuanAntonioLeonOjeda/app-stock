# Spec: analisis_accion

> Estado: cerrada (2026-09-30). **Revisión 4 (gráfica del día y de la semana) cerrada el
> 2026-10-08**: ver la sección "Revisión 4" al final. **Revisión 3 (histórico real y gráfica de precio, fase 1
> del panel "Resumen") cerrada el 2026-10-08**: ver la sección "Revisión 3" al final; sustituye
> el criterio 35. **Revisión 2 (proveedor TradingView) cerrada el 2026-10-06**: ver la sección "Revisión 2" al final; sustituye a Alpha Vantage como
> proveedor y modifica los criterios 5, 22, 27 y 31. Siguiente paso: actualizar `plan.md`.

## Qué resuelve

Quiero entender si una acción concreta está sana, cara o barata, y en qué momento está su
precio, sin tener que interpretar decenas de ratios sueltos. Busco una empresa por nombre o
ticker y la app me muestra un diagnóstico calculado por el motor de análisis (skill
`motor-analisis`): veredicto, nota global, confianza, avisos y el detalle por bloques y
métricas. Es una app de uso personal y el análisis tiene fin educativo, no es una
recomendación.

## Fuera de alcance

- Contenido educativo (explicación de cada métrica, lecciones, preguntas): es otra feature
  con su propia spec. Esta feature solo entrega el `id` estable de cada métrica.
- Horizonte de corto plazo: solo se analiza a largo plazo. El motor acepta el horizonte
  como parámetro, pero la UI no lo expone.
- Contador de peticiones restantes: la app solo reacciona cuando la API devuelve
  `rate_limit`.
- Backend propio, cuentas de usuario y sincronización entre dispositivos.
- Carteras, favoritos, alertas de precio y notificaciones.
- Comparar varias acciones, gráficos de precio y datos en tiempo real.
- Otros proveedores de datos distintos de Alpha Vantage.
- Mejoras futuras del motor (valoración frente al histórico propio, comparación con el
  sector, fuerza relativa frente a un índice).
- Idiomas distintos del español.

## Criterios de aceptación

### Navegación

0. **Dado** que abro la app, **cuando** carga, **entonces** veo la pantalla de inicio con
   el buscador arriba y el historial debajo. Al elegir una acción (de la búsqueda o del
   historial) se abre la pantalla de resultado.

### Búsqueda

1. **Dado** que estoy en la pantalla de búsqueda, **cuando** escribo un nombre o ticker
   (p. ej. "Inditex" o "AAPL") y confirmo la búsqueda, **entonces** veo una lista de
   coincidencias con símbolo, nombre, región y divisa, ordenada por relevancia.
2. **Dado** que estoy escribiendo, **cuando** aún no he confirmado la búsqueda (con el
   botón o la tecla intro), **entonces** no se hace ninguna petición a la API (no se busca
   en cada pulsación, para no gastar peticiones).
3. **Dado** que ya busqué el mismo texto en los últimos 30 días, **cuando** lo busco de
   nuevo, **entonces** los resultados salen de la caché sin gastar peticiones.
4. **Dado** que la búsqueda no encuentra nada, **cuando** termina, **entonces** veo el
   mensaje "No se ha encontrado ninguna acción" y puedo buscar otra vez.

### Análisis

5. **Dado** que he elegido una acción de la lista, **cuando** empieza el análisis,
   **entonces** veo un indicador de progreso con el paso actual (p. ej. "Obteniendo
   balance, 3 de 6"), porque las peticiones se hacen en secuencia y con pausas.
6. **Dado** que los datos de esa acción están en caché y no han caducado (caducidades de
   la skill `datos-mercado`), **cuando** la analizo, **entonces** solo se piden a la API
   los datos caducados o que faltan.
7. **Dado** que el análisis termina, **cuando** se muestra el resultado, **entonces** se
   guarda en el historial.
8. **Dado** que el mismo `StockData` se analiza dos veces, **cuando** comparo los
   resultados, **entonces** son idénticos (motor determinista).

### Resultado

9. **Dado** un análisis completo, **cuando** veo el resultado, **entonces** arriba aparecen
   el nombre, el símbolo, el precio, la fecha del último cierre, el perfil detectado, el
   veredicto (`favorable`, `neutral`, `desfavorable` o `datos insuficientes`), la nota
   global sobre 10, la confianza (`alta`, `media` o `baja`) y los avisos.
10. **Dado** un análisis completo, **cuando** veo el resultado, **entonces** debajo aparecen
    los 5 bloques (valoración, salud, crecimiento, técnico y contexto) con su nota y su
    cobertura, plegados por defecto.
11. **Dado** un bloque plegado, **cuando** lo despliego, **entonces** veo sus métricas con
    etiqueta, valor formateado (porcentajes con %), nota y, si existe, su nota
    explicativa.
12. **Dado** que una métrica no tiene dato, **cuando** la veo, **entonces** aparece como
    "sin dato" con su nota explicativa, nunca como 0.
13. **Dado** que faltan datos para alguna métrica, **cuando** veo el resultado,
    **entonces** hay una sección "Datos que faltan" que los enumera.
14. **Dado** cualquier resultado, **cuando** lo veo, **entonces** aparece de forma visible
    el texto "Análisis con fin educativo. No es una recomendación de inversión." y la
    versión del motor.

### Historial

15. **Dado** que he hecho análisis, **cuando** abro el historial, **entonces** veo los 10
    últimos (el más reciente primero) con símbolo, nombre, veredicto y fecha del análisis.
16. **Dado** que ya hay 10 entradas, **cuando** analizo una acción nueva, **entonces** se
    elimina la más antigua. Si la acción ya estaba en el historial, su entrada se actualiza
    y sube al principio (sin duplicados).
17. **Dado** una entrada del historial, **cuando** la abro, **entonces** veo el
    `AnalysisResult` guardado tal cual se calculó (con la versión del motor de entonces),
    sin recalcularlo y sin gastar peticiones, aunque los datos hayan caducado.
18. **Dado** una entrada con datos caducados, **cuando** la abro, **entonces** aparece un
    aviso "Datos de hace X" con la fecha de obtención.
19. **Dado** que cierro la app y la vuelvo a abrir, **cuando** abro el historial,
    **entonces** siguen ahí las mismas entradas (caché e historial persisten en el
    dispositivo).

### Forzar actualización

20. **Dado** un resultado en pantalla (nuevo o del historial), **cuando** pulso
    "Actualizar datos", **entonces** se vuelven a pedir todos los datos ignorando la caché
    y se muestra y guarda el nuevo resultado.
21. **Dado** que la actualización forzada falla, **cuando** termina, **entonces** sigo
    viendo el resultado anterior junto a un mensaje de error; nada se pierde.

### Errores

22. **Dado** que la API responde con límite de peticiones (`rate_limit`), **cuando** estoy
    buscando o analizando, **entonces** veo "Límite de peticiones de la API alcanzado.
    Inténtalo más tarde; puedes consultar el historial", sin cerrar la pantalla ni perder
    lo que ya había en pantalla.
23. **Dado** que la API responde que el símbolo no existe (`not_found`), **cuando**
    analizo, **entonces** veo "No hay datos para este símbolo".
24. **Dado** que no hay conexión (`network`), **cuando** busco o analizo, **entonces** veo
    "Sin conexión" con la opción de reintentar, y el historial sigue accesible.
25. **Dado** una respuesta con formato inesperado (`invalid_response`), **cuando** se
    procesa, **entonces** veo "Respuesta inesperada del proveedor de datos" y esa
    respuesta no se guarda en caché.
26. **Dado** que una petición falla a mitad del análisis, **cuando** termina, **entonces**
    las respuestas correctas ya obtenidas quedan en caché, para no volver a gastarlas al
    reintentar.
27. **Dado** que la app se compiló sin clave de API, **cuando** la abro, **entonces** veo
    "Falta configurar la clave de Alpha Vantage" y no se hace ninguna petición. El
    historial sigue accesible.

### Casos del motor visibles en la UI

(Cubiertos con tests del motor según la skill `motor-analisis`; aquí solo se exige que la UI
los refleje.)

28. **Dado** menos de 3 bloques con nota, **cuando** veo el resultado, **entonces** el
    veredicto es "Datos insuficientes" y no se muestra nota global.
29. **Dado** que la salud es < 4, **cuando** el resto daría `favorable`, **entonces** el
    veredicto es `neutral` y aparece el aviso correspondiente.
30. **Dado** que el último cierre tiene más de 7 días, **cuando** veo el resultado,
    **entonces** la confianza es `baja` y aparece un aviso de datos antiguos.
31. **Dado** que el plan gratuito solo da unas 100 sesiones de histórico, **cuando** se
    analiza, **entonces** se usan las medias y los máximos del perfil como respaldo y
    aparece el aviso de histórico corto.

## Preguntas abiertas

Ninguna.

---

## Revisión 2: proveedor TradingView (2026-10-06)

### Qué cambia y por qué

Alpha Vantage gratuito solo da 25 peticiones al día y no tiene fundamentales de bolsas
como Tokio o Madrid (comprobado con Nintendo, Fast Retailing e Iberdrola). Otras fuentes
gratuitas, como Yahoo Finance, ya se probaron y se descartaron. La app pasa a obtener los
datos de **TradingView**: el buscador de símbolos (`symbol-search.tradingview.com`) y el
scanner (`scanner.tradingview.com`), ambos sin clave. Se mantienen la búsqueda libre, el
historial, el motor y las pantallas; cambia el adapter y, por tanto, qué datos llegan.

Es una fuente **no oficial**: puede cambiar o cortarse sin aviso. Queda detrás de
`MarketDataPort`, así que volver a otro proveedor solo toca el adapter. Vale para uso
personal; antes de publicar en una tienda hace falta un proveedor con licencia.

### Qué datos llegan (comprobado 2026-10-06 con `TSE:7974`, `TSE:9983`, `BME:IBE`, `NASDAQ:AAPL`)

- **Sí:** precio, divisa, sector, capitalización, PER, P/VC, P/Ventas, EV/EBITDA, ROE,
  ROIC, beta, deuda total, deuda/patrimonio, EBITDA, márgenes, BPA, activos, series
  anuales y trimestrales de ingresos, beneficio neto, beneficio bruto, FCF, activos y
  deuda; RSI, medias móviles (SMA50, SMA200), máximo y mínimo de 52 semanas.
- **A veces vacío:** FCF y flujo operativo (vacíos en 2 de 4), dividendo por acción.
- **No llega:** histórico diario de precios, pasivo corriente, gastos por intereses,
  precio objetivo de analistas, PER a futuro.

Consecuencia para el motor: las métricas que dependen del histórico diario (MACD,
volatilidad, caída máxima, pendiente de la SMA200) y las del dato ausente (liquidez,
cobertura de intereses, potencial de analistas) salen como "sin dato" y restan
cobertura. Los demás indicadores técnicos (RSI, precio frente a SMA200, distancia al
máximo) usan los valores ya calculados por el proveedor.

### Fuera de alcance (añade a los de arriba)

- Histórico diario de precios y gráficos (no hay fuente gratuita fiable).
- Completar los huecos con una segunda fuente.
- Una lista fija de acciones o cola de refresco: sin cupo diario no hacen falta.
- Migrar o conservar el formato de caché de Alpha Vantage: se descarta.

### Criterios de aceptación

Los criterios 0-31 siguen vigentes salvo los siguientes, que se sustituyen.

32. **Dado** que elijo una acción, **cuando** empieza el análisis, **entonces** veo un
    indicador de progreso con el paso actual (sustituye al criterio 5; ahora son 1-2
    peticiones, no 6).
33. **Dado** que TradingView bloquea o limita las peticiones, **cuando** busco o analizo,
    **entonces** veo el mensaje del criterio 22 (el error `rate_limit` se mantiene como
    tipo, aunque su causa sea otra) y puedo consultar el historial.
34. **Dado** que ya no hay clave de API, **cuando** abro la app, **entonces** no aparece el
    aviso de clave faltante (el criterio 27 deja de aplicar y se elimina
    `MissingApiKeyException`).
35. **Dado** que la fuente no da histórico diario, **cuando** veo el resultado, **entonces**
    aparece un aviso "Sin histórico de precios: indicadores técnicos limitados" y las
    métricas que lo necesitan salen como "sin dato" (sustituye al criterio 31).
36. **Dado** un símbolo de bolsa extranjera (p. ej. Nintendo, `7974` en `TSE`), **cuando**
    busco "Nintendo", **entonces** veo entre las coincidencias la cotización de su bolsa
    de origen con su divisa (JPY), no solo el ADR estadounidense.
37. **Dado** una acción cuya divisa de precio y de estados financieros difiere (p. ej.
    ADR), **cuando** el motor mezcla ambos, **entonces** usa los ratios ya calculados por
    el proveedor y no divide precio entre importes de otra divisa; si no es posible,
    la métrica sale "sin dato" con una nota.
38. **Dado** que los datos de una acción se obtuvieron hace menos de 6 horas, **cuando** la
    analizo, **entonces** no se hace ninguna petición (sustituye las caducidades por
    endpoint: ahora todo viene de una sola petición).
39. **Dado** una respuesta del scanner sin fila para el símbolo, **cuando** analizo,
    **entonces** veo "No hay datos para este símbolo" (`not_found`).
40. **Dado** que los campos de la respuesta cambian de forma o de tipo, **cuando** se
    procesa, **entonces** veo el aviso del criterio 25 y no se guarda en caché.

#### Noticias recientes

41. **Dado** un resultado en pantalla, **cuando** pulso "Ver noticias recientes",
    **entonces** se abre en el navegador una búsqueda de Google en la pestaña de noticias,
    ordenada por fecha, con el nombre de la empresa y su ticker (p. ej. `Nintendo Co.,
    Ltd. 7974`).
42. **Dado** que el dispositivo no puede abrir el enlace, **cuando** pulso el botón,
    **entonces** veo "No se ha podido abrir el navegador" y el resultado sigue en pantalla.
43. **Dado** que abro las noticias, **cuando** el navegador se abre, **entonces** no se
    envía nada de la app a Google salvo el texto de la búsqueda (sin clave ni historial).

Es un enlace externo: la app no lee ni resume las noticias (nada de IA en tiempo de
ejecución). Su fin es que el usuario contraste el análisis con lo que se cuenta de la
empresa.

### Decisiones y riesgos

- **Sin series diarias el bloque técnico es el más débil.** Se acepta: el análisis es a
  largo plazo (fuera de alcance, el corto plazo).
- **Fixtures reales** de buscador y scanner (3 acciones extranjeras y 1 de EE. UU.) para
  detectar cuándo TradingView cambie el formato.
- **Cada métrica nueva o con fuente distinta** se refleja en `references/metricas.md`, y el
  cambio de datos de entrada sube `motorVersion` (semver minor).

### Preguntas abiertas

Ninguna.

---

## Revisión 3: histórico real y gráfica de precio (2026-10-08)

Primera de tres fases del panel "Resumen" (las siguientes: panel "cara o barata" con precio
implícito, y gráficas de fundamentales; cada una con su propia revisión del spec).

### Qué cambia y por qué

La Revisión 2 asumía que TradingView no daba histórico diario. Sí lo da, por el canal de
gráficos que usa su propia web (WebSocket `data.tradingview.com`, sin clave). Comprobado el
2026-10-08: Nintendo 5.878 velas diarias desde 2001 (4 s), Iberdrola 6.000 desde 2003 (1 s).
Con él:

- El resultado gana una pestaña **Resumen** con la evolución del precio, para entender de
  un vistazo lo que hasta ahora eran números sueltos. La vista actual pasa a la pestaña
  **Detalle**, sin cambios.
- El motor calcula por fin MACD, volatilidad, caída máxima y pendiente de la media con datos
  reales, y deja de avisar de "Sin histórico de precios".

Es una fuente **no oficial** y más frágil que el scanner. Si falla, la app sigue como en la
Revisión 2: sin gráfica y con una sola barra de precio.

### Fuera de alcance (añade a los de arriba)

- El panel "cara o barata", el precio implícito y los pares del sector (fase 2).
- Gráficas de ingresos, beneficio y caja, y las explicaciones educativas de cada gráfica
  (fase 3).
- Velas japonesas, volumen, indicadores superpuestos distintos de las medias de 50 y 200
  sesiones, dibujar sobre la gráfica y comparar con otras acciones.
- Intradía: solo cierres diarios.
- Ajuste por dividendos: los precios vienen ajustados por splits, no por dividendos.
- Guardar el histórico en el historial de análisis: se vuelve a pedir (o se lee de caché).

### Criterios de aceptación

#### Pestañas

44. **Dado** un resultado de análisis (nuevo o del historial), **cuando** se abre, **entonces**
    veo dos pestañas, **Resumen** (la primera, abierta por defecto) y **Detalle**, que es la
    vista de la Revisión 2 sin cambios (cabecera, avisos, bloques, datos que faltan y
    botones).
45. **Dado** que cambio de pestaña, **cuando** vuelvo, **entonces** lo que estaba desplegado
    en Detalle sigue como lo dejé, y "Actualizar datos" actúa sobre las dos.

#### Gráfica de precio

46. **Dado** la pestaña Resumen, **cuando** hay histórico, **entonces** veo una línea con los
    cierres diarios del último año y, encima, un selector de periodo con 1M, 3M, 6M, 1A, 5A y
    Todo.
47. **Dado** el selector, **cuando** elijo un periodo, **entonces** la gráfica se redibuja con
    ese periodo. Si el histórico es más corto que el periodo, muestra todo lo que hay.
48. **Dado** la gráfica, **cuando** la miro, **entonces** el máximo y el mínimo de cierre del
    periodo elegido aparecen marcados con su valor y su fecha.
49. **Dado** la gráfica, **cuando** toco o arrastro sobre ella, **entonces** veo la fecha y el
    precio de ese día con su divisa.
50. **Dado** los interruptores "Media 50" y "Media 200", **cuando** los activo, **entonces** se
    superpone la media de ese número de sesiones; empiezan desactivados. Una media sin datos
    suficientes en el periodo no se dibuja (nunca se inventa).
51. **Dado** cualquier periodo, **cuando** hay muchos puntos, **entonces** la gráfica sigue
    fluida: se agrupan los puntos conservando máximos y mínimos de cada tramo.
52. **Dado** la gráfica, **cuando** la miro, **entonces** debajo pone "Datos de TradingView.
    Precios ajustados por splits, sin dividendos."
53. **Dado** que el histórico no se puede obtener (bloqueo, sin conexión o cambio de
    protocolo), **cuando** abro Resumen, **entonces** veo "No se ha podido cargar la gráfica"
    con "Reintentar", y Detalle funciona igual que antes, con el aviso de "Sin histórico de
    precios".
54. **Dado** que ya cargué la gráfica de una acción hace menos de 6 horas, **cuando** la abro,
    **entonces** sale de la caché sin hacer ninguna petición; "Actualizar datos" la vuelve a
    pedir.

#### Motor con histórico real

55. **Dado** un histórico de al menos 252 sesiones, **cuando** se analiza, **entonces** MACD,
    pendiente de la media de 200 sesiones y caída máxima tienen valor, y no aparece el aviso
    de "Sin histórico de precios" (sustituye al criterio 35).
56. **Dado** que el histórico falla durante un análisis, **cuando** termina, **entonces** el
    análisis se completa igualmente con la única barra del último cierre (como en la Revisión
    2) y con el aviso del criterio 35; un fallo del histórico nunca impide analizar.
57. **Dado** un histórico con huecos o velas incoherentes (máximo menor que el mínimo, cierre
    fuera del rango), **cuando** se procesa, **entonces** esas velas se descartan y, si queda
    menos de 2 sesiones, se trata como histórico no disponible.

### Decisiones y riesgos

- **Pestaña Resumen por defecto**: es el "dashboard general al entrar" que se pidió.
- **El histórico no se guarda en el historial de análisis**: el `AnalysisResult` ya guardado
  sigue igual y la gráfica se pide aparte. Abrir una entrada antigua sin conexión muestra el
  criterio 53 en Resumen y Detalle intacto.
- **Fuente no oficial**: el protocolo del WebSocket puede cambiar. Los tests usan una
  transcripción real guardada para detectarlo, y el fallo se aísla del análisis (criterio 56).
- **`motorVersion` pasa a 1.2.0**: cambian los datos de entrada de varias métricas.
- **Dependencia nueva**: `fl_chart` (solo en `presentation/`).

### Preguntas abiertas

Ninguna.

---

## Revisión 4: gráfica del día y de la última semana (2026-10-08)

### Qué cambia y por qué

La gráfica de la Revisión 3 empieza en 1 mes y solo usa cierres diarios. Para ver cómo se ha
movido la acción hoy y esta semana hacen falta velas intradía. El canal de gráficos de
TradingView las da con la misma conexión (comprobado el 2026-10-08 con Nintendo, Iberdrola y
Apple: velas de 5, 30 y 60 minutos, con la zona horaria de la bolsa y el retraso de los datos).
Esto sustituye la exclusión "Intradía: solo cierres diarios" de la Revisión 3.

### Fuera de alcance (añade a los de arriba)

- Periodos intradía a medida, otras resoluciones, velas japonesas y volumen.
- Mostrar en la hora de la bolsa las plazas cuya zona horaria no esté en la tabla de la app
  (se muestra la hora del dispositivo y se avisa).
- Antes y después de mercado, y datos en tiempo real: TradingView los da con retraso y así se
  muestran.
- Medias de 50 y 200 en 1D y 1S (son de sesiones diarias).

### Criterios de aceptación

58. **Dado** el selector de periodo, **cuando** lo veo, **entonces** empieza por **1D** y
    **1S**, seguidos de 1M, 3M, 6M, 1A, 5A y Todo; el periodo por defecto sigue siendo 1A.
59. **Dado** 1D, **cuando** lo elijo, **entonces** veo la línea de la última sesión de
    negociación en tramos de 5 minutos, con el eje en horas de la bolsa ("09:00", "10:00"...).
    Si hoy no hay mercado (fin de semana, festivo), es la última sesión que hubo, y el pie
    dice su fecha.
60. **Dado** 1S, **cuando** lo elijo, **entonces** veo las últimas 5 sesiones en tramos de
    30 minutos, pegadas unas a otras sin huecos de noche ni de fin de semana, con el día de
    cada sesión en el eje ("jue 8").
61. **Dado** 1D o 1S, **cuando** miro la gráfica, **entonces** el máximo y el mínimo del
    periodo aparecen marcados con su valor, su día y su hora.
62. **Dado** 1D o 1S, **cuando** toco o arrastro, **entonces** veo el día, la hora y el precio
    de ese punto con su divisa.
63. **Dado** 1D o 1S, **cuando** los elijo, **entonces** los interruptores de las medias no se
    muestran; al volver a un periodo largo, reaparecen como los dejé.
64. **Dado** que TradingView informa de retraso, **cuando** veo 1D o 1S, **entonces** el pie
    dice "Datos con 15 minutos de retraso" (los que indique). Las horas son las de la bolsa; si
    su zona horaria no se conoce, son las del dispositivo y el pie lo dice.
65. **Dado** que ya cargué 1D o 1S hace menos de 5 minutos, **cuando** los vuelvo a elegir,
    **entonces** salen de la caché; "Actualizar datos" los vuelve a pedir.
66. **Dado** que 1D o 1S no se pueden cargar, **cuando** los elijo, **entonces** veo "No se ha
    podido cargar la gráfica" con "Reintentar" solo en esa vista; los periodos largos siguen
    funcionando.
67. **Dado** una acción con una sola sesión disponible (cotización muy reciente o poco
    líquida), **cuando** elijo 1S, **entonces** veo las sesiones que haya, sin inventar las
    que faltan.

### Decisiones y riesgos

- **Sesiones por huecos, no por fechas**: una sesión es una racha de velas sin un hueco de más
  de 3 horas (la pausa de la comida de Tokio es de 1 hora). Así el corte no depende de la zona
  horaria.
- **Horas de la bolsa con una tabla de zonas** (Tokio, Madrid, Londres, Nueva York y las
  principales) con sus reglas de cambio de hora; una zona desconocida usa la del dispositivo.
- **En 1D y 1S el eje es el orden de las velas, no el tiempo**, para que las sesiones no
  dejen huecos (como hace la propia TradingView).
- **Caché de 5 minutos** para el intradía (los datos llegan con retraso de 15-20 minutos).

### Preguntas abiertas

Ninguna.

