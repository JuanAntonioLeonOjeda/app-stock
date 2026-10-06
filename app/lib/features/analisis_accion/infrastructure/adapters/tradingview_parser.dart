// JSON de TradingView → entidades del dominio. Normaliza aquí todas las
// rarezas del proveedor para que el motor no las conozca: porcentajes → fracción,
// series sin fechas, escalares en USD frente a series en la moneda de reporte
// y datos ausentes → null.

import 'dart:convert';

import 'package:stock_app/features/analisis_accion/domain/entities/balance_sheet.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/cash_flow_statement.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/company_overview.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/daily_bar.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/income_statement.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/stock_data.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/symbol_match.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/tradingview_fields.dart';

typedef _Json = Map<String, Object?>;

/// Máximo de coincidencias que se muestran de una búsqueda.
const _maxSearchResults = 15;

/// Puntuación por tipo de cotización: la bolsa de origen antes que las demás
/// bolsas y los certificados de depositario (ADR).
const _primaryListingScore = 1.0;
const _secondaryListingScore = 0.8;
const _depositaryReceiptScore = 0.5;

/// Resta por posición, para conservar el orden que devuelve el proveedor.
const _positionPenalty = 0.001;

/// Coincidencias de la búsqueda de símbolos, de más a menos relevante. El
/// símbolo es `BOLSA:TICKER` (p. ej. `TSE:7974`), que es lo que pide el
/// scanner.
List<SymbolMatch> parseTradingViewSearch(String body) {
  final symbols = _list(_decodeObject(body), 'symbols');
  final matches = <SymbolMatch>[];
  for (final item in symbols) {
    final match = _symbolMatch(_asObject(item, 'symbols'), matches.length);
    if (match != null) matches.add(match);
  }
  // La penalización por posición hace únicas las puntuaciones: el orden es
  // determinista aunque `sort` no sea estable.
  matches.sort((a, b) => b.matchScore.compareTo(a.matchScore));
  return matches.take(_maxSearchResults).toList();
}

SymbolMatch? _symbolMatch(_Json item, int position) {
  final ticker = _text(item['symbol']);
  final exchange = _text(item['exchange']);
  final type = _text(item['type']);
  if (ticker == null || exchange == null) return null;
  if (type != 'stock' && type != 'dr') return null;
  final score = type == 'dr'
      ? _depositaryReceiptScore
      : item['is_primary_listing'] == true
      ? _primaryListingScore
      : _secondaryListingScore;
  return SymbolMatch(
    symbol: '$exchange:$ticker',
    name: _stripHighlight(_text(item['description']) ?? ticker),
    region: _text(item['country']) ?? exchange,
    currency: _text(item['currency_code']) ?? '',
    matchScore: score - position * _positionPenalty,
  );
}

/// El buscador marca las palabras encontradas con `<em>…</em>`.
String _stripHighlight(String text) => text.replaceAll(RegExp('</?em>'), '');

/// Datos de una acción a partir de la respuesta del scanner.
///
/// Lanza `NotFoundException` si el símbolo no tiene fila o no tiene precio, e
/// `InvalidResponseException` si la forma de la respuesta no es la esperada.
StockData parseTradingViewScan(String body, {required DateTime fetchedAt}) {
  final row = _Row.fromBody(body);
  final price = row.number('close');
  final lastCloseEpoch = row.number('time');
  if (price == null || lastCloseEpoch == null) {
    throw const NotFoundException('Sin precio para el símbolo');
  }
  final currency = row.text('currency');
  // La moneda de reporte no viene con las series. En una cotización local es
  // la de cotización; en un ADR no se puede saber, y se deja sin indicar
  // para no declarar una moneda que podría ser falsa.
  final reportedCurrency = row.text('type') == 'stock' ? currency : null;
  final annualEnd = row.epochDate('fiscal_period_end_fy');
  final quarterEnd = row.epochDate('fiscal_period_end_current');
  return StockData(
    overview: _overview(row, symbol: row.symbol, currency: currency),
    dailyBars: [_lastBar(row, price, lastCloseEpoch)],
    annualIncome: _incomeStatements(
      row,
      suffix: 'fy',
      lastEnd: annualEnd,
      monthsPerPeriod: 12,
      currency: reportedCurrency,
    ),
    quarterlyIncome: _incomeStatements(
      row,
      suffix: 'fq',
      lastEnd: quarterEnd,
      monthsPerPeriod: 3,
      currency: reportedCurrency,
    ),
    annualBalance: _balanceSheets(
      row,
      suffix: 'fy',
      lastEnd: annualEnd,
      monthsPerPeriod: 12,
      currency: reportedCurrency,
    ),
    quarterlyBalance: _balanceSheets(
      row,
      suffix: 'fq',
      lastEnd: quarterEnd,
      monthsPerPeriod: 3,
      currency: reportedCurrency,
    ),
    annualCashFlow: _cashFlows(
      row,
      suffix: 'fy',
      lastEnd: annualEnd,
      monthsPerPeriod: 12,
      currency: reportedCurrency,
    ),
    quarterlyCashFlow: _cashFlows(
      row,
      suffix: 'fq',
      lastEnd: quarterEnd,
      monthsPerPeriod: 3,
      currency: reportedCurrency,
    ),
    // El proveedor no da BPA estimado: sin sorpresas de resultados.
    quarterlyEarnings: const [],
    fetchedAt: fetchedAt,
  );
}

