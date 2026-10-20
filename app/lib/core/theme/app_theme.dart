import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stock_app/core/theme/signal_colors.dart';

const _sans = 'PlusJakartaSans';

/// Cifras de ancho fijo: los importes y las notas se alinean en columna.
const _tabular = [FontFeature.tabularFigures()];

const _indigo = Color(0xFF4338CA);

/// Tema de la app, claro u oscuro: superficies limpias con tarjetas sin borde
/// y esquinas amplias, y un índigo vivo como único color de marca. El semáforo tiene su propia paleta
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
      titleSpacing: 20,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
      indicator: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      dividerColor: Colors.transparent,
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
      side: BorderSide.none,
      backgroundColor: scheme.surfaceContainerHigh,
      shape: const StadiumBorder(),
      labelStyle: text.labelLarge,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        shape: const StadiumBorder(),
        side: BorderSide.none,
        backgroundColor: scheme.surfaceContainerHigh,
        selectedBackgroundColor: scheme.primaryContainer,
        selectedForegroundColor: scheme.onPrimaryContainer,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}

ButtonStyle _buttonStyle() => ButtonStyle(
  minimumSize: const WidgetStatePropertyAll(Size(48, 52)),
  shape: const WidgetStatePropertyAll(StadiumBorder()),
);

ColorScheme _colorScheme(Brightness brightness) {
  final base = ColorScheme.fromSeed(seedColor: _indigo, brightness: brightness);
  if (brightness == Brightness.dark) {
    return base.copyWith(
      primary: const Color(0xFFA5ACFF),
      onPrimary: const Color(0xFF14124D),
      primaryContainer: const Color(0xFF2B2A6B),
      onPrimaryContainer: const Color(0xFFE0E2FF),
      surface: const Color(0xFF0B0D12),
      onSurface: const Color(0xFFEDEFF5),
      onSurfaceVariant: const Color(0xFFA0A6B8),
      surfaceContainerLowest: const Color(0xFF151821),
      surfaceContainerHigh: const Color(0xFF1F2330),
      outline: const Color(0xFF6C7388),
      outlineVariant: const Color(0xFF2A2F3D),
    );
  }
  return base.copyWith(
    primary: _indigo,
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFE3E4FF),
    onPrimaryContainer: const Color(0xFF1B1A66),
    surface: const Color(0xFFF4F5FA),
    onSurface: const Color(0xFF12141C),
    onSurfaceVariant: const Color(0xFF575D70),
    surfaceContainerLowest: Colors.white,
    surfaceContainerHigh: const Color(0xFFE8EAF2),
    outline: const Color(0xFF7A8096),
    outlineVariant: const Color(0xFFDDE0EA),
  );
}

/// Escala tipográfica: Plus Jakarta Sans en toda la app, con cifras de ancho
/// fijo. `bodyLarge`, que solo usa el texto educativo, es algo más grande y
/// con más interlineado para que se lea como una explicación.
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
      40,
      FontWeight.w700,
      height: 1.1,
    ).copyWith(letterSpacing: -1.2),
    headlineSmall: sans(22, FontWeight.w700, height: 1.25),
    titleLarge: sans(20, FontWeight.w700, height: 1.25),
    titleMedium: sans(16, FontWeight.w600),
    titleSmall: sans(14, FontWeight.w600),
    bodyLarge: sans(16, FontWeight.w400, height: 1.6),
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
