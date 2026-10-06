/// Campos que se piden al scanner de TradingView, en el orden en que se
/// devuelven. Un nombre desconocido llega como `null` sin error, así que un
/// test comprueba cada nombre contra una respuesta real guardada.
///
/// Los escalares de fundamentales (`net_debt`, `ebit_ttm`, `total_equity_fq`...)
/// vienen convertidos a USD; las series `*_h` (más reciente primero) vienen en
/// la moneda de reporte de la empresa. Los ratios y porcentajes no tienen
/// unidad.
const tradingViewFields = <String>[
  // Perfil y precio.
  'description',
  'type',
  'sector',
  'industry',
  'currency',
  'close',
  'open',
  'high',
  'low',
  'volume',
  // Epoch en segundos del último cierre.
  'time',
  'total_shares_outstanding',
  // Valoración.
  'price_earnings_ttm',
  'price_earnings_growth_ttm',
  'price_book_fq',
  'price_sales_current',
  'price_free_cash_flow_ttm',
  'enterprise_value_ebitda_ttm',
  // Dividendo (porcentaje) y riesgo.
  'dividends_yield',
  'beta_1_year',
  // Técnico, ya calculado por el proveedor.
  'RSI',
  'SMA50',
  'SMA200',
  'price_52_week_high',
  'price_52_week_low',
  // Rentabilidad y solidez (porcentajes y ratios).
  'return_on_equity',
  'return_on_invested_capital',
  'operating_margin_ttm',
  'gross_margin_ttm',
  'debt_to_equity_fq',
  'current_ratio_fq',
  // Para deuda neta / EBITDA (ambos en USD, así que el cociente no tiene unidad).
  'net_debt_fq',
  'ebitda_ttm',
  // Fechas de cierre del último ejercicio y trimestre publicados (epoch).
  'fiscal_period_end_fy',
  'fiscal_period_end_current',
  // Series anuales (20 años) y trimestrales (32), moneda de reporte.
  'total_revenue_fy_h',
  'gross_profit_fy_h',
  'ebitda_fy_h',
  'net_income_fy_h',
  'free_cash_flow_fy_h',
  'total_debt_fy_h',
  'total_revenue_fq_h',
  'gross_profit_fq_h',
  'ebitda_fq_h',
  'net_income_fq_h',
  'free_cash_flow_fq_h',
  'total_debt_fq_h',
];
