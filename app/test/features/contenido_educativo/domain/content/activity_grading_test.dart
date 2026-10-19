import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/contenido_educativo/domain/content/activity_grading.dart';
import 'package:stock_app/features/contenido_educativo/domain/entities/learning_activity.dart';

OrderItem _item(double value) =>
    OrderItem(name: '$value', value: value, shown: '$value');

void main() {
  group('isAscending', () {
    test('una lista de menor a mayor es correcta', () {
      expect(isAscending([_item(1), _item(5), _item(9)]), isTrue);
    });

    test('una lista con un par al revés es incorrecta', () {
      expect(isAscending([_item(1), _item(9), _item(5)]), isFalse);
    });
  });

  group('shuffledOrder', () {
    const values = [8.0, 15.0, 30.0, 45.0];

    test('es una permutación de todos los índices', () {
      final order = shuffledOrder('per', values);

      expect(order.toList()..sort(), [0, 1, 2, 3]);
    });

    test('nunca sale ya ordenada, con cualquier semilla', () {
      for (var i = 0; i < 200; i++) {
        final order = shuffledOrder('semilla$i', values);
        final shown = [for (final index in order) values[index]];
        expect(shown, isNot(orderedEquals([...values]..sort())));
      }
    });

    test('con la misma semilla da siempre el mismo orden', () {
      expect(shuffledOrder('per', values), shuffledOrder('per', values));
    });

    test('con semillas distintas no da siempre el mismo orden', () {
      final orders = {
        for (var i = 0; i < 20; i++) shuffledOrder('s$i', values).join(','),
      };

      expect(orders.length, greaterThan(1));
    });
  });
}
