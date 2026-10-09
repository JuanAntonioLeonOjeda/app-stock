import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/load_history_use_case.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/history_entry.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/stock_analyzer.dart';

import '../../domain/motor/synthetic_companies.dart';
import '../fake_ports.dart';

HistoryEntry _entryAt(DateTime analyzedAt) => HistoryEntry(
  result: const StockAnalyzer().analyze(
    emptyCompany(),
    referenceDate: referenceDate,
  ),
  analyzedAt: analyzedAt,
);

void main() {
  group('LoadHistoryUseCase', () {
    test('devuelve las entradas, la más reciente primero', () async {
      final older = _entryAt(DateTime(2026, 9, 28));
      final newest = _entryAt(DateTime(2026, 9, 30));
      final middle = _entryAt(DateTime(2026, 9, 29));
      final history = FakeHistory([older, newest, middle]);

      final entries = await LoadHistoryUseCase(history)();

      expect(entries, [newest, middle, older]);
    });

    test('un historial vacío da una lista vacía', () async {
      expect(await LoadHistoryUseCase(FakeHistory())(), isEmpty);
    });
  });
}
