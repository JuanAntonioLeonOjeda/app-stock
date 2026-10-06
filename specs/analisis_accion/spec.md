# Spec: analisis_accion

> Estado: cerrada (2026-09-30). Siguiente paso: `plan.md`.

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
