import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/alpha_vantage_error_detector.dart';

import '../../../../fixtures/alpha_vantage_fixtures.dart';

// Textos de límite de peticiones documentados por Alpha Vantage; no se han
// capturado porque provocarlos gasta la cuota del día.
const _dailyLimitBody = '''
{"Information": "Thank you for using Alpha Vantage! Our standard API rate limit is 25 requests per day. Please subscribe to any of the premium plans at https://www.alphavantage.co/premium/ to instantly remove all daily rate limits."}''';

const _perMinuteLimitBody = '''
{"Note": "Thank you for using Alpha Vantage! Our standard API call frequency is 5 calls per minute and 500 calls per day."}''';

const _burstLimitBody = '''
{"Information": "Thank you for using Alpha Vantage! Please consider spreading out your free API requests more sparingly (1 request per second). You may subscribe to any of the premium plans at https://www.alphavantage.co/premium/ to lift the free key rate limit (25 requests per day), raise the per-minute rate limit, and instantly unlock all premium endpoints"}''';

const _invalidCallBody = '''
{"Error Message": "Invalid API call. Please retry or visit the documentation (https://www.alphavantage.co/documentation/) for TIME_SERIES_DAILY."}''';

void main() {
  group('decodeAlphaVantageBody', () {
    test('devuelve el objeto de una respuesta correcta', () {
      final json = decodeAlphaVantageBody(
        readAlphaVantageFixture('overview_ibm'),
      );

      expect(json['Symbol'], 'IBM');
    });

    test('el límite diario es RateLimitException aunque mencione premium', () {
      expect(
        () => decodeAlphaVantageBody(_dailyLimitBody),
        throwsA(isA<RateLimitException>()),
      );
    });

    test('el límite por minuto es RateLimitException', () {
      expect(
        () => decodeAlphaVantageBody(_perMinuteLimitBody),
        throwsA(isA<RateLimitException>()),
      );
    });

    test(
      'el aviso de ráfaga (1 petición por segundo) es RateLimitException',
      () {
        expect(
          () => decodeAlphaVantageBody(_burstLimitBody),
          throwsA(isA<RateLimitException>()),
        );
      },
    );

    test('el histórico completo de pago es AlphaVantagePremiumException', () {
      expect(
        () => decodeAlphaVantageBody(
          readAlphaVantageFixture('time_series_daily_full_ibm'),
        ),
        throwsA(isA<AlphaVantagePremiumException>()),
      );
    });

    test('el aviso de la clave demo es MissingApiKeyException', () {
      expect(
        () => decodeAlphaVantageBody(
          readAlphaVantageFixture('information_demo_key'),
        ),
        throwsA(isA<MissingApiKeyException>()),
      );
    });

    test('un símbolo inexistente (objeto vacío) es NotFoundException', () {
      expect(
        () => decodeAlphaVantageBody(
          readAlphaVantageFixture('overview_unknown_symbol'),
        ),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('un "Error Message" es NotFoundException', () {
      expect(
        () => decodeAlphaVantageBody(_invalidCallBody),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('un aviso desconocido es InvalidResponseException', () {
      expect(
        () => decodeAlphaVantageBody('{"Information": "Algo inesperado"}'),
        throwsA(isA<InvalidResponseException>()),
      );
    });

    test('un cuerpo que no es JSON es InvalidResponseException', () {
      expect(
        () => decodeAlphaVantageBody('<html>502 Bad Gateway</html>'),
        throwsA(isA<InvalidResponseException>()),
      );
    });

    test('un JSON que no es un objeto es InvalidResponseException', () {
      expect(
        () => decodeAlphaVantageBody('[1, 2, 3]'),
        throwsA(isA<InvalidResponseException>()),
      );
    });
  });
}
