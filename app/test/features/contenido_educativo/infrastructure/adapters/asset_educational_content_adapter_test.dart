import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/contenido_educativo/domain/exceptions/educational_content_exception.dart';
import 'package:stock_app/features/contenido_educativo/infrastructure/adapters/asset_educational_content_adapter.dart';

import '../../sample_content.dart';

/// Bundle escrito a mano: sirve los archivos de muestra y cuenta lecturas.
class _FakeBundle extends AssetBundle {
  _FakeBundle({this.missing});

  /// Nombre de archivo que "no existe".
  final String? missing;
  final List<String> reads = [];

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    reads.add(key);
    if (missing != null && key.endsWith(missing!)) {
      throw FlutterError('Unable to load asset: $key');
    }
    final files = sampleFiles();
    if (key.endsWith('metricas.es.json')) return files.metrics;
    if (key.endsWith('conceptos.es.json')) return files.concepts;
    if (key.endsWith('bloques.es.json')) return files.blocks;
    return files.guide;
  }

  @override
  Future<ByteData> load(String key) async => ByteData.sublistView(
    Uint8List.fromList(utf8.encode(await loadString(key))),
  );
}

void main() {
  group('AssetEducationalContentAdapter', () {
    test('lee los cuatro archivos y devuelve el contenido', () async {
      final bundle = _FakeBundle();

      final content = await AssetEducationalContentAdapter(bundle: bundle)
          .load();

      expect(content.metrics, hasLength(3));
      expect(bundle.reads, [
        'assets/contenido/metricas.es.json',
        'assets/contenido/conceptos.es.json',
        'assets/contenido/bloques.es.json',
        'assets/contenido/guia.es.json',
      ]);
    });

    test('guarda el contenido en memoria: se lee una sola vez', () async {
      final bundle = _FakeBundle();
      final adapter = AssetEducationalContentAdapter(bundle: bundle);

      final first = await adapter.load();
      final second = await adapter.load();

      expect(second, same(first));
      expect(bundle.reads, hasLength(4));
    });

    test('un archivo que falta es InvalidContentException', () async {
      final adapter = AssetEducationalContentAdapter(
        bundle: _FakeBundle(missing: 'bloques.es.json'),
      );

      await expectLater(
        adapter.load(),
        throwsA(isA<InvalidContentException>()),
      );
    });

    test('un fallo no se guarda: la siguiente llamada vuelve a leer', () async {
      final bundle = _FakeBundle(missing: 'guia.es.json');
      final adapter = AssetEducationalContentAdapter(bundle: bundle);
      await expectLater(
        adapter.load(),
        throwsA(isA<InvalidContentException>()),
      );
      final readsAfterFailure = bundle.reads.length;

      await expectLater(
        adapter.load(),
        throwsA(isA<InvalidContentException>()),
      );

      expect(bundle.reads.length, greaterThan(readsAfterFailure));
    });
  });
}
