import 'package:flutter/material.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/company_listings.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/favorite.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/history_entry.dart';
import 'package:stock_app/features/analisis_accion/presentation/controllers/home_controller.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/error_messages.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/error_notice.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/favorites_list.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/recent_queries_section.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/search_bar_section.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/company_listings_tile.dart';

/// Construye la pantalla de resultado para [symbol]: análisis nuevo, o el
/// guardado en [entry] si viene del historial. Lo aporta el composition root,
/// que es quien conoce los use cases.
typedef AnalysisScreenBuilder = Widget Function(
  String symbol, {
  HistoryEntry? entry,
});

/// Pantalla de inicio: buscador, favoritas y, plegadas, las últimas consultas
/// (criterio 0).
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    required this.buildAnalysisScreen,
    this.onOpenLearn,
  });

  final HomeController controller;
  final AnalysisScreenBuilder buildAnalysisScreen;

  /// Abre el glosario educativo; sin ella no hay acceso "Aprender".
  final void Function(BuildContext context)? onOpenLearn;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.refreshHistory();
    _controller.refreshFavorites();
  }

  Future<void> _openAnalysis(String symbol, {HistoryEntry? entry}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => widget.buildAnalysisScreen(symbol, entry: entry),
      ),
    );
    // El análisis puede haber añadido una entrada o cambiado una favorita.
    await _controller.refreshHistory();
    await _controller.refreshFavorites();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Analizar una acción'),
      actions: [
        if (widget.onOpenLearn case final onOpenLearn?)
          TextButton.icon(
            icon: const Icon(Icons.school_outlined),
            label: const Text('Aprender'),
            onPressed: () => onOpenLearn(context),
          ),
      ],
    ),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SearchBarSection(
              enabled: _controller.canSearch,
              onSearch: _controller.search,
            ),
            const SizedBox(height: 8),
            ..._searchResults(),
            const SizedBox(height: 24),
            Text('Favoritas', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            FavoritesList(
              favorites: _controller.favorites,
              history: _controller.history,
              onOpen: (Favorite favorite) => _openAnalysis(favorite.symbol),
              onRemove: _controller.removeFavorite,
            ),
            const SizedBox(height: 16),
            RecentQueriesSection(
              entries: _controller.history,
              onTap: (entry) =>
                  _openAnalysis(entry.result.symbol, entry: entry),
              onClear: _controller.clearHistory,
            ),
          ],
        ),
      ),
    ),
  );

  /// "Mostrar certificados ADR (n)" / "Ocultar certificados ADR" (criterio 75).
  Widget _receiptsButton() => Align(
    alignment: Alignment.centerLeft,
    child: TextButton(
      onPressed: () =>
          _controller.setShowReceipts(isVisible: !_controller.showReceipts),
      child: Text(
        _controller.showReceipts
            ? 'Ocultar certificados ADR'
            : 'Mostrar certificados ADR (${_controller.receiptCount})',
      ),
    ),
  );

  List<Widget> _searchResults() {
    if (_controller.isSearching) return const [LinearProgressIndicator()];
    if (_controller.searchError case final error?) {
      return [ErrorNotice(message: errorMessage(error))];
    }
    if (_controller.hasNoResults) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('No se ha encontrado ninguna acción.'),
        ),
      ];
    }
    return [
      for (final company in _controller.companies ?? const <CompanyListings>[])
        CompanyListingsTile(company: company, onSelect: _openAnalysis),
      if (_controller.canToggleReceipts) _receiptsButton(),
    ];
  }
}
