import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/contenido_educativo/application/use_cases/get_metric_scale_use_case.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/reading_scale.dart';

import '../fake_ports.dart';

void main() {
  group('GetMetricScaleUseCase', () {
    final perScale = ReadingScale(
      points: const [ScalePoint(8, 9), ScalePoint(50, 1)],
      unit: ScaleUnit.multiple,
      favorableFrom: 7,
      neutralFrom: 5,
    );

    test('devuelve la escala que da el port para esa métrica', () {
      final useCase = GetMetricScaleUseCase(
        FakeMetricScales({'per': perScale}),
      );

      expect(useCase('per'), same(perScale));
    });

    test('una métrica sin escala devuelve null', () {
      final useCase = GetMetricScaleUseCase(FakeMetricScales({}));

      expect(useCase('macd'), isNull);
    });
  });
}
