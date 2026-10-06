// Composition root: el único sitio que construye adapters concretos y los
// conecta con use cases, controllers y pantallas (hexagonal-architecture.md).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:stock_app/core/theme/app_theme.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/analyze_stock_use_case.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/load_history_use_case.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/open_news_use_case.dart';
import 'package:stock_app/features/analisis_accion/application/use_cases/search_symbol_use_case.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/history_entry.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/file_analysis_history_adapter.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/file_cache_adapter.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/tradingview_adapter.dart';
import 'package:stock_app/features/analisis_accion/infrastructure/adapters/url_launcher_adapter.dart';
import 'package:stock_app/features/analisis_accion/presentation/controllers/analysis_controller.dart';
import 'package:stock_app/features/analisis_accion/presentation/controllers/home_controller.dart';
import 'package:stock_app/features/analisis_accion/presentation/screens/analysis_screen.dart';
import 'package:stock_app/features/analisis_accion/presentation/screens/home_screen.dart';

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

  @override
  void initState() {
    super.initState();
    final storagePath = widget.storageDirectory.path;
    final marketData = TradingViewAdapter(
      client: _httpClient,
      cache: FileCacheAdapter(directory: Directory('$storagePath/cache')),
    );
    final history = FileAnalysisHistoryAdapter(
      directory: widget.storageDirectory,
    );
    _analyzeStock = AnalyzeStockUseCase(
      marketData: marketData,
      history: history,
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

  Widget _buildAnalysisScreen(String symbol, {HistoryEntry? entry}) =>
      AnalysisScreen(
        controller: AnalysisController(
          analyzeStock: _analyzeStock,
          openNews: const OpenNewsUseCase(UrlLauncherAdapter()),
          symbol: symbol,
          initialEntry: entry,
        ),
      );

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Análisis de acciones',
    theme: buildAppTheme(Brightness.light),
    darkTheme: buildAppTheme(Brightness.dark),
    home: HomeScreen(
      controller: _homeController,
      buildAnalysisScreen: _buildAnalysisScreen,
    ),
  );
}
