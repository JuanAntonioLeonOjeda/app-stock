import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stock_app/core/theme/signal_colors.dart';

const _sans = 'IBMPlexSans';
const _serif = 'IBMPlexSerif';

/// Cifras de ancho fijo: los importes y las notas se alinean en columna.
const _tabular = [FontFeature.tabularFigures()];

const _petrol = Color(0xFF1D4E5F);

/// Tema de la app, claro u oscuro: tinta verdosa sobre papel, con un azul
/// petróleo como único color de marca. El semáforo tiene su propia paleta
/// ([SignalColors]); la marca nunca se usa para indicar "bueno" o "malo".
ThemeData buildAppTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme = _colorScheme(brightness);
  final text = _textTheme(scheme);
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    textTheme: text,
    fontFamily: _sans,
    extensions: [isDark ? SignalColors.dark : SignalColors.light],
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge,
      systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      space: 1,
      thickness: 1,
    ),
    tabBarTheme: TabBarThemeData(
      labelStyle: text.titleSmall,
      unselectedLabelStyle: text.titleSmall,
      labelColor: scheme.primary,
      unselectedLabelColor: scheme.onSurfaceVariant,
      indicatorSize: TabBarIndicatorSize.tab,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: scheme.primary, width: 3),
      ),
      dividerColor: scheme.outlineVariant,
    ),
    expansionTileTheme: const ExpansionTileThemeData(
      shape: Border(),
      collapsedShape: Border(),
      tilePadding: EdgeInsets.symmetric(horizontal: 16),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: scheme.onSurfaceVariant,
      subtitleTextStyle: text.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
    ),
    chipTheme: ChipThemeData(
      side: BorderSide(color: scheme.outlineVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      labelStyle: text.labelLarge,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: scheme.outlineVariant),
        textStyle: text.labelLarge,
        visualDensity: VisualDensity.compact,
        minimumSize: const Size(48, 44),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(style: _buttonStyle()),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: _buttonStyle().copyWith(
        side: WidgetStatePropertyAll(BorderSide(color: scheme.outline)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: _buttonStyle()),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

ButtonStyle _buttonStyle() => ButtonStyle(
  minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
  shape: WidgetStatePropertyAll(
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
);

ColorScheme _colorScheme(Brightness brightness) {
  final base = ColorScheme.fromSeed(seedColor: _petrol, brightness: brightness);
  if (brightness == Brightness.dark) {
    return base.copyWith(
      primary: const Color(0xFF8CC4D1),
      onPrimary: const Color(0xFF08262E),
      surface: const Color(0xFF0F1514),
      onSurface: const Color(0xFFE4EBE8),
      onSurfaceVariant: const Color(0xFFA3B2AD),
      surfaceContainerLowest: const Color(0xFF131C1B),
      surfaceContainerHigh: const Color(0xFF1C2827),
      outline: const Color(0xFF6B7C77),
      outlineVariant: const Color(0xFF2C3A38),
    );
  }
  return base.copyWith(
    primary: _petrol,
    onPrimary: Colors.white,
    surface: const Color(0xFFF4F6F3),
    onSurface: const Color(0xFF172321),
    onSurfaceVariant: const Color(0xFF55645F),
    surfaceContainerLowest: Colors.white,
    surfaceContainerHigh: const Color(0xFFE6ECE8),
    outline: const Color(0xFF7C8B86),
    outlineVariant: const Color(0xFFD3DBD7),
  );
}

/// Escala tipográfica: IBM Plex Sans para la interfaz y los números; Plex
/// Serif en `bodyLarge`, que solo usa el texto educativo, para que se lea
/// como una explicación y no como un dato.
TextTheme _textTheme(ColorScheme scheme) {
  TextStyle sans(double size, FontWeight weight, {double height = 1.35}) =>
      TextStyle(
        fontFamily: _sans,
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: scheme.onSurface,
        fontFeatures: _tabular,
      );
  return TextTheme(
    displaySmall: sans(
      34,
      FontWeight.w600,
      height: 1.1,
    ).copyWith(letterSpacing: -0.8),
    headlineSmall: sans(22, FontWeight.w600, height: 1.25),
    titleLarge: sans(20, FontWeight.w600, height: 1.25),
    titleMedium: sans(16, FontWeight.w600),
    titleSmall: sans(14, FontWeight.w600),
    bodyLarge: TextStyle(
      fontFamily: _serif,
      fontSize: 16,
      height: 1.6,
      color: scheme.onSurface,
    ),
    bodyMedium: sans(14, FontWeight.w400, height: 1.45),
    bodySmall: sans(
      12.5,
      FontWeight.w400,
      height: 1.4,
    ).copyWith(color: scheme.onSurfaceVariant),
    labelLarge: sans(14, FontWeight.w500),
    labelMedium: sans(12.5, FontWeight.w500),
    labelSmall: sans(11.5, FontWeight.w500),
  );
}
