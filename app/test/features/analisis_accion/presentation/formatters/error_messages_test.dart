import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/error_messages.dart';

void main() {
  group('errorMessage', () {
    test('usa los textos de la spec (criterios 22-27)', () {
      expect(
        errorMessage(const RateLimitException()),
        contains('Límite de peticiones de la API alcanzado'),
      );
      expect(
        errorMessage(const NotFoundException()),
        'No hay datos para este símbolo.',
      );
      expect(errorMessage(const NetworkException()), 'Sin conexión.');
      expect(
        errorMessage(const InvalidResponseException()),
        'Respuesta inesperada del proveedor de datos.',
      );
    });

    test('nunca muestra el detalle técnico', () {
      expect(
        errorMessage(const NetworkException('SocketException: detalle')),
        isNot(contains('SocketException')),
      );
    });
  });

  group('isRetryable', () {
    test('solo se ofrece reintentar ante fallos de red o respuestas raras', () {
      expect(isRetryable(const NetworkException()), isTrue);
      expect(isRetryable(const InvalidResponseException()), isTrue);
      expect(isRetryable(const RateLimitException()), isFalse);
      expect(isRetryable(const NotFoundException()), isFalse);
    });
  });
}
