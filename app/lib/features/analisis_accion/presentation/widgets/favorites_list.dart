import 'package:flutter/material.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/favorite.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/history_entry.dart';
import 'package:stock_app/features/analisis_accion/presentation/formatters/metric_value_formatter.dart';
import 'package:stock_app/features/analisis_accion/presentation/widgets/verdict_badge.dart';

/// Acciones favoritas como tarjetas en dos columnas: se abren al pulsarlas y
/// se quitan con la estrella. Si hay un análisis guardado de la acción,
/// la tarjeta enseña su último veredicto, nota y precio.
class FavoritesList extends StatelessWidget {
  const FavoritesList({
    super.key,
    required this.favorites,
    required this.onOpen,
    required this.onRemove,
    this.history = const [],
  });

  static const _gap = 12.0;

  final List<Favorite> favorites;
  final ValueChanged<Favorite> onOpen;
  final ValueChanged<Favorite> onRemove;

  /// Análisis guardados, de donde sale el último resultado de cada favorita.
  final List<HistoryEntry> history;

  /// El análisis más reciente de [favorite], si lo hay.
  HistoryEntry? _latestFor(Favorite favorite) {
    final symbol = favorite.symbol.toUpperCase();
    HistoryEntry? latest;
    for (final entry in history) {
      if (entry.result.symbol.toUpperCase() != symbol) continue;
      if (latest == null || entry.analyzedAt.isAfter(latest.analyzedAt)) {
        latest = entry;
      }
    }
    return latest;
  }

  @override
  Widget build(BuildContext context) {
    if (favorites.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Aún no tienes favoritas. Abre una acción y pulsa la estrella '
          'para verla aquí.',
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - _gap) / 2;
        return Wrap(
          spacing: _gap,
          runSpacing: _gap,
          children: [
            for (final favorite in favorites)
              SizedBox(
                width: width,
                child: _FavoriteCard(
                  favorite: favorite,
                  latest: _latestFor(favorite),
                  onOpen: () => onOpen(favorite),
                  onRemove: () => onRemove(favorite),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.favorite,
    required this.latest,
    required this.onOpen,
    required this.onRemove,
  });

  final Favorite favorite;
  final HistoryEntry? latest;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  /// Hasta dos iniciales del nombre, para el avatar.
  String get _initials {
    final words = favorite.name.trim().split(RegExp(r'\s+'));
    final letters = words
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0].toUpperCase());
    return letters.join();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                    child: Text(_initials, style: text.labelLarge),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Quitar ${favorite.name} de favoritos',
                    icon: Icon(Icons.star, color: theme.colorScheme.primary),
                    onPressed: onRemove,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      favorite.name,
                      style: text.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(favorite.symbol, style: text.bodySmall),
                    ..._lastResult(text),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Precio, veredicto y nota del último análisis guardado.
  List<Widget> _lastResult(TextTheme text) {
    final result = latest?.result;
    if (result == null) return const [];
    return [
      const SizedBox(height: 12),
      Text(formatPrice(result.price, result.currency), style: text.titleMedium),
      const SizedBox(height: 6),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          VerdictBadge(verdict: result.verdict),
          if (result.globalScore case final score?)
            Text('${formatScore(score)} / 10', style: text.labelMedium),
        ],
      ),
    ];
  }
}
