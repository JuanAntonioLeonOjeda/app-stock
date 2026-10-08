import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/chart/chart_range.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/fetch_step.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/labels.dart';

void main() {
  group('fetchProgressLabel', () {
    test('indica el paso en curso', () {
      expect(
        fetchProgressLabel(FetchStep.fetching),
        'Obteniendo datos de la empresa',
      );
    });
  });

  group('chartRangeLabel', () {
    test('cada periodo tiene su texto del selector', () {
      expect(
        [for (final range in ChartRange.values) chartRangeLabel(range)],
        ['1M', '3M', '6M', '1A', '5A', 'Todo'],
      );
    });
  });

  group('blockTopicId', () {
    test('cada bloque tiene un id de tema distinto y estable', () {
      expect(
        [for (final block in Block.values) blockTopicId(block)],
        [
          'bloque_valoracion',
          'bloque_salud',
          'bloque_crecimiento',
          'bloque_tecnico',
          'bloque_contexto',
        ],
      );
    });

    test('la guía tiene su propio id de tema', () {
      expect(diagnosisGuideTopicId, 'guia_diagnostico');
    });
  });

  group('etiquetas de enums', () {
    test('los veredictos usan los textos de la spec', () {
      expect(verdictLabel(Verdict.favorable), 'Favorable');
      expect(verdictLabel(Verdict.unfavorable), 'Desfavorable');
      expect(verdictLabel(Verdict.insufficientData), 'Datos insuficientes');
    });

    test('cada bloque tiene su nombre', () {
      expect(blockLabel(Block.health), 'Salud financiera');
      expect(Block.values.map(blockLabel).toSet(), hasLength(5));
    });
  });
}
