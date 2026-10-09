import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/currency/quote_currency.dart';

void main() {
  group('resolveQuoteCurrency', () {
    test('una moneda normal se queda como está', () {
      final currency = resolveQuoteCurrency('JPY')!;

      expect(currency.isoCode, 'JPY');
      expect(currency.subunitDivisor, 1);
      expect(currency.isEuro, isFalse);
    });

    test('el euro se reconoce', () {
      expect(resolveQuoteCurrency('EUR')!.isEuro, isTrue);
    });

    test('los peniques son libras entre 100 (criterio 91)', () {
      final currency = resolveQuoteCurrency('GBX')!;

      expect(currency.isoCode, 'GBP');
      expect(currency.subunitDivisor, 100);
    });

    test('los céntimos del rand y los agorot del séquel también', () {
      expect(resolveQuoteCurrency('ZAC')!.isoCode, 'ZAR');
      expect(resolveQuoteCurrency('ZAC')!.subunitDivisor, 100);
      expect(resolveQuoteCurrency('ILA')!.isoCode, 'ILS');
      expect(resolveQuoteCurrency('ILA')!.subunitDivisor, 100);
    });

    test('no distingue mayúsculas ni espacios', () {
      expect(resolveQuoteCurrency(' usd ')!.isoCode, 'USD');
      expect(resolveQuoteCurrency('gbx')!.isoCode, 'GBP');
    });

    test('sin código no hay moneda', () {
      expect(resolveQuoteCurrency(null), isNull);
      expect(resolveQuoteCurrency(''), isNull);
      expect(resolveQuoteCurrency('   '), isNull);
    });
  });
}
