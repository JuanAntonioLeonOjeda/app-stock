// La hora local de una bolsa a partir de su zona horaria (nombre IANA). Una
// tabla de las zonas habituales con las reglas de cambio de hora de la UE y de
// EE. UU. evita traer la base de datos completa de zonas: si la zona no está,
// devuelve null y quien llama usa la hora del dispositivo (criterio 64).

/// Zonas sin cambio de hora, en minutos respecto a UTC.
const _fixedOffsets = {
  'Asia/Tokyo': 540,
  'Asia/Seoul': 540,
  'Asia/Hong_Kong': 480,
  'Asia/Shanghai': 480,
  'Asia/Singapore': 480,
  'Asia/Taipei': 480,
  'Asia/Kolkata': 330,
  'Asia/Dubai': 240,
  'Europe/Istanbul': 180,
  'America/Sao_Paulo': -180,
  'America/Mexico_City': -360,
};

/// Zonas europeas con cambio de hora, con su desfase de invierno en minutos.
const _europeanBaseOffsets = {
  'Europe/Madrid': 60,
  'Europe/Paris': 60,
  'Europe/Berlin': 60,
  'Europe/Rome': 60,
  'Europe/Amsterdam': 60,
  'Europe/Brussels': 60,
  'Europe/Zurich': 60,
  'Europe/Vienna': 60,
  'Europe/Stockholm': 60,
  'Europe/Oslo': 60,
  'Europe/Copenhagen': 60,
  'Europe/Warsaw': 60,
  'Europe/Prague': 60,
  'Europe/Budapest': 60,
  'Europe/London': 0,
  'Europe/Lisbon': 0,
  'Europe/Dublin': 0,
  'Europe/Helsinki': 120,
  'Europe/Athens': 120,
};

/// Zonas norteamericanas con cambio de hora, con su desfase de invierno.
const _americanBaseOffsets = {
  'America/New_York': -300,
  'America/Toronto': -300,
  'America/Chicago': -360,
  'America/Denver': -420,
  'America/Los_Angeles': -480,
};

/// La hora de pared de [timezone] en el instante [utc], como un `DateTime`
/// en UTC cuyos campos (hora, día...) son los locales. `null` si la zona no
/// está en la tabla.
DateTime? exchangeWallClock(DateTime utc, String? timezone) {
  final offset = exchangeOffsetMinutes(utc, timezone);
  return offset == null ? null : utc.add(Duration(minutes: offset));
}

/// Desfase de [timezone] respecto a UTC, en minutos, en el instante [utc].
int? exchangeOffsetMinutes(DateTime utc, String? timezone) {
  if (timezone == null) return null;
  final fixed = _fixedOffsets[timezone];
  if (fixed != null) return fixed;
  final european = _europeanBaseOffsets[timezone];
  if (european != null) {
    return european + (_isEuropeanSummerTime(utc) ? 60 : 0);
  }
  final american = _americanBaseOffsets[timezone];
  if (american != null) {
    return american + (_isAmericanSummerTime(utc, american) ? 60 : 0);
  }
  return null;
}

/// Hora de verano de la UE: desde el último domingo de marzo hasta el último
/// domingo de octubre, ambos a la 01:00 UTC.
bool _isEuropeanSummerTime(DateTime utc) {
  final start = DateTime.utc(utc.year, 3, _lastSunday(utc.year, 3), 1);
  final end = DateTime.utc(utc.year, 10, _lastSunday(utc.year, 10), 1);
  return !utc.isBefore(start) && utc.isBefore(end);
}

/// Hora de verano de EE. UU.: desde el segundo domingo de marzo a las 02:00
/// locales de invierno hasta el primer domingo de noviembre a las 02:00
/// locales de verano.
bool _isAmericanSummerTime(DateTime utc, int baseOffset) {
  final start = DateTime.utc(
    utc.year,
    3,
    _nthSunday(utc.year, 3, 2),
    2,
  ).subtract(Duration(minutes: baseOffset));
  final end = DateTime.utc(
    utc.year,
    11,
    _nthSunday(utc.year, 11, 1),
    2,
  ).subtract(Duration(minutes: baseOffset + 60));
  return !utc.isBefore(start) && utc.isBefore(end);
}

/// Día del mes del último domingo de [month].
int _lastSunday(int year, int month) {
  final lastDay = DateTime.utc(year, month + 1, 0);
  return lastDay.day - lastDay.weekday % DateTime.daysPerWeek;
}

/// Día del mes del [n]-ésimo domingo de [month].
int _nthSunday(int year, int month, int n) {
  final first = DateTime.utc(year, month);
  final firstSunday = 1 + (DateTime.sunday - first.weekday) % 7;
  return firstSunday + (n - 1) * 7;
}
