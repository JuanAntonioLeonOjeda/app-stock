import 'package:flutter/material.dart';
import 'package:stock_app/features/ajustes/domain/entities/theme_preference.dart';
import 'package:stock_app/features/ajustes/presentation/controllers/theme_controller.dart';

/// Botón de la barra que abre el menú de tema (Sistema, Claro, Oscuro) y
/// enseña como icono la opción activa.
class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({super.key, required this.controller});

  final ThemeController controller;

  static String labelOf(ThemePreference preference) => switch (preference) {
    ThemePreference.system => 'Sistema',
    ThemePreference.light => 'Claro',
    ThemePreference.dark => 'Oscuro',
  };

  static IconData iconOf(ThemePreference preference) => switch (preference) {
    ThemePreference.system => Icons.brightness_auto_outlined,
    ThemePreference.light => Icons.light_mode_outlined,
    ThemePreference.dark => Icons.dark_mode_outlined,
  };

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => PopupMenuButton<ThemePreference>(
      tooltip: 'Tema: ${labelOf(controller.preference)}',
      icon: Icon(iconOf(controller.preference)),
      initialValue: controller.preference,
      onSelected: controller.select,
      itemBuilder: (context) => [
        for (final preference in ThemePreference.values)
          CheckedPopupMenuItem(
            value: preference,
            checked: preference == controller.preference,
            child: Text(labelOf(preference)),
          ),
      ],
    ),
  );
}
