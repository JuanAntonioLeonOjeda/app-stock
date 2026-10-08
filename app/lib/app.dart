// Composition root: el único sitio que construye adapters concretos y los
// conecta con use cases, controllers y pantallas (hexagonal-architecture.md).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:stock_app/core/theme/app_theme.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/analyze_stock_use_case.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/get_exchange_rates_use_case.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/get_intraday_history_use_case.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/get_price_history_use_case.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/load_history_use_case.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/open_news_use_case.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/search_symbol_use_case.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/history_entry.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/bde_exchange_rate_adapter.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/cached_exchange_rate_adapter.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/ecb_exchange_rate_adapter.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/fallback_exchange_rate_adapter.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/file_analysis_history_adapter.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/file_cache_adapter.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/tradingview_adapter.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/tradingview_chart_connection.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/url_launcher_adapter.dart';
import 'package:stock_app/features/analisis_accion/presentation/controllers/analysis_controller.dart';
import 'package:stock_app/features/analisis_accion/presentation/controllers/display_currency_controller.dart';
import 'package:stock_app/features/analisis_accion/presentation/controllers/home_controller.dart';
import 'package:stock_app/features/analisis_accion/presentation/controllers/price_chart_controller.dart';
import 'package:stock_app/features/analisis_accion/presentation/screens/analysis_screen.dart';
import 'package:stock_app/features/analisis_accion/presentation/screens/home_screen.dart';
import 'package:stock_app/features/contenido_educativo/application/use_cases/load_educational_content_use_case.dart';
import 'package:stock_app/features/contenido_educativo/application/use_cases/search_glossary_use_case.dart';
import 'package:stock_app/features/contenido_educativo/infrastructure/adapters/asset_educational_content_adapter.dart';
import 'package:stock_app/features/contenido_educativo/presentation/controllers/glossary_controller.dart';
import 'package:stock_app/features/contenido_educativo/presentation/open_topic.dart';
import 'package:stock_app/features/contenido_educativo/presentation/screens/glossary_screen.dart';
import 'package:stock_app/features/contenido_educativo/presentation/widgets/topic_inline_view.dart';

class StockApp extends StatefulWidget {
  const StockApp({super.key, required this.storageDirectory});

  /// Carpeta de la app donde se guardan la caché y el historial.
  final Directory storageDirectory;

  @override
  State<StockApp> createState() => _StockAppState();
}

class _StockAppState extends State<StockApp> {
  final _httpClient = http.Client();
  late final AnalyzeStockUseCase _analyzeStock;
  late final HomeController _homeController;
  late final GetPriceHistoryUseCase _getPriceHistory;
  late final GetIntradayHistoryUseCase _getIntradayHistory;
  late final GetExchangeRatesUseCase _getExchangeRates;
  late final LoadEducationalContentUseCase _loadEducationalContent;

  @override
  void initState() {
    super.initState();
    final storagePath = widget.storageDirectory.path;
    final cache = FileCacheAdapter(directory: Directory('$storagePath/cache'));
    final marketData = TradingViewAdapter(
      client: _httpClient,
      cache: cache,
      chartConnector: IoChartConnection.connect,
    );
    final history = FileAnalysisHistoryAdapter(
      directory: widget.storageDirectory,
    );
    _analyzeStock = AnalyzeStockUseCase(
      marketData: marketData,
      history: history,
    );
    _getPriceHistory = GetPriceHistoryUseCase(marketData);
    _getIntradayHistory = GetIntradayHistoryUseCase(marketData);
    _getExchangeRates = GetExchangeRatesUseCase(
      CachedExchangeRateAdapter(
        inner: FallbackExchangeRateAdapter(
          primary: EcbExchangeRateAdapter(client: _httpClient),
          secondary: BdeExchangeRateAdapter(client: _httpClient),
        ),
        cache: cache,
      ),
    );
    _loadEducationalContent = LoadEducationalContentUseCase(
      AssetEducationalContentAdapter(bundle: rootBundle),
    );
    _homeController = HomeController(
      searchSymbol: SearchSymbolUseCase(marketData),
      loadHistory: LoadHistoryUseCase(history),
    );
  }

  @override
  void dispose() {
    _homeController.dispose();
    _httpClient.close();
    super.dispose();
  }

  /// Une las dos features: `analisis_accion` pide abrir un tema y
  /// `contenido_educativo` lo muestra, sin que se conozcan entre sí.
  void _openTopic(BuildContext context, String topicId) => openEducationalTopic(
    context,
    loadContent: _loadEducationalContent,
    topicId: topicId,
  );

  /// La explicación de una métrica o un bloque, en el sitio. Las métricas
  /// relacionadas se abren aparte, en una hoja.
  Widget _buildInfo(BuildContext context, String topicId) => TopicInlineView(
    loadContent: _loadEducationalContent,
    topicId: topicId,
    onOpenTopic: (relatedId) => _openTopic(context, relatedId),
  );

  void _openGlossary(BuildContext context) {
    // El controller se crea fuera del builder: la ruta puede reconstruirlo.
    final controller = GlossaryController(
      loadContent: _loadEducationalContent,
      searchGlossary: const SearchGlossaryUseCase(),
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            GlossaryScreen(controller: controller, openTopic: _openTopic),
      ),
    );
  }

  Widget _buildAnalysisScreen(String symbol, {HistoryEntry? entry}) {
    // Un controlador de moneda por resultado: siempre empieza en euros.
    final display = DisplayCurrencyController(
      getExchangeRates: _getExchangeRates,
    );
    return AnalysisScreen(
      controller: AnalysisController(
        analyzeStock: _analyzeStock,
        openNews: const OpenNewsUseCase(UrlLauncherAdapter()),
        symbol: symbol,
        initialEntry: entry,
      ),
      showInfo: _openTopic,
      buildInfo: _buildInfo,
      chartController: PriceChartController(
        getPriceHistory: _getPriceHistory,
        getIntradayHistory: _getIntradayHistory,
        symbol: symbol,
        displayCurrency: display,
      ),
      displayCurrency: display,
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Análisis de acciones',
    theme: buildAppTheme(Brightness.light),
    darkTheme: buildAppTheme(Brightness.dark),
    home: HomeScreen(
      controller: _homeController,
      buildAnalysisScreen: _buildAnalysisScreen,
      onOpenLearn: _openGlossary,
    ),
  );
}
