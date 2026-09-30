import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/search_symbol_use_case.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/symbol_match.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';

import '../fake_ports.dart';

const _tesco = SymbolMatch(
  symbol: 'TSCO.LON',
  name: 'Tesco PLC',
  region: 'United Kingdom',
  currency: 'GBX',
  matchScore: 0.73,
);

void main() {
  group('SearchSymbolUseCase', () {
    test('devuelve las coincidencias del proveedor', () async {
      final marketData = FakeMarketData(matches: [_tesco]);

      final matches = await SearchSymbolUseCase(marketData)('tesco');

      expect(matches, [_tesco]);
    });

    test('quita los espacios de los extremos antes de buscar', () async {
      final marketData = FakeMarketData();

      await SearchSymbolUseCase(marketData)('  tesco  ');

      expect(marketData.searchQueries, ['tesco']);
    });

    test('un texto vacío no busca y devuelve una lista vacía', () async {
      final marketData = FakeMarketData(matches: [_tesco]);

      final matches = await SearchSymbolUseCase(marketData)('   ');

      expect(matches, isEmpty);
      expect(marketData.searchQueries, isEmpty);
    });

    test('recorta textos de más de 60 caracteres', () async {
      final marketData = FakeMarketData();

      await SearchSymbolUseCase(marketData)('a' * 100);

      expect(marketData.searchQueries.single, hasLength(maxSearchQueryLength));
    });

    test('propaga los errores del proveedor', () async {
      final marketData = FakeMarketData()..error = const RateLimitException();

      await expectLater(
        SearchSymbolUseCase(marketData)('tesco'),
        throwsA(isA<RateLimitException>()),
      );
    });
  });
}
