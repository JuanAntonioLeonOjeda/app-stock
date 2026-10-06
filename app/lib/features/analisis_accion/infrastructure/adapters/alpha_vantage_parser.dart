// JSON de Alpha Vantage (ya validado por decodeAlphaVantageBody) → entidades
// del dominio. Normaliza aquí todas las rarezas del proveedor para que el
// motor no las conozca: números como texto, "None"/"-"/vacío → null, gastos
// en positivo, deuda y caja con campos de respaldo.

import 'package:stock_app/features/analisis_accion/domain/entities/balance_sheet.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/cash_flow_statement.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/company_overview.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/daily_bar.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/earnings_report.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/income_statement.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/symbol_match.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';

typedef Json = Map<String, Object?>;

/// Informes anuales y trimestrales de un mismo tipo.
typedef Reports<T> = ({List<T> annual, List<T> quarterly});

CompanyOverview parseOverview(Json json) => CompanyOverview(
  symbol: _requiredText(json, 'Symbol'),
  name: _requiredText(json, 'Name'),
  sector: _text(json['Sector']),
  industry: _text(json['Industry']),
  currency: _text(json['Currency']),
  latestQuarter: _date(json['LatestQuarter']),
  marketCapitalization: _number(json['MarketCapitalization']),
  sharesOutstanding: _number(json['SharesOutstanding']),
  peRatio: _number(json['PERatio']),
  forwardPe: _number(json['ForwardPE']),
  pegRatio: _number(json['PEGRatio']),
  priceToBook: _number(json['PriceToBookRatio']),
  priceToSales: _number(json['PriceToSalesRatioTTM']),
  evToEbitda: _number(json['EVToEBITDA']),
  beta: _number(json['Beta']),
  dividendYield: _number(json['DividendYield']),
  analystTargetPrice: _number(json['AnalystTargetPrice']),
  movingAverage50: _number(json['50DayMovingAverage']),
  movingAverage200: _number(json['200DayMovingAverage']),
  week52High: _number(json['52WeekHigh']),
  week52Low: _number(json['52WeekLow']),
);

/// Histórico diario (en el orden de la respuesta; `StockData` lo ordena).
List<DailyBar> parseDailySeries(Json json) {
  final series = _object(json, 'Time Series (Daily)');
  return [
    for (final MapEntry(key: date, value: day) in series.entries)
      _dailyBar(date, _asObject(day, date)),
  ];
}

DailyBar _dailyBar(String date, Json day) => DailyBar(
  date: _requiredDate(date),
  open: _requiredNumber(day, '1. open'),
  high: _requiredNumber(day, '2. high'),
  low: _requiredNumber(day, '3. low'),
  close: _requiredNumber(day, '4. close'),
  volume: _requiredNumber(day, '5. volume').round(),
);

Reports<IncomeStatement> parseIncomeStatements(Json json) =>
    _reports(json, _incomeStatement);

IncomeStatement _incomeStatement(Json report) => IncomeStatement(
  fiscalDateEnding: _requiredDate(report['fiscalDateEnding']),
  reportedCurrency: _text(report['reportedCurrency']),
  totalRevenue: _number(report['totalRevenue']),
  grossProfit: _number(report['grossProfit']),
  operatingIncome: _number(report['operatingIncome']),
  ebit: _number(report['ebit']),
  ebitda: _number(report['ebitda']),
  interestExpense: _positive(_number(report['interestExpense'])),
  incomeBeforeTax: _number(report['incomeBeforeTax']),
  // Sin normalizar el signo: un impuesto negativo es real (devolución).
  incomeTaxExpense: _number(report['incomeTaxExpense']),
  netIncome: _number(report['netIncome']),
);

Reports<BalanceSheet> parseBalanceSheets(Json json) =>
    _reports(json, _balanceSheet);

BalanceSheet _balanceSheet(Json report) => BalanceSheet(
  fiscalDateEnding: _requiredDate(report['fiscalDateEnding']),
  reportedCurrency: _text(report['reportedCurrency']),
  totalCurrentAssets: _number(report['totalCurrentAssets']),
  totalCurrentLiabilities: _number(report['totalCurrentLiabilities']),
  totalShareholderEquity: _number(report['totalShareholderEquity']),
  totalDebt: _totalDebt(report),
  cashAndShortTermInvestments:
      _number(report['cashAndShortTermInvestments']) ??
      _number(report['cashAndCashEquivalentsAtCarryingValue']),
  sharesOutstanding: _number(report['commonStockSharesOutstanding']),
);

