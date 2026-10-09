import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/domain/ports/link_opener_port.dart';

/// Abre en el navegador las noticias más recientes de una empresa.
///
/// Es solo un enlace a una búsqueda de Google: la app no lee ni resume las
/// noticias.
class OpenNewsUseCase {
  const OpenNewsUseCase(this._linkOpener);

  final LinkOpenerPort _linkOpener;

  /// `true` si se pudo abrir el navegador.
  Future<bool> call(AnalysisResult result) =>
      _linkOpener.open(newsSearchUri(name: result.name, symbol: result.symbol));
}

/// Búsqueda de Google en la pestaña de noticias (`tbm=nws`), de más nueva a
/// más antigua (`tbs=sbd:1`). Lleva el ticker sin la bolsa (`TSE:7974` →
/// `7974`) para distinguir empresas con nombres parecidos.
Uri newsSearchUri({required String name, required String symbol}) {
  final ticker = symbol.split(':').last;
  return Uri.https('www.google.com', '/search', {
    'q': '$name $ticker',
    'tbm': 'nws',
    'tbs': 'sbd:1',
  });
}
