import 'package:flutter/material.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/history_entry.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/symbol_match.dart';
import 'package:stock_app/features/analisis_accion/presentation/controllers/home_controller.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/error_messages.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/error_notice.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/history_list.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/search_bar_section.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/symbol_match_tile.dart';

/// Construye la pantalla de resultado para [symbol]: análisis nuevo, o el
/// guardado en [entry] si viene del historial. Lo aporta el composition root,
/// que es quien conoce los use cases.
typedef AnalysisScreenBuilder = Widget Function(
  String symbol, {
  HistoryEntry? entry,
});

/// Pantalla de inicio: buscador arriba e historial debajo (criterio 0).
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    required this.buildAnalysisScreen,
  });

  final HomeController controller;
  final AnalysisScreenBuilder buildAnalysisScreen;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.refreshHistory();
  }

  Future<void> _openAnalysis(String symbol, {HistoryEntry? entry}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => widget.buildAnalysisScreen(symbol, entry: entry),
      ),
    );
    // El análisis puede haber añadido o actualizado una entrada.
    await _controller.refreshHistory();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Analizar una acción')),
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
            Text('Historial', style: Theme.of(context).textTheme.titleMedium),
            HistoryList(
              entries: _controller.history,
              onTap: (entry) =>
                  _openAnalysis(entry.result.symbol, entry: entry),
            ),
          ],
        ),
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
      for (final match in _controller.matches ?? const <SymbolMatch>[])
        SymbolMatchTile(match: match, onTap: () => _openAnalysis(match.symbol)),
    ];
  }
}
