import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/motor_version.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/analyze_stock_use_case.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/open_news_use_case.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/history_entry.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';
import 'package:stock_app/features/analisis_accion/domain/motor/stock_analyzer.dart';
import 'package:stock_app/features/analisis_accion/presentation/controllers/analysis_controller.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/metric_value_formatter.dart';
import 'package:stock_app/features/analisis_accion/presentation/screens/analysis_screen.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/info_builder.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/show_info.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/educational_disclaimer.dart';

import '../../application/fake_ports.dart';
import '../../domain/motor/synthetic_companies.dart';

HistoryEntry _qualityEntry() => HistoryEntry(
  result: const StockAnalyzer().analyze(
    qualityCompany(),
    referenceDate: referenceDate,
  ),
  analyzedAt: referenceDate,
);

Future<void> _pumpScreen(
  WidgetTester tester,
  FakeMarketData marketData, {
  HistoryEntry? entry,
  DateTime? now,
  FakeLinkOpener? linkOpener,
  ShowInfo? showInfo,
  InfoBuilder? buildInfo,
}) => tester.pumpWidget(
  MaterialApp(
    home: AnalysisScreen(
      showInfo: showInfo,
      buildInfo: buildInfo,
      controller: AnalysisController(
        openNews: OpenNewsUseCase(linkOpener ?? FakeLinkOpener()),
        analyzeStock: AnalyzeStockUseCase(
          marketData: marketData,
          history: FakeHistory(),
          now: () => referenceDate,
        ),
        symbol: 'CALI',
        initialEntry: entry,
        now: () => now ?? referenceDate,
      ),
    ),
  ),
);

Future<void> _scrollTo(WidgetTester tester, Finder finder) => tester
    .scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);

