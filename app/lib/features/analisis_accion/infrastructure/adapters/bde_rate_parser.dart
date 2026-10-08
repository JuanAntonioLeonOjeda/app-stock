// CSV oficial de tipos de cambio del Banco de España (`tc_1_1.csv`): una
// columna por moneda y una fila por día. Republica los tipos de referencia del
// BCE con un día de retraso.

import 'package:stock_app/features/analisis_accion/domain/entities/exchange_rate_series.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';

const _months = {
  'ENE': 1,
  'FEB': 2,
  'MAR': 3,
  'ABR': 4,
  'MAY': 5,
  'JUN': 6,
  'JUL': 7,
  'AGO': 8,
  'SEP': 9,
  'OCT': 10,
  'NOV': 11,
  'DIC': 12,
};

/// Una fila de datos empieza por la fecha: `"04 ENE 1999",1.1789,...`.
final _dataRow = RegExp(r'^"(\d{2}) ([A-Z]{3}) (\d{4})"');

/// Tipos de [currency] frente al euro a partir del texto del CSV (ya
/// decodificado: el archivo viene en latin-1).
///
/// Lanza `InvalidResponseException` si no parece el CSV esperado y
/// `NotFoundException` si no tiene columna para la moneda.
ExchangeRateSeries parseBdeRates(String csv, String currency) {
  final lines = csv.split(RegExp(r'\r?\n'));
  final header = lines.isEmpty ? '' : lines.first;
  if (!header.startsWith('"CÓDIGO DE LA SERIE"')) {
    throw const InvalidResponseException('El CSV del Banco de España cambió');
  }
  final column = _columnOf(header, currency);
  if (column == null) {
    throw NotFoundException('El Banco de España no trae tipos para $currency');
  }
  final points = <RatePoint>[];
  for (final line in lines.skip(1)) {
    final row = _dataRow.firstMatch(line);
    if (row == null) continue;
    final fields = line.split(',');
    if (column >= fields.length) continue;
    final rate = double.tryParse(fields[column]);
    // `"_"` y los huecos son días sin tipo para esa moneda.
    if (rate == null || rate <= 0) continue;
    points.add(RatePoint(_date(row), rate));
  }
  if (points.isEmpty) {
    throw NotFoundException('El Banco de España no trae tipos para $currency');
  }
  return ExchangeRateSeries(currency: currency, points: points);
}

/// Posición de la columna `DTCCBCE<moneda>EUR.B` en la cabecera.
int? _columnOf(String header, String currency) {
  final codes = header.split(',');
  final index = codes.indexOf('DTCCBCE${currency}EUR.B');
  return index < 0 ? null : index;
}

DateTime _date(RegExpMatch row) {
  final month = _months[row.group(2)];
  if (month == null) {
    throw InvalidResponseException('Mes desconocido: ${row.group(2)}');
  }
  return DateTime.utc(
    int.parse(row.group(3)!),
    month,
    int.parse(row.group(1)!),
  );
}
