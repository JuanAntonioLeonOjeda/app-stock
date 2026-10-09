// Cortes del veredicto, de la confianza y de antigüedad de los datos.

/// Nota global mínima para `favorable`.
const favorableMinScore = 7.0;

/// Nota global mínima para `neutral` (por debajo, `desfavorable`).
const neutralMinScore = 5.0;

/// Con menos bloques con nota, el veredicto es `datos insuficientes`.
const minScoredBlocks = 3;

/// Con la salud por debajo de esta nota, el veredicto máximo es `neutral`.
const healthCapScore = 4.0;

/// Cobertura ponderada mínima (y los 5 bloques con nota) para confianza alta.
const highConfidenceMinCoverage = 0.8;

/// Cobertura ponderada mínima para confianza media.
const mediumConfidenceMinCoverage = 0.6;

/// Con precios más antiguos, la confianza es siempre baja.
const maxPriceAge = Duration(days: 7);

/// Último informe trimestral más antiguo que esto → aviso.
const maxQuarterAge = Duration(days: 183);

/// Por debajo de estas sesiones, las medias y máximos se toman del perfil.
const minSessionsForOwnAverages = 200;

/// Estimación de la próxima publicación de resultados: última + 91 días.
const estimatedEarningsInterval = Duration(days: 91);

/// Se avisa si la próxima publicación estimada cae dentro de esta ventana.
const earningsSoonWindow = Duration(days: 14);