void main() {
  group('AnalysisScreen', () {
    testWidgets('muestra la cabecera, los bloques plegados y el aviso '
        'educativo', (tester) async {
      await _pumpScreen(tester, FakeMarketData(), entry: _qualityEntry());

      expect(find.text('Calidad S.A.'), findsOneWidget);
      expect(find.text('Favorable'), findsOneWidget);
      expect(find.text('8,3 / 10'), findsOneWidget);
      expect(find.text('Confianza: Alta'), findsOneWidget);
      expect(find.text('Motor v$motorVersion'), findsOneWidget);
      expect(find.text('Valoración'), findsOneWidget);
      expect(find.text('PER 12 meses'), findsNothing);
      await _scrollTo(tester, find.text(educationalDisclaimerText));
      expect(find.text(educationalDisclaimerText), findsOneWidget);
    });

    testWidgets(
      'el botón de noticias abre la búsqueda de Google (criterio 41)',
      (tester) async {
        final linkOpener = FakeLinkOpener();
        await _pumpScreen(
          tester,
          FakeMarketData(),
          entry: _qualityEntry(),
          linkOpener: linkOpener,
        );
        await _scrollTo(tester, find.text('Ver noticias recientes'));

        await tester.tap(find.text('Ver noticias recientes'));
        await tester.pump();

        final uri = linkOpener.opened.single;
        expect(uri.host, 'www.google.com');
        expect(uri.queryParameters['q'], contains('Calidad S.A.'));
      },
    );

    testWidgets('si no se puede abrir el navegador, avisa (criterio 42)', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        FakeMarketData(),
        entry: _qualityEntry(),
        linkOpener: FakeLinkOpener(canOpen: false),
      );
      await _scrollTo(tester, find.text('Ver noticias recientes'));

      await tester.tap(find.text('Ver noticias recientes'));
      await tester.pump();

      expect(find.text('No se ha podido abrir el navegador'), findsOneWidget);
      // El resultado sigue en pantalla.
      expect(find.text('Ver noticias recientes'), findsOneWidget);
    });

    testWidgets('con showInfo, el botón de la guía abre su tema', (
      tester,
    ) async {
      final opened = <String>[];
      await _pumpScreen(
        tester,
        FakeMarketData(),
        entry: _qualityEntry(),
        showInfo: (_, topicId) => opened.add(topicId),
      );

      await tester.tap(find.text('¿Cómo leer este diagnóstico?'));

      expect(opened, ['guia_diagnostico']);
    });

    testWidgets('con buildInfo, bloques y métricas se explican en el sitio', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        FakeMarketData(),
        entry: _qualityEntry(),
        buildInfo: (_, topicId) => Text('Explicación de $topicId'),
      );

      await tester.tap(find.byTooltip('Qué mide Valoración'));
      await tester.pumpAndSettle();
      expect(find.text('Explicación de bloque_valoracion'), findsOneWidget);
      await tester.tap(find.byTooltip('Qué es PER 12 meses'));
      await tester.pumpAndSettle();

      expect(find.text('Explicación de per'), findsOneWidget);
      expect(find.text('PER 12 meses'), findsOneWidget);
    });

    testWidgets('sin showInfo ni buildInfo no hay botón de guía ni iconos', (
      tester,
    ) async {
      await _pumpScreen(tester, FakeMarketData(), entry: _qualityEntry());

      expect(find.text('¿Cómo leer este diagnóstico?'), findsNothing);
      expect(find.byIcon(Icons.info_outline), findsNothing);
    });

    testWidgets('al desplegar un bloque se ven sus métricas', (tester) async {
      await _pumpScreen(tester, FakeMarketData(), entry: _qualityEntry());

      await tester.tap(find.text('Valoración'));
      await tester.pumpAndSettle();

      expect(find.text('PER 12 meses'), findsOneWidget);
      // En la empresa sintética, PER y P/FCF valen 14.
      expect(find.text('14,0x'), findsNWidgets(2));
    });

    testWidgets('la cabecera muestra precio, fecha de cierre y perfil '
        '(criterio 9)', (tester) async {
      final entry = _qualityEntry();
      final result = entry.result;
      await _pumpScreen(tester, FakeMarketData(), entry: entry);

      expect(find.text('CALI'), findsWidgets);
      expect(
        find.text(
          '${formatPrice(result.price, 'USD')} · cierre del '
          '${formatDate(result.lastCloseDate!)}',
        ),
        findsOneWidget,
      );
      expect(find.text('Perfil: General'), findsOneWidget);
    });

    testWidgets('cada bloque muestra su cobertura (criterio 10)', (
      tester,
    ) async {
      await _pumpScreen(tester, FakeMarketData(), entry: _qualityEntry());

      expect(find.text('Cobertura 100 %'), findsWidgets);
    });

    testWidgets('una métrica sin valor muestra "sin dato" y su nota '
        '(criterio 12)', (tester) async {
      final fragile = HistoryEntry(
        result: const StockAnalyzer().analyze(
          fragileCompany(),
          referenceDate: referenceDate,
        ),
        analyzedAt: referenceDate,
      );
      await _pumpScreen(tester, FakeMarketData(), entry: fragile);

      await tester.tap(find.text('Valoración'));
      await tester.pumpAndSettle();

      expect(
        find.text('sin dato · No aplica: flujo de caja libre negativo.'),
        findsOneWidget,
      );
    });

    testWidgets('lista los datos que faltan (criterio 13)', (tester) async {
      final shortHistory = HistoryEntry(
        result: const StockAnalyzer().analyze(
          buildCompany(dailyBars: priceHistory(sessions: 150)),
          referenceDate: referenceDate,
        ),
        analyzedAt: referenceDate,
      );
      await _pumpScreen(tester, FakeMarketData(), entry: shortHistory);

      await _scrollTo(tester, find.text('Datos que faltan'));

      expect(find.text('Datos que faltan'), findsOneWidget);
      expect(
        find.text('• Pendiente de la media de 200 sesiones'),
        findsOneWidget,
      );
    });

    testWidgets('con datos insuficientes no muestra nota global '
        '(criterio 28)', (tester) async {
      final empty = HistoryEntry(
        result: const StockAnalyzer().analyze(
          emptyCompany(),
          referenceDate: referenceDate,
        ),
        analyzedAt: referenceDate,
      );
      await _pumpScreen(tester, FakeMarketData(), entry: empty);

      expect(find.text('Datos insuficientes'), findsOneWidget);
      expect(find.textContaining('/ 10'), findsNothing);
    });

    testWidgets('desde el historial no pide datos', (tester) async {
      final marketData = FakeMarketData();

      await _pumpScreen(tester, marketData, entry: _qualityEntry());

      expect(marketData.fetchCalls, isEmpty);
    });

    testWidgets('un resultado antiguo avisa de su antigüedad', (tester) async {
      await _pumpScreen(
        tester,
        FakeMarketData(),
        entry: _qualityEntry(),
        now: referenceDate.add(const Duration(hours: 7)),
      );

      expect(find.text('Datos de hace 7 horas'), findsOneWidget);
    });

    testWidgets('un análisis nuevo muestra el progreso y después el '
        'resultado', (tester) async {
      final marketData = FakeMarketData(stockData: qualityCompany())
        ..gate = Completer<void>();

      await _pumpScreen(tester, marketData);
      await tester.pump();

      expect(find.text('Obteniendo datos de la empresa'), findsOneWidget);
      marketData.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Favorable'), findsOneWidget);
    });

    testWidgets('sin conexión ofrece reintentar', (tester) async {
      final marketData = FakeMarketData()..error = const NetworkException();

      await _pumpScreen(tester, marketData);
      await tester.pumpAndSettle();

      expect(find.text('Sin conexión.'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('con el límite de peticiones no ofrece reintentar', (
      tester,
    ) async {
      final marketData = FakeMarketData()..error = const RateLimitException();

      await _pumpScreen(tester, marketData);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Límite de peticiones de la API'),
        findsOneWidget,
      );
      expect(find.text('Reintentar'), findsNothing);
    });

    testWidgets('si falla la actualización, el resultado anterior sigue '
        'visible', (tester) async {
      final marketData = FakeMarketData()..error = const RateLimitException();
      await _pumpScreen(tester, marketData, entry: _qualityEntry());

      await tester.tap(find.byTooltip('Actualizar datos'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Límite de peticiones de la API'),
        findsOneWidget,
      );
      expect(find.text('Calidad S.A.'), findsOneWidget);
    });
  });
}
