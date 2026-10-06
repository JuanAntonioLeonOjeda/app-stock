// Umbrales y textos de los avisos. Cada texto va junto a su umbral para que
// no se desincronicen: si cambias un número, cambia también su texto.

/// Crecimiento anual de acciones en circulación a partir del cual se avisa.
const dilutionAlarmMin = 0.05;
const dilutionAlarmText =
    'Las acciones en circulación crecen más de un 5 % anual: dilución para '
    'el accionista.';

/// Deuda neta/EBITDA a partir del cual se avisa.
const netDebtToEbitdaAlarmMin = 4.0;
const netDebtToEbitdaAlarmText = 'La deuda neta supera 4 veces el EBITDA.';

/// Rentabilidad por dividendo a partir de la cual se avisa.
const dividendYieldAlarmMin = 0.07;
const dividendYieldAlarmText =
    'Rentabilidad por dividendo superior al 7 %: el mercado duda de que sea '
    'sostenible.';

/// Diferencia máxima tolerada entre la capitalización y precio × acciones.
const marketCapMismatchMax = 0.1;
const marketCapMismatchText =
    'La capitalización no cuadra con precio × acciones (diferencia superior '
    'al 10 %): revisa los datos.';

const profitUpCashDownText =
    'El beneficio neto sube desde hace dos años mientras el flujo de caja '
    'libre baja: el beneficio podría no estar convirtiéndose en caja.';

const fallingQuarterlyMarginText =
    'El margen operativo trimestral lleva tres trimestres seguidos cayendo.';

const negativeEquityText =
    'Patrimonio neto negativo: el ROE y la deuda/patrimonio no son '
    'interpretables.';

const noPriceHistoryText =
    'Sin histórico de precios: indicadores técnicos limitados. El RSI, las '
    'medias y el máximo de 52 semanas los calcula el proveedor.';

const shortHistoryText =
    'Histórico de precios inferior a 200 sesiones: las medias y el máximo de '
    '52 semanas se toman del perfil del proveedor.';

const stalePriceText =
    'El último cierre tiene más de 7 días: los precios están desactualizados.';

const staleQuarterText = 'El último informe trimestral tiene más de 6 meses.';

const verdictCappedByHealthText =
    'Veredicto limitado a neutral por una salud financiera débil (nota '
    'inferior a 4): una empresa frágil puede seguir abaratándose.';

const earningsSoonText =
    'Probablemente publique resultados en los próximos 14 días (estimación).';

String currencyMismatchText(String reportCurrency, String quoteCurrency) =>
    'Los estados financieros están en $reportCurrency y la cotización en '
    '$quoteCurrency: los ratios que mezclan precio y balance pueden no ser '
    'comparables.';
