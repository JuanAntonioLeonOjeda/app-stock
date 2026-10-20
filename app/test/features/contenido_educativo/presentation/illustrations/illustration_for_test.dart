import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/core/theme/app_theme.dart';
import 'package:stock_app/features/contenido_educativo/presentation/illustrations/chart_concept_illustrations.dart';
import 'package:stock_app/features/contenido_educativo/presentation/illustrations/context_illustrations.dart';
import 'package:stock_app/features/contenido_educativo/presentation/illustrations/growth_illustrations.dart';
import 'package:stock_app/features/contenido_educativo/presentation/illustrations/health_illustrations.dart';
import 'package:stock_app/features/contenido_educativo/presentation/illustrations/illustration_canvas.dart';
import 'package:stock_app/features/contenido_educativo/presentation/illustrations/illustration_for.dart';
import 'package:stock_app/features/contenido_educativo/presentation/illustrations/technical_illustrations.dart';
import 'package:stock_app/features/contenido_educativo/presentation/illustrations/valuation_illustrations.dart';

Future<void> _pump(WidgetTester tester, Widget child, Brightness brightness) =>
    tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(brightness),
        home: Scaffold(body: Center(child: child)),
      ),
    );

final _allIds = [
  ...valuationIllustrations.keys,
  ...healthIllustrations.keys,
  ...growthIllustrations.keys,
  ...technicalIllustrations.keys,
  ...contextIllustrations.keys,
  ...chartConceptIllustrations.keys,
];

void main() {
  group('illustrationFor', () {
    test('un id sin ilustración devuelve null', () {
      expect(illustrationFor('no_existe'), isNull);
    });

    test('hay una ilustración por cada métrica de valoración', () {
      expect(valuationIllustrations.keys, [
        'per',
        'peg',
        'ev_ebitda',
        'p_fcf',
        'p_ventas',
        'p_vc',
      ]);
      for (final id in valuationIllustrations.keys) {
        expect(illustrationFor(id), isNotNull, reason: id);
      }
    });

    test('hay una ilustración por cada métrica de salud financiera', () {
      expect(healthIllustrations.keys, [
        'deuda_ebitda',
        'deuda_patrimonio',
        'liquidez',
        'cobertura_intereses',
        'fcf_positivo',
        'payout_fcf',
      ]);
      for (final id in healthIllustrations.keys) {
        expect(illustrationFor(id), isNotNull, reason: id);
      }
    });

    test(
      'hay una ilustración por cada métrica de crecimiento y rentabilidad',
      () {
        expect(growthIllustrations.keys, [
          'ingresos_cagr3',
          'ingresos_yoy',
          'beneficio_cagr3',
          'margen_operativo',
          'margen_tendencia',
          'margen_bruto',
          'roic',
          'roe',
          'dilucion',
        ]);
        for (final id in growthIllustrations.keys) {
          expect(illustrationFor(id), isNotNull, reason: id);
        }
      },
    );

    test('hay una ilustración por cada métrica técnica', () {
      expect(technicalIllustrations.keys, [
        'precio_sma200',
        'pendiente_sma200',
        'rsi',
        'macd',
        'dist_maximo',
      ]);
      for (final id in technicalIllustrations.keys) {
        expect(illustrationFor(id), isNotNull, reason: id);
      }
    });

    test('hay una ilustración por cada métrica de contexto', () {
      expect(contextIllustrations.keys, [
        'sorpresas_bpa',
        'potencial_analistas',
        'beta',
        'caida_maxima',
      ]);
      for (final id in contextIllustrations.keys) {
        expect(illustrationFor(id), isNotNull, reason: id);
      }
    });

    test('hay una ilustración por cada concepto de la gráfica', () {
      expect(chartConceptIllustrations.keys, [
        'media_50',
        'media_200',
        'grafico_precio',
      ]);
      for (final id in chartConceptIllustrations.keys) {
        expect(illustrationFor(id), isNotNull, reason: id);
      }
    });

    test('ningún id está en dos bloques', () {
      expect(_allIds.toSet(), hasLength(_allIds.length));
    });

    for (final brightness in Brightness.values) {
      testWidgets('se dibujan sin errores en tema ${brightness.name}', (
        tester,
      ) async {
        for (final id in _allIds) {
          await _pump(tester, illustrationFor(id)!, brightness);

          expect(tester.takeException(), isNull, reason: id);
        }
      });
    }

    testWidgets(
      'cada ilustración tiene una descripción para lectores de pantalla',
      (tester) async {
        final handle = tester.ensureSemantics();
        for (final id in _allIds) {
          await _pump(tester, illustrationFor(id)!, Brightness.light);

          final label = tester
              .getSemantics(find.byType(IllustrationCanvas))
              .label;
          expect(label.trim(), isNotEmpty, reason: id);
        }
        handle.dispose();
      },
    );
  });
}
