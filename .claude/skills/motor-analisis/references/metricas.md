# Referencia de métricas

Fórmulas y escalas iniciales del motor. Las escalas son un punto de partida para empresas no financieras: calibrar con empresas reales conocidas. Si cambias un valor en el módulo de reglas, actualiza este documento.

Notación de escala: `valor→nota`, interpolación lineal entre puntos, saturación en los extremos. TTM = suma de los últimos 4 trimestres (si no hay 4, usar el último año fiscal).

## Índice
1. Indicadores técnicos (fórmulas)
2. Valoración
3. Salud financiera
4. Crecimiento y rentabilidad
5. Técnico (reglas)
6. Contexto
7. Señales de alarma

---

## 1. Indicadores técnicos (fórmulas)

Sobre cierres diarios en orden ascendente. Devuelven null si no hay suficientes datos.

- **SMA(n)**: media de los últimos n cierres.
- **EMA(n)**: semilla = SMA de los n primeros; después `EMA = cierre·k + EMA_anterior·(1−k)`, con `k = 2/(n+1)`.
- **RSI(14) de Wilder**: media de subidas y bajadas de los primeros 14 cambios; después `media = (media_anterior·13 + valor_actual)/14`. `RSI = 100 − 100/(1 + subidas/bajadas)`. Si no hay bajadas: 100 (o 50 si tampoco hay subidas). Requiere ≥ 15 cierres.
- **MACD(12, 26, 9)**: línea = EMA12 − EMA26; señal = EMA9 de la línea; histograma = línea − señal. Guardar también el histograma anterior. Requiere ≥ 35 cierres.
- **Pendiente SMA200**: SMA200 hoy / SMA200 hace 20 sesiones − 1.
- **Rentabilidad n sesiones**: cierre actual / cierre hace n − 1 (3 meses = 63, 12 meses = 252).
- **Volatilidad anualizada**: desviación típica muestral de rendimientos logarítmicos diarios (último año) × √252.
- **Caída máxima (1 año)**: mínimo de `cierre / máximo acumulado − 1`.
- **Máximo y mínimo de 52 semanas**: sobre las últimas 252 sesiones.

Si el histórico tiene < 200 sesiones (planes gratuitos o proveedores sin histórico diario), usar como respaldo SMA50, SMA200 y máximo/mínimo de 52 semanas que ofrezca el perfil de la API, y añadir aviso.

## 2. Valoración

| id | Métrica | Fórmula / origen | Escala | Perfiles |
|---|---|---|---|---|
| per | PER 12 meses | Perfil de la API; solo si > 0 | 8→9, 15→8, 25→5, 35→3, 50→1 | crecimiento ×0,3. Si beneficio ≤ 0: null con nota "No aplica" |
| peg | PEG | Perfil; solo si > 0 | 0,5→9, 1→8, 2→5, 3→2 | |
| ev_ebitda | EV/EBITDA | Perfil; solo si > 0 | 6→9, 10→7, 14→5, 20→3, 30→1 | financiera: 0 |
| p_fcf | Precio/FCF | Capitalización / FCF TTM (si FCF > 0) | 10→9, 15→8, 25→5, 40→2 | financiera: 0 |
| p_ventas | Precio/Ventas | Perfil | 2→9, 5→7, 10→4, 20→1 | solo crecimiento (peso 1,5) |
| p_vc | Precio/Valor contable | Perfil | 0,8→8, 1,5→6, 3→3 | solo financiera (peso 1,5) |

## 3. Salud financiera

| id | Métrica | Fórmula | Escala | Perfiles |
|---|---|---|---|---|
| deuda_ebitda | Deuda neta/EBITDA (peso 1,5) | (deuda total − caja) / EBITDA TTM; solo si EBITDA > 0 | −1→10, 0→9, 1→8, 2→7, 3→4, 4→2, 6→0 | financiera: 0 |
| deuda_patrimonio | Deuda/Patrimonio | Deuda total / patrimonio (si > 0) | 0,3→9, 1→7, 2→4, 3→2 | financiera: 0 |
| liquidez | Ratio de liquidez | Activo corriente / pasivo corriente | 0,7→2, 1→4, 1,5→7, 2→9 | financiera: 0 |
| cobertura_intereses | Cobertura de intereses | EBIT TTM / gastos financieros TTM | 1→0, 2→2, 5→6, 10→9, 20→10 | |
| fcf_positivo | Años con FCF positivo | Fracción de los últimos 5 años (mín. 3) con FCF > 0 | 0→1, 0,6→4, 0,8→7, 1→10 | |
| payout_fcf | Dividendo/FCF | Dividendos pagados / FCF último año | 0,3→9, 0,6→7, 0,9→3, 1,2→0 | solo dividendo (peso 1,5) |

Balance: usar el trimestral más reciente. Deuda total = deuda total reportada o, si falta, corto + largo plazo. Caja = caja e inversiones a corto plazo. FCF = flujo operativo − CAPEX.

## 4. Crecimiento y rentabilidad