CompanyOverview _overview(
  _Row row, {
  required String symbol,
  required String? currency,
}) => CompanyOverview(
  symbol: symbol,
  name: row.text('description') ?? symbol,
  sector: row.text('sector'),
  industry: row.text('industry'),
  currency: currency,
  latestQuarter: row.epochDate('fiscal_period_end_current'),
  // La capitalización del proveedor está en USD, no en la moneda del precio:
  // no se usa. Las acciones en circulación sí son un recuento.
  marketCapitalization: null,
  sharesOutstanding: row.number('total_shares_outstanding'),
  peRatio: row.number('price_earnings_ttm'),
  forwardPe: null,
  pegRatio: row.number('price_earnings_growth_ttm'),
  priceToBook: row.number('price_book_fq'),
  priceToSales: row.number('price_sales_current'),
  evToEbitda: row.number('enterprise_value_ebitda_ttm'),
  beta: row.number('beta_1_year'),
  dividendYield: row.fraction('dividends_yield'),
  analystTargetPrice: null,
  movingAverage50: row.number('SMA50'),
  movingAverage200: row.number('SMA200'),
  week52High: row.number('price_52_week_high'),
  week52Low: row.number('price_52_week_low'),
  priceToFreeCashFlow: row.number('price_free_cash_flow_ttm'),
  returnOnEquity: row.fraction('return_on_equity'),
  returnOnInvestedCapital: row.fraction('return_on_invested_capital'),
  netDebtToEbitda: _ratio(row.number('net_debt_fq'), row.number('ebitda_ttm')),
  debtToEquity: row.number('debt_to_equity_fq'),
  currentRatio: row.number('current_ratio_fq'),
  operatingMargin: row.fraction('operating_margin_ttm'),
  grossMargin: row.fraction('gross_margin_ttm'),
  rsi14: row.number('RSI'),
);

/// Cociente solo con denominador > 0 (un EBITDA negativo no da un ratio).
double? _ratio(double? numerator, double? denominator) {
  if (numerator == null || denominator == null || denominator <= 0) {
    return null;
  }
  return numerator / denominator;
}

/// El proveedor no da histórico diario: el último cierre es la única barra.
DailyBar _lastBar(_Row row, double close, double epochSeconds) => DailyBar(
  date: _epochToDate(epochSeconds),
  open: row.number('open') ?? close,
  high: row.number('high') ?? close,
  low: row.number('low') ?? close,
  close: close,
  volume: row.number('volume')?.round() ?? 0,
);

List<IncomeStatement> _incomeStatements(
  _Row row, {
  required String suffix,
  required DateTime? lastEnd,
  required int monthsPerPeriod,
  required String? currency,
}) {
  final revenue = row.series('total_revenue_${suffix}_h');
  final grossProfit = row.series('gross_profit_${suffix}_h');
  final ebitda = row.series('ebitda_${suffix}_h');
  final netIncome = row.series('net_income_${suffix}_h');
  return [
    for (final (i, end) in _periods(lastEnd, monthsPerPeriod, [
      revenue,
      grossProfit,
      ebitda,
      netIncome,
    ]))
      IncomeStatement(
        fiscalDateEnding: end,
        reportedCurrency: currency,
        totalRevenue: revenue.at(i),
        grossProfit: grossProfit.at(i),
        // El proveedor no da resultado operativo, EBIT, intereses ni
        // impuestos por periodo: el motor usa sus ratios ya calculados.
        operatingIncome: null,
        ebit: null,
        ebitda: ebitda.at(i),
        interestExpense: null,
        incomeBeforeTax: null,
        incomeTaxExpense: null,
        netIncome: netIncome.at(i),
      ),
  ];
}

List<BalanceSheet> _balanceSheets(
  _Row row, {
  required String suffix,
  required DateTime? lastEnd,
  required int monthsPerPeriod,
  required String? currency,
}) {
  final debt = row.series('total_debt_${suffix}_h');
  return [
    for (final (i, end) in _periods(lastEnd, monthsPerPeriod, [debt]))
      BalanceSheet(
        fiscalDateEnding: end,
        reportedCurrency: currency,
        totalCurrentAssets: null,
        totalCurrentLiabilities: null,
        totalShareholderEquity: null,
        totalDebt: debt.at(i),
        cashAndShortTermInvestments: null,
        sharesOutstanding: null,
      ),
  ];
}

