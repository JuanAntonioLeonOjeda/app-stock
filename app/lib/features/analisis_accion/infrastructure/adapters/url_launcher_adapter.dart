import 'package:flutter/services.dart';
import 'package:stock_app/features/analisis_accion/domain/ports/link_opener_port.dart';
import 'package:url_launcher/url_launcher.dart';

/// [LinkOpenerPort] con el navegador del dispositivo.
class UrlLauncherAdapter implements LinkOpenerPort {
  const UrlLauncherAdapter();

  @override
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on PlatformException {
      // Sin navegador o sin permiso para abrirlo: no es un error de datos,
      // el use case solo necesita saber que no se pudo.
      return false;
    }
  }
}
