import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/symbol_match.dart';
import 'package:stock_app/features/analisis_accion/domain/search/group_listings.dart';

SymbolMatch _match(
  String symbol, {
  String? isin,
  String currency = 'EUR',
  bool primary = false,
  bool receipt = false,
  double score = 0.5,
  String name = 'Empresa',
}) => SymbolMatch(
  symbol: symbol,
  name: name,
  region: 'ES',
  currency: currency,
  matchScore: score,
  isin: isin,
  exchange: symbol.split(':').first,
  isPrimaryListing: primary,
  isDepositaryReceipt: receipt,
);

void main() {
  group('groupListings', () {
    test('une en una sola empresa las cotizaciones con el mismo ISIN (criterio 72)', () {
      final companies = groupListings([
        _match(
          'TSE:7974',
          isin: 'JP1',
          currency: 'JPY',
          primary: true,
          score: 1,
        ),
        _match('GETTEX:NTO', isin: 'JP1', score: 0.9),
        _match('LSE:0R1E', isin: 'JP1', currency: 'JPY', score: 0.8),
      ]);

      expect(companies, hasLength(1));
      expect(companies.single.isin, 'JP1');
    });

    test('la cotización principal es la que se abre y va etiquetada', () {
      final company = groupListings([
        _match('GETTEX:NTO', isin: 'JP1', score: 1),
        _match(
          'TSE:7974',
          isin: 'JP1',
          currency: 'JPY',
          primary: true,
          score: 0.9,
        ),
      ]).single;

      expect(company.defaultListing.symbol, 'TSE:7974');
      expect(company.hasConfirmedPrimary, isTrue);
      expect(company.others.map((m) => m.symbol), ['GETTEX:NTO']);
    });

    test('sin cotización marcada como principal se abre la mejor coincidencia sin etiquetarla', () {
      final company = groupListings([
        _match('OTC:IDEXF', isin: 'ES1', currency: 'USD', score: 0.7),
        _match('GETTEX:IXD1', isin: 'ES1', score: 0.9),
      ]).single;

      expect(company.defaultListing.symbol, 'GETTEX:IXD1');
      expect(company.hasConfirmedPrimary, isFalse);
    });

    test('en "otras cotizaciones" las de euros van primero (criterio 73)', () {
      final company = groupListings([
        _match(
          'TSE:7974',
          isin: 'JP1',
          currency: 'JPY',
          primary: true,
          score: 1,
        ),
        _match('BMV:NTDOY/N', isin: 'JP1', currency: 'MXN', score: 0.95),
        _match('LSE:0R1E', isin: 'JP1', currency: 'JPY', score: 0.9),
        _match('GETTEX:NTO', isin: 'JP1', score: 0.8),
        _match('XETR:NTO', isin: 'JP1', score: 0.7),
      ]).single;

      expect(company.others.map((m) => m.symbol), [
        'GETTEX:NTO',
        'XETR:NTO',
        'BMV:NTDOY/N',
        'LSE:0R1E',
      ]);
    });

    test('descarta las coincidencias sin ISIN (criterio 76)', () {
      final companies = groupListings([
        _match('Pyth:AAPL', isin: null, currency: 'USD'),
        _match('X:Y', isin: '', currency: 'USD'),
        _match('NASDAQ:AAPL', isin: 'US1', currency: 'USD', primary: true),
      ]);

      expect(companies.map((c) => c.isin), ['US1']);
    });

    test('dos empresas con nombres parecidos no se mezclan', () {
      final companies = groupListings([
        _match(
          'NASDAQ:AAPL',
          isin: 'US1',
          currency: 'USD',
          primary: true,
          score: 1,
        ),
        _match(
          'NYSE:APLE',
          isin: 'US2',
          currency: 'USD',
          primary: true,
          score: 0.9,
        ),
      ]);

      expect(companies, hasLength(2));
    });

    test('las empresas van por la relevancia de su mejor coincidencia (criterio 79)', () {
      final companies = groupListings([
        _match('A:1', isin: 'AAA', score: 0.3, primary: true),
        _match('B:1', isin: 'BBB', score: 0.9, primary: true),
        _match('A:2', isin: 'AAA', score: 0.95),
        _match('C:1', isin: 'CCC', score: 0.6, primary: true),
      ]);

      expect(companies.map((c) => c.isin), ['AAA', 'BBB', 'CCC']);
    });

    test('con la misma relevancia se conserva el orden del proveedor', () {
      final companies = groupListings([
        _match('A:1', isin: 'AAA', score: 0.5, primary: true),
        _match('B:1', isin: 'BBB', score: 0.5, primary: true),
      ]);

      expect(companies.map((c) => c.isin), ['AAA', 'BBB']);
    });

    test('los certificados ADR van al final y marcados (criterio 75)', () {
      final companies = groupListings([
        _match(
          'OTC:NTDOY',
          isin: 'US1',
          currency: 'USD',
          receipt: true,
          score: 1,
        ),
        _match(
          'TSE:7974',
          isin: 'JP1',
          currency: 'JPY',
          primary: true,
          score: 0.4,
        ),
      ]);

      expect(companies.map((c) => c.isin), ['JP1', 'US1']);
      expect(companies.last.isDepositaryReceipt, isTrue);
      expect(companies.first.isDepositaryReceipt, isFalse);
    });

    test('un grupo con acciones y certificados mezclados no es un ADR', () {
      final company = groupListings([
        _match('A:1', isin: 'X', primary: true),
        _match('A:2', isin: 'X', receipt: true),
      ]).single;

      expect(company.isDepositaryReceipt, isFalse);
    });

    test(
      'el nombre y el país de la empresa son los de su cotización por defecto',
      () {
        final company = groupListings([
          _match('GETTEX:NTO', isin: 'JP1', name: 'Nintendo (Fráncfort)'),
          _match(
            'TSE:7974',
            isin: 'JP1',
            primary: true,
            name: 'Nintendo Co., Ltd.',
          ),
        ]).single;

        expect(company.name, 'Nintendo Co., Ltd.');
      },
    );

    test('sin coincidencias devuelve una lista vacía', () {
      expect(groupListings(const []), isEmpty);
    });
  });

  group('isinsMissingPrimary', () {
    test('devuelve los ISIN de las empresas sin cotización principal (criterio 77)', () {
      final missing = isinsMissingPrimary([
        _match('OTC:IDEXF', isin: 'ES1', currency: 'USD', score: 0.9),
        _match('TSE:7974', isin: 'JP1', primary: true, score: 0.8),
        _match('GETTEX:X', isin: 'DE1', score: 0.7),
      ]);

      expect(missing, ['ES1', 'DE1']);
    });

    test('no pide completar los certificados ADR', () {
      final missing = isinsMissingPrimary([
        _match('OTC:IDEXY', isin: 'US1', currency: 'USD', receipt: true),
      ]);

      expect(missing, isEmpty);
    });

    test('ignora las coincidencias sin ISIN', () {
      expect(isinsMissingPrimary([_match('X:Y', isin: null)]), isEmpty);
    });

    test('sin coincidencias no hay nada que completar', () {
      expect(isinsMissingPrimary(const []), isEmpty);
    });
  });
}
