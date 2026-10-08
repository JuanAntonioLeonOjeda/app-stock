import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/history_entry.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/stock_analyzer.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/analysis_result_json.dart';

import '../../domain/motor/synthetic_companies.dart';

/// Ida y vuelta a través de texto JSON, como al guardar y leer un archivo.
Object? _throughText(Object? json) => jsonDecode(jsonEncode(json));

void main() {
  group('analysisResultToJson / analysisResultFromJson', () {
    test('un análisis completo sobrevive a la ida y vuelta sin pérdidas', () {
      for (final data in [qualityCompany(), fragileCompany(), emptyCompany()]) {
        final result = const StockAnalyzer().analyze(
          data,
          referenceDate: referenceDate,
        );
        final json = analysisResultToJson(result);

        final restored = analysisResultFromJson(_throughText(json));

        expect(analysisResultToJson(restored), json, reason: result.symbol);
      }
    });

    test('conserva los null (datos que faltan) como null, no como 0', () {
      final result = const StockAnalyzer().analyze(
        emptyCompany(),
        referenceDate: referenceDate,
      );

      final restored = analysisResultFromJson(
        _throughText(analysisResultToJson(result)),
      );

      expect(restored.globalScore, isNull);
      expect(restored.price, isNull);
      expect(restored.blocks.first.metrics.first.value, isNull);
    });

    test('guarda y recupera el ISIN, la bolsa y si es la principal', () {
      final result = const StockAnalyzer().analyze(
        buildCompany(
          companyOverview: overview(
            isin: 'JP3756600007',
            exchange: 'TSE',
            isPrimaryListing: false,
          ),
        ),
        referenceDate: referenceDate,
      );

      final restored = analysisResultFromJson(
        _throughText(analysisResultToJson(result)),
      );

      expect(restored.isin, 'JP3756600007');
      expect(restored.exchange, 'TSE');
      expect(restored.isPrimaryListing, isFalse);
    });

    test('un análisis guardado antes de esos campos se lee igual, con null (criterio 81)', () {
      final json =
          analysisResultToJson(
              const StockAnalyzer().analyze(
                qualityCompany(),
                referenceDate: referenceDate,
              ),
            )
            ..remove('isin')
            ..remove('exchange')
            ..remove('isPrimaryListing');

      final restored = analysisResultFromJson(_throughText(json));

      expect(restored.isin, isNull);
      expect(restored.exchange, isNull);
      expect(restored.isPrimaryListing, isNull);
      expect(restored.name, 'Calidad S.A.');
    });

    test('un valor de enum desconocido es FormatException', () {
      final json = analysisResultToJson(
        const StockAnalyzer().analyze(
          qualityCompany(),
          referenceDate: referenceDate,
        ),
      )..['verdict'] = 'buenisimo';

      expect(() => analysisResultFromJson(json), throwsFormatException);
    });

    test('un JSON que no es un objeto es FormatException', () {
      expect(() => analysisResultFromJson([1, 2]), throwsFormatException);
    });
  });

  group('historyEntryToJson / historyEntryFromJson', () {
    test('conserva la fecha del análisis y el resultado', () {
      final entry = HistoryEntry(
        result: const StockAnalyzer().analyze(
          qualityCompany(),
          referenceDate: referenceDate,
        ),
        analyzedAt: DateTime(2026, 9, 30, 10, 15),
      );

      final restored = historyEntryFromJson(
        _throughText(historyEntryToJson(entry)),
      );

      expect(restored.analyzedAt, entry.analyzedAt);
      expect(restored.result.symbol, 'CALI');
    });
  });
}
