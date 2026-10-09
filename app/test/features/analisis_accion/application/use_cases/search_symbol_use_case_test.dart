import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/search_symbol_use_case.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/symbol_match.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';

import '../fake_ports.dart';
import '../../search_samples.dart';

void main() {
  group('SearchSymbolUseCase', () {
    test('devuelve las empresas encontradas, agrupadas por ISIN', () async {
      final marketData = FakeMarketData(matches: [tescoFrankfurt, tescoLondon]);

      final companies = await SearchSymbolUseCase(marketData)('tesco');

      expect(companies, hasLength(1));
      expect(companies.single.defaultListing.symbol, 'LSE:TSCO');
      expect(companies.single.others.map((m) => m.symbol), ['GETTEX:TCO']);
    });

    test('los certificados ADR salen al final', () async {
      final marketData = FakeMarketData(matches: [tescoReceipt, tescoLondon]);

      final companies = await SearchSymbolUseCase(marketData)('tesco');

      expect(companies.map((c) => c.isDepositaryReceipt), [false, true]);
    });

    test('descarta lo que no tiene ISIN', () async {
      final marketData = FakeMarketData(
        matches: [
          const SymbolMatch(
            symbol: 'Pyth:AAPL',
            name: 'Apple (sintético)',
            region: 'US',
            currency: 'USD',
            matchScore: 1,
          ),
          tescoLondon,
        ],
      );

      final companies = await SearchSymbolUseCase(marketData)('tesco');

      expect(companies.map((c) => c.isin), ['GB0008847096']);
    });

    test('quita los espacios de los extremos antes de buscar', () async {
      final marketData = FakeMarketData();

      await SearchSymbolUseCase(marketData)('  tesco  ');

      expect(marketData.searchQueries, ['tesco']);
    });

    test('un texto vacío no busca y devuelve una lista vacía', () async {
      final marketData = FakeMarketData(matches: [tescoLondon]);

      final companies = await SearchSymbolUseCase(marketData)('   ');

      expect(companies, isEmpty);
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
