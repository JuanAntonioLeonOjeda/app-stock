import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/scoring/piecewise_scale.dart';

void main() {
  // Escala del PER (menor es mejor): 8→9, 15→8, 25→5, 35→3, 50→1.
  const perScale = [
    ScorePoint(8, 9),
    ScorePoint(15, 8),
    ScorePoint(25, 5),
    ScorePoint(35, 3),
    ScorePoint(50, 1),
  ];

  group('scorePiecewise', () {
    test('interpola linealmente entre dos puntos', () {
      expect(scorePiecewise(20, perScale), closeTo(6.5, 1e-9));
    });

    test('devuelve la nota exacta en un punto de la escala', () {
      expect(scorePiecewise(25, perScale), 5);
    });

    test('satura en la nota del primer punto por debajo del rango', () {
      expect(scorePiecewise(2, perScale), 9);
    });

    test('satura en la nota del último punto por encima del rango', () {
      expect(scorePiecewise(80, perScale), 1);
    });

    test('admite escalas con óptimo intermedio (sube y baja)', () {
      const rsiScale = [
        ScorePoint(20, 4),
        ScorePoint(45, 9),
        ScorePoint(60, 9),
        ScorePoint(80, 3),
      ];

      expect(scorePiecewise(50, rsiScale), 9);
      expect(scorePiecewise(70, rsiScale), closeTo(6, 1e-9));
    });
  });

  group('roundToTenth', () {
    test('redondea a un decimal', () {
      expect(roundToTenth(6.54), 6.5);
      expect(roundToTenth(6.56), 6.6);
    });
  });
}
