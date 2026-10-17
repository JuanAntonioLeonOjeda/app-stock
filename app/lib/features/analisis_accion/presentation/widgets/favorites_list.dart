import 'package:flutter/material.dart';
import 'package:stock_app/features/analisis_accion/domain/entities/favorite.dart';

/// Acciones favoritas: se abren al pulsarlas y se quitan con la estrella.
class FavoritesList extends StatelessWidget {
  const FavoritesList({
    super.key,
    required this.favorites,
    required this.onOpen,
    required this.onRemove,
  });

  final List<Favorite> favorites;
  final ValueChanged<Favorite> onOpen;
  final ValueChanged<Favorite> onRemove;

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
    return Column(
      children: [
        for (final favorite in favorites)
          Card(
            child: ListTile(
              title: Text(favorite.name),
              subtitle: Text(favorite.symbol),
              onTap: () => onOpen(favorite),
              trailing: IconButton(
                tooltip: 'Quitar ${favorite.name} de favoritos',
                icon: Icon(
                  Icons.star,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () => onRemove(favorite),
              ),
            ),
          ),
      ],
    );
  }
}
