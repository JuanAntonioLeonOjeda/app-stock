import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/analysis_result.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/motor_version.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/rules/flag_rules.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/stock_analyzer.dart';

import 'synthetic_companies.dart';

const _analyzer = StockAnalyzer();

MetricResult? _metric(AnalysisResult result, String id) =>
    result.blocks.expand((b) => b.metrics).where((m) => m.id == id).firstOrNull;

/// Representación completa de un resultado, para comparar dos análisis.
String _fingerprint(AnalysisResult r) => [
  r.symbol,
  r.name,
  r.currency,
  r.price,
  r.lastCloseDate,
  r.lastFiscalPeriod,
  r.profile,
  r.horizon,
  r.verdict,
  r.globalScore,
  r.confidence,
  for (final b in r.blocks) ...[
    b.block,
    b.score,
    b.weight,
    b.coverage,
    for (final m in b.metrics) ...[
      m.id,
      m.label,
      m.value,
      m.format,
      m.score,
      m.weight,
      m.note,
    ],
  ],
  ...r.flags,
  ...r.missingData,
  r.motorVersion,
].join('|');

void main() {
  group('StockAnalyzer con empresas sintéticas', () {
    test('una empresa de calidad en tendencia alcista sale favorable', () {
      final result = _analyzer.analyze(
        qualityCompany(),
        referenceDate: referenceDate,
      );

      expect(result.verdict, Verdict.favorable);
      expect(result.globalScore, greaterThanOrEqualTo(7));
      expect(result.confidence, Confidence.high);
      expect(result.profile, CompanyProfile.general);
      expect(result.flags, isEmpty);
      expect(result.missingData, isEmpty);
    });

    test('una empresa frágil sale desfavorable y con avisos', () {
      final result = _analyzer.analyze(
        fragileCompany(),
        referenceDate: referenceDate,
      );

      expect(result.verdict, Verdict.unfavorable);
      expect(result.globalScore, lessThan(5));
      expect(
        result.flags,
        containsAll([dilutionAlarmText, netDebtToEbitdaAlarmText]),
      );
    });

    test('analizar dos veces los mismos datos da un resultado idéntico', () {
      final data = qualityCompany();

      final first = _analyzer.analyze(data, referenceDate: referenceDate);
      final second = _analyzer.analyze(data, referenceDate: referenceDate);

      expect(_fingerprint(second), _fingerprint(first));
    });

    test(
      'copia al resultado el ISIN, la bolsa y si es la principal (criterio 80)',
      () {
        final data = buildCompany(
          companyOverview: overview(
            isin: 'ES0144580Y14',
            exchange: 'BME',
            isPrimaryListing: true,
          ),
        );

        final result = _analyzer.analyze(data, referenceDate: referenceDate);

        expect(result.isin, 'ES0144580Y14');
        expect(result.exchange, 'BME');
        expect(result.isPrimaryListing, isTrue);
      },
    );

    test('sin esos datos el resultado los deja en null', () {
      final result = _analyzer.analyze(
        qualityCompany(),
        referenceDate: referenceDate,
      );

      expect(result.isin, isNull);
      expect(result.isPrimaryListing, isNull);
    });

    test('rellena los datos de cabecera y la versión del motor', () {
      final data = qualityCompany();

      final result = _analyzer.analyze(data, referenceDate: referenceDate);

      expect(result.symbol, 'CALI');
      expect(result.price, data.dailyBars.last.close);
      expect(result.lastCloseDate, data.dailyBars.last.date);
      expect(result.lastFiscalPeriod, DateTime(2026, 6, 30));
      expect(result.horizon, Horizon.longTerm);
      expect(result.motorVersion, motorVersion);
      expect(result.blocks.map((b) => b.block), Block.values);
    });
  });

  group('StockAnalyzer: casos límite', () {
    test('con beneficios negativos el PER no puntúa ni cuenta como dato '
        'que falta', () {
      final data = buildCompany(
        annualOperatingIncome: const [5, 300, 260, 220],
      );

      final result = _analyzer.analyze(data, referenceDate: referenceDate);
      final per = _metric(result, 'per');

      expect(result.profile, CompanyProfile.growth);
      expect(per?.score, isNull);
      expect(per?.note, contains('No aplica'));
      expect(result.missingData, isNot(contains(per?.label)));
    });

    test('el perfil financiero desactiva las métricas de deuda y activa '
        'P/VC y ROE', () {
      final data = buildCompany(
        companyOverview: overview(
          sector: 'FINANCIAL SERVICES',
          industry: 'BANKS - REGIONAL',
        ),
      );

      final result = _analyzer.analyze(data, referenceDate: referenceDate);

      expect(result.profile, CompanyProfile.financial);
      for (final id in ['deuda_ebitda', 'deuda_patrimonio', 'liquidez']) {
        expect(_metric(result, id), isNull, reason: id);
      }
      expect(_metric(result, 'p_vc'), isNotNull);
      expect(_metric(result, 'roe'), isNotNull);
    });

    test('sin datos el veredicto es datos insuficientes', () {
      final result = _analyzer.analyze(
        emptyCompany(),
        referenceDate: referenceDate,
      );

      expect(result.verdict, Verdict.insufficientData);
      expect(result.globalScore, isNull);
      expect(result.confidence, Confidence.low);
      expect(result.price, isNull);
    });

    test('con precios de hace más de 7 días la confianza es baja y se '
        'avisa', () {
      final result = _analyzer.analyze(
        qualityCompany(),
        referenceDate: referenceDate.add(const Duration(days: 30)),
      );

      expect(result.confidence, Confidence.low);
      expect(result.flags, contains(stalePriceText));
    });

    test('con histórico corto usa la media de 200 del perfil y avisa', () {
      final data = buildCompany(
        companyOverview: overview(movingAverage200: 100, week52High: 140),
        dailyBars: priceHistory(sessions: 150),
      );

      final result = _analyzer.analyze(data, referenceDate: referenceDate);
      final price = result.price!;

      expect(
        _metric(result, 'precio_sma200')?.value,
        closeTo(price / 100 - 1, 1e-9),
      );
      expect(
        _metric(result, 'dist_maximo')?.value,
        closeTo(price / 140 - 1, 1e-9),
      );
      expect(result.flags, contains(shortHistoryText));
      expect(
        result.missingData,
        contains('Pendiente de la media de 200 sesiones'),
      );
    });

    test('con histórico real calcula MACD, pendiente y caída máxima sin avisar '
        '(criterio 55)', () {
      final data = buildCompany(dailyBars: priceHistory(sessions: 400));

      final result = _analyzer.analyze(data, referenceDate: referenceDate);

      expect(_metric(result, 'macd')?.value, isNotNull);
      expect(_metric(result, 'pendiente_sma200')?.value, isNotNull);
      expect(_metric(result, 'caida_maxima')?.value, isNotNull);
      expect(_metric(result, 'precio_sma200')?.value, isNotNull);
      expect(result.flags, isNot(contains(noPriceHistoryText)));
      expect(result.flags, isNot(contains(shortHistoryText)));
    });

    test('con una sola barra esas métricas siguen sin dato y avisa '
        '(criterio 56)', () {
      final data = buildCompany(dailyBars: priceHistory(sessions: 1));

      final result = _analyzer.analyze(data, referenceDate: referenceDate);

      expect(_metric(result, 'macd')?.value, isNull);
      expect(_metric(result, 'pendiente_sma200')?.value, isNull);
      expect(_metric(result, 'caida_maxima')?.value, isNull);
      expect(result.flags, contains(noPriceHistoryText));
    });

    test(
      'con 6.000 sesiones el resultado sigue siendo el mismo (determinista)',
      () {
        final data = buildCompany(dailyBars: priceHistory(sessions: 6000));

        final first = _analyzer.analyze(data, referenceDate: referenceDate);
        final second = _analyzer.analyze(data, referenceDate: referenceDate);

        expect(_fingerprint(first), _fingerprint(second));
        expect(_metric(first, 'macd')?.value, isNotNull);
      },
    );
  });
}
