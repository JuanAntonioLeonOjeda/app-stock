import 'package:flutter/material.dart';

/// Tema Material 3 de la app, claro u oscuro.
ThemeData buildAppTheme(Brightness brightness) => ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.indigo,
    brightness: brightness,
  ),
  useMaterial3: true,
);
