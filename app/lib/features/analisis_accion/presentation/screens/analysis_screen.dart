import 'package:flutter/material.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/history_entry.dart';
import 'package:stock_app/features/analisis_accion/domain/exceptions/market_data_exception.dart';
import 'package:stock_app/features/analisis_accion/presentation/controllers/analysis_controller.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/error_messages.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/labels.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/metric_value_formatter.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/analysis_progress.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/block_tile.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/educational_disclaimer.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/error_notice.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/flags_section.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/missing_data_section.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/show_info.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/verdict_header.dart';

/// Resultado del análisis de una acción. Es dueña de su [controller] (lo
/// libera al cerrarse).
class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key, required this.controller, this.showInfo});

  final AnalysisController controller;

  /// Abre la explicación educativa de un tema; sin ella no hay iconos de
  /// información ni botón de la guía.
  final ShowInfo? showInfo;

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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
            onPressed: _controller.canRefresh ? _controller.refresh : null,
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

  Widget _result(HistoryEntry entry) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      if (_controller.isLoading)
        AnalysisProgress(step: _controller.currentStep),
      // Si falla una actualización, el resultado anterior sigue debajo
      // (criterio 21).
      if (_controller.error case final error?) _errorNotice(error),
      if (_controller.isStale) _staleNotice(entry),
      VerdictHeader(result: entry.result),
      _guideButton(),
      FlagsSection(flags: entry.result.flags),
      for (final block in entry.result.blocks)
        BlockTile(block: block, showInfo: widget.showInfo),
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
