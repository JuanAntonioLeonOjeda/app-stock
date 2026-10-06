import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/open_news_use_case.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/stock_analyzer.dart';

import '../../domain/motor/synthetic_companies.dart';
import '../fake_ports.dart';

void main() {
  group('newsSearchUri', () {
    test('busca en la pestaña de noticias, de más nueva a más antigua', () {
      final uri = newsSearchUri(name: 'Nintendo Co., Ltd.', symbol: 'TSE:7974');

      expect(uri.host, 'www.google.com');
      expect(uri.path, '/search');
      expect(uri.queryParameters['tbm'], 'nws');
      expect(uri.queryParameters['tbs'], 'sbd:1');
    });

    test('lleva el nombre y el ticker sin la bolsa', () {
      final uri = newsSearchUri(name: 'Nintendo Co., Ltd.', symbol: 'TSE:7974');

      expect(uri.queryParameters['q'], 'Nintendo Co., Ltd. 7974');
    });

    test('un símbolo sin bolsa se usa tal cual', () {
      final uri = newsSearchUri(name: 'Apple Inc.', symbol: 'AAPL');

      expect(uri.queryParameters['q'], 'Apple Inc. AAPL');
    });

    test('codifica los caracteres especiales del nombre', () {
      final uri = newsSearchUri(name: 'AT&T Inc.', symbol: 'NYSE:T');

      expect(uri.toString(), isNot(contains('AT&T')));
      expect(uri.queryParameters['q'], 'AT&T Inc. T');
    });
  });

  group('OpenNewsUseCase', () {
    test('abre la búsqueda de la empresa del resultado', () async {
      final linkOpener = FakeLinkOpener();
      final result = const StockAnalyzer().analyze(
        qualityCompany(),
        referenceDate: referenceDate,
      );

      final wasOpened = await OpenNewsUseCase(linkOpener)(result);

      expect(wasOpened, isTrue);
      expect(
        linkOpener.opened.single.queryParameters['q'],
        contains('Calidad'),
      );
    });

    test('devuelve false si no se pudo abrir', () async {
      final result = const StockAnalyzer().analyze(
        qualityCompany(),
        referenceDate: referenceDate,
      );

      final wasOpened = await OpenNewsUseCase(FakeLinkOpener(canOpen: false))(
        result,
      );

      expect(wasOpened, isFalse);
    });
  });
}