| id | Métrica | Fórmula | Escala | Perfiles |
|---|---|---|---|---|
| ingresos_cagr3 | Crecimiento ingresos 3 años (peso 1,5) | `(ingresos_hoy / ingresos_hace_3)^(1/3) − 1` (solo con valores > 0) | −0,05→1, 0→3, 0,05→5, 0,1→7, 0,2→9, 0,3→10 | |
| ingresos_yoy | Crecimiento ingresos último año | Último año / anterior − 1 | igual que la anterior | |
| beneficio_cagr3 | Crecimiento beneficio 3 años | CAGR del beneficio neto | −0,05→1, 0→3, 0,05→5, 0,1→7, 0,2→9 | crecimiento ×0,3 |
| margen_operativo | Margen operativo | Resultado operativo / ingresos | 0→1, 0,05→3, 0,1→5, 0,2→8, 0,3→10 | financiera: 0 |
| margen_tendencia | Cambio margen operativo 3 años | Margen hoy − margen hace 3 años | −0,05→2, 0→5, 0,03→8, 0,06→9 | financiera: 0 |
| margen_bruto | Margen bruto | Beneficio bruto / ingresos | 0,2→2, 0,4→5, 0,6→8, 0,75→10 | solo crecimiento (peso 1,5) |
| roic | ROIC (peso 1,5) | EBIT·(1 − tipo impositivo) / (deuda + patrimonio − caja). Tipo = impuestos / beneficio antes de impuestos; si es < 0 o > 50 %, usar 21 % | 0→1, 0,05→3, 0,1→6, 0,15→8, 0,25→10 | financiera: 0 |
| roe | ROE | Beneficio TTM / patrimonio (si > 0) | 0,05→2, 0,1→5, 0,15→8, 0,2→10 | solo financiera (peso 2) |
| dilucion | Variación de acciones (peso 0,5) | CAGR de acciones en circulación 3 años | −0,03→9, 0→7, 0,03→4, 0,06→1 | |

## 5. Técnico (reglas)

| id | Métrica | Escala |
|---|---|---|
| precio_sma200 (peso 1,5) | Precio / SMA200 − 1 | −0,2→1, −0,05→3, 0→5, 0,05→8, 0,15→9, 0,25→6, 0,4→3 |
| pendiente_sma200 | Pendiente SMA200 | −0,05→1, 0→4, 0,02→7, 0,05→9 |
| rsi | RSI(14) | 20→4, 30→6, 45→9, 60→9, 70→6, 80→3 |
| macd | Histograma MACD | ≥ 0 y subiendo → 9; ≥ 0 y bajando → 6; < 0 y subiendo → 4; < 0 y bajando → 2 |
| dist_maximo (peso 0,5) | Precio / máximo 52 semanas − 1 | −0,5→2, −0,3→4, −0,1→7, 0→8 |

## 6. Contexto

| id | Métrica | Escala |
|---|---|---|
| sorpresas_bpa | Trimestres (de los 4 últimos) con BPA real > estimado | 0→2, 1→4, 2→6, 3→8, 4→10 |
| potencial_analistas (peso 0,5) | Precio objetivo / precio − 1 | −0,1→2, 0→4, 0,1→6, 0,25→8 |
| beta (peso 0,5) | Beta | 0,8→8, 1,2→6, 1,8→3, 2,5→1 |
| caida_maxima (peso 0,5) | Caída máxima 1 año | −0,6→1, −0,4→3, −0,25→6, −0,1→9 |

## 7. Señales de alarma (avisos)

- Beneficio neto sube 2 años seguidos mientras el FCF baja 2 años seguidos.
- Margen operativo trimestral cae 3 trimestres consecutivos.
- Acciones en circulación crecen > 5 % anual (dilución).
- Deuda neta/EBITDA > 4.
- Patrimonio neto negativo (ROE y deuda/patrimonio no interpretables).
- Rentabilidad por dividendo > 7 % (el mercado duda de su sostenibilidad).

## Respaldo con ratios del proveedor (motor 1.1.0)

Cuando las cuentas no permiten calcular una métrica, el motor usa el ratio que da el
proveedor (`CompanyOverview`), siempre como **segunda opción**: lo calculado con las
cuentas prevalece. Con TradingView las cuentas por periodo son parciales y, además, sus
escalares están en USD y las series en la moneda de reporte, así que estos ratios (sin
unidad) evitan mezclar monedas.

| id | Calculado con cuentas | Respaldo (`CompanyOverview`) |
|---|---|---|
| `p_fcf` | capitalización / FCF TTM | `priceToFreeCashFlow` |
| `deuda_ebitda` | (deuda − caja) / EBITDA TTM | `netDebtToEbitda` |
| `deuda_patrimonio` | deuda / patrimonio | `debtToEquity` (solo si > 0) |
| `liquidez` | activo corriente / pasivo corriente | `currentRatio` (solo si > 0) |
| `margen_operativo` | resultado operativo / ingresos TTM | `operatingMargin` |
| `margen_bruto` | beneficio bruto / ingresos TTM | `grossMargin` |
| `roic` | NOPAT / capital invertido | `returnOnInvestedCapital` |
| `roe` | beneficio neto TTM / patrimonio | `returnOnEquity` |
| `rsi` | RSI de 14 sesiones del histórico | `rsi14` |

Si no hay histórico diario (una sola barra), el aviso es "Sin histórico de precios", y
MACD, pendiente de la SMA200 y caída máxima quedan "sin dato".
