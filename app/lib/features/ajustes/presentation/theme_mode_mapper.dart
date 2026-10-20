import 'package:flutter/material.dart';
import 'package:stock_app/features/ajustes/domain/entities/theme_preference.dart';

/// El [ThemeMode] de Flutter que corresponde a [preference].
ThemeMode themeModeFor(ThemePreference preference) => switch (preference) {
  ThemePreference.system => ThemeMode.system,
  ThemePreference.light => ThemeMode.light,
  ThemePreference.dark => ThemeMode.dark,
};
