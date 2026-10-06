import 'package:flutter_test/flutter_test.dart';
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