/// `shortLongTermDebtTotal`; si falta, corto + largo plazo (los que haya).
double? _totalDebt(Json report) {
  final total = _number(report['shortLongTermDebtTotal']);
  if (total != null) return total;
  final parts = [
    _number(report['shortTermDebt']),
    _number(report['longTermDebt']),
  ].whereType<double>();
  return parts.isEmpty ? null : parts.reduce((a, b) => a + b);
}

Reports<CashFlowStatement> parseCashFlows(Json json) =>
    _reports(json, _cashFlowStatement);

CashFlowStatement _cashFlowStatement(Json report) => CashFlowStatement(
  fiscalDateEnding: _requiredDate(report['fiscalDateEnding']),
  reportedCurrency: _text(report['reportedCurrency']),
  operatingCashflow: _number(report['operatingCashflow']),
  capitalExpenditures: _positive(_number(report['capitalExpenditures'])),
  dividendPayout: _positive(
    _number(report['dividendPayout']) ??
        _number(report['dividendPayoutCommonStock']),
  ),
);

/// Resultados trimestrales.
List<EarningsReport> parseEarnings(Json json) => [
  for (final report in _objectList(json, 'quarterlyEarnings'))
    EarningsReport(
      fiscalDateEnding: _requiredDate(report['fiscalDateEnding']),
      reportedDate: _date(report['reportedDate']),
      reportedEps: _number(report['reportedEPS']),
      estimatedEps: _number(report['estimatedEPS']),
    ),
];

List<SymbolMatch> parseSymbolSearch(Json json) => [
  for (final match in _objectList(json, 'bestMatches'))
    SymbolMatch(
      symbol: _requiredText(match, '1. symbol'),
      name: _requiredText(match, '2. name'),
      region: _text(match['4. region']) ?? '',
      currency: _text(match['8. currency']) ?? '',
      matchScore: _number(match['9. matchScore']) ?? 0,
    ),
];

Reports<T> _reports<T>(Json json, T Function(Json report) parse) => (
  annual: [for (final r in _objectList(json, 'annualReports')) parse(r)],
  quarterly: [for (final r in _objectList(json, 'quarterlyReports')) parse(r)],
);

// --- Lectura segura de campos --------------------------------------------

const _absentMarkers = {'', 'none', '-', 'null', 'n/a'};

/// Texto del proveedor → número. `null` si falta o no es un número.
double? _number(Object? raw) {
  if (raw is num) return raw.toDouble();
  if (raw is! String) return null;
  final text = raw.trim();
  if (_absentMarkers.contains(text.toLowerCase())) return null;
  final value = double.tryParse(text);
  return value == null || value.isNaN || value.isInfinite ? null : value;
}

double? _positive(double? value) => value?.abs();

String? _text(Object? raw) {
  if (raw is! String) return null;
  final text = raw.trim();
  return _absentMarkers.contains(text.toLowerCase()) ? null : text;
}

DateTime? _date(Object? raw) {
  final text = _text(raw);
  return text == null ? null : DateTime.tryParse(text);
}

String _requiredText(Json json, String key) =>
    _text(json[key]) ?? (throw InvalidResponseException('Falta "$key"'));

double _requiredNumber(Json json, String key) =>
    _number(json[key]) ?? (throw InvalidResponseException('Falta "$key"'));

DateTime _requiredDate(Object? raw) =>
    _date(raw) ?? (throw InvalidResponseException('Fecha no válida: $raw'));

Json _object(Json json, String key) => _asObject(json[key], key);

Json _asObject(Object? value, String key) {
  if (value is Map<String, Object?>) return value;
  throw InvalidResponseException('"$key" no es un objeto');
}

List<Json> _objectList(Json json, String key) {
  final value = json[key];
  if (value is! List<Object?>) {
    throw InvalidResponseException('"$key" no es una lista');
  }
  return [for (final item in value) _asObject(item, key)];
}
