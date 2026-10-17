import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/history_entry.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/file_analysis_history_adapter.dart';

HistoryEntry _entry(String symbol, {int minute = 0}) => HistoryEntry(
  result: AnalysisResult(
    symbol: symbol,
    name: '$symbol S.A.',
    currency: 'USD',
    price: 10,
    lastCloseDate: DateTime(2026, 9, 29),
    lastFiscalPeriod: null,
    profile: CompanyProfile.general,
    horizon: Horizon.longTerm,
    verdict: Verdict.neutral,
    globalScore: 5.5,
    confidence: Confidence.medium,
    blocks: [],
    flags: [],
    missingData: [],
    motorVersion: '1.0.0',
  ),
  analyzedAt: DateTime(2026, 9, 30, 10, minute),
);

List<String> _symbols(List<HistoryEntry> entries) => [
  for (final entry in entries) entry.result.symbol,
];

void main() {
  late Directory directory;
  late FileAnalysisHistoryAdapter history;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('history');
    history = FileAnalysisHistoryAdapter(directory: directory);
  });
  tearDown(() => directory.deleteSync(recursive: true));

  group('FileAnalysisHistoryAdapter', () {
    test('sin archivo el historial está vacío', () async {
      expect(await history.load(), isEmpty);
    });

    test('guarda al principio: el más reciente primero', () async {
      await history.save(_entry('AAA'));
      await history.save(_entry('BBB'));

      expect(_symbols(await history.load()), ['BBB', 'AAA']);
    });

    test('un símbolo repetido se actualiza y sube al principio, sin '
        'duplicados', () async {
      await history.save(_entry('AAA'));
      await history.save(_entry('BBB'));
      await history.save(_entry('aaa', minute: 30));

      final entries = await history.load();

      expect(_symbols(entries), ['aaa', 'BBB']);
      expect(entries.first.analyzedAt, DateTime(2026, 9, 30, 10, 30));
    });

    test('guarda como máximo 10 y descarta el más antiguo', () async {
      for (var i = 0; i < 11; i++) {
        await history.save(_entry('S$i'));
      }

      final symbols = _symbols(await history.load());

      expect(symbols, hasLength(maxHistoryEntries));
      expect(symbols.first, 'S10');
      expect(symbols, isNot(contains('S0')));
    });

    test('persiste entre instancias (reinicio de la app)', () async {
      await history.save(_entry('AAA'));

      final reopened = FileAnalysisHistoryAdapter(directory: directory);

      expect(_symbols(await reopened.load()), ['AAA']);
    });

    test('un archivo corrupto da un historial vacío y se puede seguir '
        'guardando', () async {
      File('${directory.path}/analysis_history.json')
          .writeAsStringSync('{"version": 1, "entries": [{"roto": true}]}');

      expect(await history.load(), isEmpty);
      await history.save(_entry('AAA'));
      expect(_symbols(await history.load()), ['AAA']);
    });

    test('un archivo de otra versión da un historial vacío', () async {
      File('${directory.path}/analysis_history.json')
          .writeAsStringSync('{"version": 99, "entries": []}');

      expect(await history.load(), isEmpty);
    });
  });

  group('FileAnalysisHistoryAdapter.clear', () {
    test('vacía el historial guardado', () async {
      await history.save(_entry('AAA'));
      await history.save(_entry('BBB', minute: 1));

      await history.clear();

      expect(await history.load(), isEmpty);
    });

    test('limpiar un historial que no existe no falla', () async {
      await history.clear();

      expect(await history.load(), isEmpty);
    });

    test('se puede guardar de nuevo después de limpiar', () async {
      await history.save(_entry('AAA'));
      await history.clear();

      await history.save(_entry('BBB'));

      expect(_symbols(await history.load()), ['BBB']);
    });
  });
}