List<CashFlowStatement> _cashFlows(
  _Row row, {
  required String suffix,
  required DateTime? lastEnd,
  required int monthsPerPeriod,
  required String? currency,
}) {
  final freeCashFlow = row.series('free_cash_flow_${suffix}_h');
  return [
    for (final (i, end) in _periods(lastEnd, monthsPerPeriod, [freeCashFlow]))
      CashFlowStatement(
        fiscalDateEnding: end,
        reportedCurrency: currency,
        // El proveedor solo da el flujo de caja libre ya restado: se guarda
        // como flujo operativo con CAPEX 0, de modo que FCF = flujo − 0.
        operatingCashflow: freeCashFlow.at(i),
        capitalExpenditures: freeCashFlow.at(i) == null ? null : 0,
        dividendPayout: null,
      ),
  ];
}

/// Posición y fecha de cierre de los periodos para los que hay algún dato.
/// Sin fecha de cierre no se puede fechar ninguno.
List<(int, DateTime)> _periods(
  DateTime? lastEnd,
  int monthsPerPeriod,
  List<_Series> series,
) {
  if (lastEnd == null) return const [];
  final length = series.fold<int>(
    0,
    (max, s) => s.length > max ? s.length : max,
  );
  return [
    for (var i = 0; i < length; i++)
      if (series.any((s) => s.at(i) != null))
        (i, _periodEnd(lastEnd, i, monthsPerPeriod)),
  ];
}

/// Fin del periodo [index] (0 = el último publicado), restando
/// [monthsPerPeriod] meses por posición.
DateTime _periodEnd(DateTime lastEnd, int index, int monthsPerPeriod) {
  final monthIndex =
      lastEnd.year * 12 + (lastEnd.month - 1) - index * monthsPerPeriod;
  final year = monthIndex ~/ 12;
  final month = monthIndex % 12 + 1;
  final lastDayOfMonth = DateTime.utc(year, month + 1, 0).day;
  return DateTime.utc(
    year,
    month,
    lastEnd.day < lastDayOfMonth ? lastEnd.day : lastDayOfMonth,
  );
}

DateTime _epochToDate(double epochSeconds) {
  final moment = DateTime.fromMillisecondsSinceEpoch(
    (epochSeconds * 1000).round(),
    isUtc: true,
  );
  return DateTime.utc(moment.year, moment.month, moment.day);
}

/// Serie de valores de un campo `*_h`, del más reciente al más antiguo.
class _Series {
  const _Series(this._values);

  final List<double?> _values;

  int get length => _values.length;

  double? at(int index) => index < _values.length ? _values[index] : null;
}

/// Fila del scanner: los valores por nombre de campo.
class _Row {
  const _Row._(this.symbol, this._values);

  factory _Row.fromBody(String body) {
    final data = _list(_decodeObject(body), 'data');
    if (data.isEmpty) {
      throw const NotFoundException('Sin filas en la respuesta');
    }
    final row = _asObject(data.first, 'data');
    final symbol = row['s'];
    final values = row['d'];
    if (symbol is! String || values is! List<Object?>) {
      throw const InvalidResponseException('Fila sin "s" o "d"');
    }
    if (values.length != tradingViewFields.length) {
      throw InvalidResponseException(
        '${values.length} valores para ${tradingViewFields.length} campos',
      );
    }
    return _Row._(symbol, {
      for (var i = 0; i < values.length; i++) tradingViewFields[i]: values[i],
    });
  }

  /// Símbolo completo de la fila, `BOLSA:TICKER`.
  final String symbol;
  final Map<String, Object?> _values;

  String? text(String field) => _text(_values[field]);

  double? number(String field) => _number(_values[field], field);

  /// Un porcentaje del proveedor (17 = 17 %) como fracción (0,17).
  double? fraction(String field) {
    final percent = number(field);
    return percent == null ? null : percent / 100;
  }

  DateTime? epochDate(String field) {
    final epoch = number(field);
    return epoch == null ? null : _epochToDate(epoch);
  }

  _Series series(String field) {
    final value = _values[field];
    if (value == null) return const _Series([]);
    if (value is! List<Object?>) {
      throw InvalidResponseException('"$field" no es una lista');
    }
    return _Series([for (final item in value) _number(item, field)]);
  }
}

_Json _decodeObject(String body) {
  final Object? decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException {
    throw const InvalidResponseException('La respuesta no es JSON');
  }
  return _asObject(decoded, 'respuesta');
}

_Json _asObject(Object? value, String name) {
  if (value is! Map<String, Object?>) {
    throw InvalidResponseException('"$name" no es un objeto');
  }
  return value;
}

List<Object?> _list(_Json json, String key) {
  final value = json[key];
  if (value is! List<Object?>) {
    throw InvalidResponseException('"$key" no es una lista');
  }
  return value;
}

String? _text(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

double? _number(Object? value, [String field = 'valor']) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  throw InvalidResponseException('"$field" no es un número');
}
