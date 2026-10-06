import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/history_entry.dart';

void main() {
  final analyzedAt = DateTime(2026, 9, 30, 10);
  final entry = HistoryEntry(
    result: AnalysisResult(
      symbol: 'TEST',
      name: 'Empresa de prueba',
      currency: 'USD',
      price: null,
      lastCloseDate: null,
      lastFiscalPeriod: null,
      profile: CompanyProfile.general,
      horizon: Horizon.longTerm,
      verdict: Verdict.insufficientData,
      globalScore: null,
      confidence: Confidence.low,
      blocks: [],
      flags: [],
      missingData: [],
      motorVersion: '1.0.0',
    ),
    analyzedAt: analyzedAt,
  );

  group('HistoryEntry.isStaleAt', () {
    test('no está caducada justo a las 6 horas', () {
      expect(
        entry.isStaleAt(analyzedAt.add(const Duration(hours: 6))),
        isFalse,
      );
    });

    test('está caducada pasadas las 6 horas', () {
      expect(
        entry.isStaleAt(analyzedAt.add(const Duration(hours: 6, minutes: 1))),
        isTrue,
      );
    });
  });
}
