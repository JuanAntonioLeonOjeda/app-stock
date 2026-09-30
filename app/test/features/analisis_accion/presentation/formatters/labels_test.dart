import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/fetch_step.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/labels.dart';

void main() {
  group('fetchProgressLabel', () {
    test('indica el paso y su posición de 6', () {
      expect(
        fetchProgressLabel(FetchStep.balanceSheet),
        'Obteniendo balance, 4 de 6',
      );
      expect(
        fetchProgressLabel(FetchStep.overview),
        'Obteniendo perfil, 1 de 6',
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
