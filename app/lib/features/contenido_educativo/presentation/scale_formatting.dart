import 'package:intl/intl.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/reading_scale.dart';

/// Único punto donde una fracción se multiplica por 100 para mostrarla
/// (ver `naming-conventions.md`).
const _percentFactor = 100;

final _number = NumberFormat('#,##0.#', 'es');

String formatNumber(double value) => _number.format(value);

/// Un valor de una escala: `15x`, `2,5 %` o `55`.
String formatScaleValue(double value, ScaleUnit unit) => switch (unit) {
  ScaleUnit.multiple => '${formatNumber(value)}x',
  ScaleUnit.fraction => '${formatNumber(value * _percentFactor)} %',
  ScaleUnit.decimal => formatNumber(value),
};

/// Un dato de una fórmula con su unidad (`30 €`); sin unidad, solo el número.
String formatPieceValue(double value, String unit) =>
    unit.isEmpty ? formatNumber(value) : '${formatNumber(value)} $unit';

/// El resultado de una fórmula. Con unidad `%` el valor es una fracción;
/// `x` se pega al número y cualquier otra unidad va separada.
String formatResultValue(double value, String unit) => switch (unit) {
  '' => formatNumber(value),
  '%' => '${formatNumber(value * _percentFactor)} %',
  'x' => '${formatNumber(value)}x',
  _ => '${formatNumber(value)} $unit',
};
