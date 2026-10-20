import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/contenido_educativo/domain/content/scale_bands.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/reading_scale.dart';

/// La escala del PER del motor: cuanto más bajo, mejor.
final _per = ReadingScale(
  points: const [
    ScalePoint(8, 9),
    ScalePoint(15, 8),
    ScalePoint(25, 5),
    ScalePoint(35, 3),
    ScalePoint(50, 1),
  ],
  unit: ScaleUnit.multiple,
  favorableFrom: 7,
  neutralFrom: 5,
);

/// Una escala creciente (cuanto más alto, mejor), como un margen.
final _margin = ReadingScale(
  points: const [ScalePoint(0, 1), ScalePoint(0.1, 5), ScalePoint(0.2, 9)],
  unit: ScaleUnit.fraction,
  favorableFrom: 7,
  neutralFrom: 5,
);

void main() {
  group('scoreAt', () {
    test('interpola entre puntos como el motor', () {
      expect(scoreAt(_per, 20), closeTo(6.5, 1e-9));
    });

    test('satura por debajo del primer punto y por encima del último', () {
      expect(scoreAt(_per, 2), 9);
      expect(scoreAt(_per, 200), 1);
    });
  });

  group('bandsFor', () {
    test('una escala decreciente da favorable, intermedio y desfavorable', () {
      final bands = bandsFor(_per);

      expect(bands.map((b) => b.tone), [
        Tone.positive,
        Tone.neutral,
        Tone.negative,
      ]);
    });

    test('las fronteras están donde la nota cruza los cortes del motor', () {
      final bands = bandsFor(_per);

      // Entre 15 (nota 8) y 25 (nota 5): 7 se cruza en 18,33.
      expect(bands[0].to, closeTo(18.333, 0.001));
      // La nota 5 es justo la del punto 25: ahí empieza lo desfavorable.
      expect(bands[1].to, closeTo(25, 1e-9));
    });

    test('otros cortes dan otras fronteras: no hay umbrales fijos', () {
      final strict = ReadingScale(
        points: _per.points,
        unit: ScaleUnit.multiple,
        favorableFrom: 8.5,
        neutralFrom: 4,
      );

      final bands = bandsFor(strict);

      // 8,5 se cruza entre 8 (nota 9) y 15 (nota 8)... ya no llega a 8,5.
      expect(bands.first.tone, Tone.positive);
      expect(bands.first.to, lessThan(15));
      // 4 se cruza en 30, entre 25 (nota 5) y 35 (nota 3).
      expect(bands[bands.length - 2].to, closeTo(30, 1e-9));
    });

    test('los tramos cubren de principio a fin sin huecos', () {
      final bands = bandsFor(_per);

      expect(bands.first.from, 8);
      expect(bands.last.to, 50);
      for (var i = 1; i < bands.length; i++) {
        expect(bands[i].from, bands[i - 1].to);
      }
    });

    test('una escala creciente invierte el orden de los tonos', () {
      expect(bandsFor(_margin).map((b) => b.tone), [
        Tone.negative,
        Tone.neutral,
        Tone.positive,
      ]);
    });

    test('tramos contiguos del mismo tono se unen en uno', () {
      final flat = ReadingScale(
        points: const [ScalePoint(0, 9), ScalePoint(5, 8), ScalePoint(10, 8)],
        unit: ScaleUnit.decimal,
        favorableFrom: 7,
        neutralFrom: 5,
      );

      final bands = bandsFor(flat);

      expect(bands, hasLength(1));
      expect(bands.single.from, 0);
      expect(bands.single.to, 10);
    });
  });

  group('toneAt', () {
    test('devuelve el tono del tramo en el que cae el valor', () {
      expect(toneAt(_per, 10), Tone.positive);
      expect(toneAt(_per, 25), Tone.neutral);
      expect(toneAt(_per, 45), Tone.negative);
    });

    test('la nota justo en la frontera cuenta como el tramo mejor', () {
      expect(toneOfScore(_per, 7), Tone.positive);
      expect(toneOfScore(_per, 5), Tone.neutral);
      expect(toneOfScore(_per, 4.99), Tone.negative);
    });
  });
}
