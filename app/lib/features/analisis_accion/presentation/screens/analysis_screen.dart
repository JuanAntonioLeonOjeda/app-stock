import 'package:flutter/material.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/history_entry.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';
import 'package:stock_app/features/analisis_accion/presentation/controllers/analysis_controller.dart';
import 'package:stock_app/features/analisis_accion/presentation/controllers/price_chart_controller.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/error_messages.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/labels.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/metric_value_formatter.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/analysis_progress.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/block_tile.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/educational_disclaimer.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/error_notice.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/flags_section.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/info_builder.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/missing_data_section.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/price_chart_panel.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/show_info.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/verdict_header.dart';

/// Resultado del análisis de una acción. Es dueña de su [controller] y de su
/// [chartController] (los libera al cerrarse).
///
/// Con [chartController] el resultado tiene dos pestañas: Resumen (la gráfica
/// de precio, abierta por defecto) y Detalle (la vista de siempre). Sin él, es
/// solo el detalle.
class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({
    super.key,
    required this.controller,
    this.showInfo,
    this.buildInfo,
    this.chartController,
  });

  final AnalysisController controller;

  /// Estado de la gráfica de precio de la pestaña Resumen.
  final PriceChartController? chartController;

  /// Abre una explicación educativa aparte (la guía del diagnóstico); sin ella
  /// no hay botón de la guía.
  final ShowInfo? showInfo;

  /// Construye la explicación de una métrica o un bloque para mostrarla en el
  /// sitio; sin ella no hay iconos de información.
  final InfoBuilder? buildInfo;

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  AnalysisController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    // Desde el historial ya hay resultado: no se recalcula (criterio 17).
    if (_controller.entry == null) _controller.analyze();
    widget.chartController?.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    widget.chartController?.dispose();
    super.dispose();
  }

  /// "Actualizar datos": vuelve a pedirlo todo, análisis y gráfica (criterio
  /// 45).
  void _refreshAll() {
    _controller.refresh();
    widget.chartController?.load(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: Text(_controller.symbol),
        actions: [
          IconButton(
            tooltip: 'Actualizar datos',
            icon: const Icon(Icons.refresh),
            onPressed: _controller.canRefresh ? _refreshAll : null,
          ),
        ],
      ),
      body: SafeArea(child: _body()),
    ),
  );

  Widget _body() {
    final entry = _controller.entry;
    if (entry != null) return _result(entry);
    if (_controller.isLoading) {
      return Center(child: AnalysisProgress(step: _controller.currentStep));
    }
    if (_controller.error case final error?) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _errorNotice(error),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _result(HistoryEntry entry) {
    final chart = widget.chartController;
    if (chart == null) return _detail(entry);
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Resumen'),
              Tab(text: 'Detalle'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _KeepAlive(child: _summary(entry, chart)),
                _KeepAlive(child: _detail(entry)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Avisos que valen para las dos pestañas: actualización en curso, error al
  /// actualizar (el resultado anterior sigue debajo, criterio 21) y datos
  /// antiguos.
  List<Widget> _notices(HistoryEntry entry) => [
    if (_controller.isLoading) AnalysisProgress(step: _controller.currentStep),
    if (_controller.error case final error?) _errorNotice(error),
    if (_controller.isStale) _staleNotice(entry),
  ];

  /// Pestaña Resumen: cabecera y gráfica de precio.
  Widget _summary(HistoryEntry entry, PriceChartController chart) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      ..._notices(entry),
      VerdictHeader(result: entry.result),
      const SizedBox(height: 16),
      PriceChartPanel(controller: chart, currency: entry.result.currency),
    ],
  );

  /// Pestaña Detalle: la vista de siempre.
  Widget _detail(HistoryEntry entry) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      ..._notices(entry),
      VerdictHeader(result: entry.result),
      _guideButton(),
      FlagsSection(flags: entry.result.flags),
      for (final block in entry.result.blocks)
        BlockTile(block: block, buildInfo: widget.buildInfo),
      MissingDataSection(missingData: entry.result.missingData),
      _newsButton(),
      const EducationalDisclaimer(),
    ],
  );

  /// "¿Cómo leer este diagnóstico?" (criterio 8 de `contenido_educativo`).
  Widget _guideButton() {
    final showInfo = widget.showInfo;
    if (showInfo == null) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        icon: const Icon(Icons.menu_book_outlined),
        label: const Text('¿Cómo leer este diagnóstico?'),
        onPressed: () => showInfo(context, diagnosisGuideTopicId),
      ),
    );
  }

  /// "Ver noticias recientes" (criterios 41-42).
  Widget _newsButton() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: OutlinedButton.icon(
      icon: const Icon(Icons.newspaper),
      label: const Text('Ver noticias recientes'),
      onPressed: _openNews,
    ),
  );

  Future<void> _openNews() async {
    final messenger = ScaffoldMessenger.of(context);
    final wasOpened = await _controller.openNews();
    if (wasOpened) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('No se ha podido abrir el navegador')),
    );
  }

  Widget _errorNotice(MarketDataException error) => ErrorNotice(
    message: errorMessage(error),
    onRetry: isRetryable(error) ? _controller.retry : null,
  );

  /// "Datos de hace X" (criterio 18).
  Widget _staleNotice(HistoryEntry entry) {
    final age = _controller.age ?? Duration.zero;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.history),
        title: Text('Datos de ${formatAge(age)}'),
        subtitle: Text(
          'Análisis del ${formatDate(entry.analyzedAt)}. Pulsa actualizar '
          'para obtener datos nuevos.',
        ),
      ),
    );
  }
}

/// Mantiene viva una pestaña al cambiar a otra, para que lo desplegado en ella
/// siga como se dejó (criterio 45).
class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
