/// Pasos de la obtención de datos de una acción, en el orden en que se
/// ejecutan. La posición en [FetchStep.values] da el "3 de 6" del progreso.
enum FetchStep {
  overview,
  dailyHistory,
  incomeStatement,
  balanceSheet,
  cashFlow,
  earnings,
}
