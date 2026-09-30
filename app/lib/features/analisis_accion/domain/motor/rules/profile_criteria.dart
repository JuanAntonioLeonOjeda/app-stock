// Criterios de detección del perfil de empresa (orden: financiera →
// crecimiento → dividendo → general).

/// Palabras (en minúsculas) del sector o la industria que marcan una
/// empresa financiera: banca, seguros o servicios financieros.
const financialKeywords = [
  'financ',
  'bank',
  'insurance',
  'banco',
  'seguro',
  'capital markets',
  'asset management',
];

/// Crecimiento anual de ingresos (3 años) a partir del cual es `crecimiento`.
const growthProfileMinRevenueCagr = 0.2;

/// Rentabilidad por dividendo a partir de la cual es `dividendo`.
const dividendProfileMinYield = 0.03;
