import 'package:flutter/material.dart';

abstract final class AppPalette {
  static const ink = Color(0xFF302B38);
  static const mutedInk = Color(0xFF817A88);
  static const cream = Color(0xFFFCF9F5);
  static const lavender = Color(0xFFE9E0F4);
  static const lavenderDeep = Color(0xFF8771A3);
  static const pink = Color(0xFFF5E2E8);
  static const mint = Color(0xFFDDECE3);
  static const peach = Color(0xFFF5E4D5);
  static const yellow = Color(0xFFF4EDCE);
  static const line = Color(0xFFEDE7E2);
  static const white = Color(0xFFFFFEFC);

  static const noteColors = <Color>[
    Color(0xFFF4E9F2),
    Color(0xFFE6EDF6),
    Color(0xFFE4EFE5),
    Color(0xFFF6E8D9),
    Color(0xFFF5EDCF),
    Color(0xFFF2E5E4),
  ];

  static Color fromHex(String value) {
    final normalized = value.replaceFirst('#', '');
    final parsed = int.tryParse(normalized, radix: 16);
    return parsed == null ? lavender : Color(0xFF000000 | parsed);
  }

  static String toHex(Color color) =>
      '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
}

abstract final class AppSpacing {
  static const page = 22.0;
  static const small = 8.0;
  static const medium = 16.0;
  static const large = 24.0;
  static const section = 30.0;
  static const cardRadius = 22.0;
}

ThemeData buildAppTheme({required bool dark}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppPalette.lavenderDeep,
    brightness: dark ? Brightness.dark : Brightness.light,
    surface: dark ? const Color(0xFF24212A) : AppPalette.white,
  );
  final textTheme = ThemeData(brightness: dark ? Brightness.dark : Brightness.light)
      .textTheme
      .apply(
        bodyColor: dark ? const Color(0xFFF5F0F7) : AppPalette.ink,
        displayColor: dark ? const Color(0xFFF5F0F7) : AppPalette.ink,
        fontFamily: 'serif',
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? const Color(0xFF1D1B22) : AppPalette.cream,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? const Color(0xFF1D1B22) : AppPalette.cream,
      foregroundColor: dark ? Colors.white : AppPalette.ink,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF302D37) : AppPalette.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: AppPalette.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: AppPalette.lavenderDeep, width: 1.5),
      ),
      labelStyle: const TextStyle(color: AppPalette.mutedInk),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppPalette.lavenderDeep,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
        side: const BorderSide(color: AppPalette.line),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerColor: AppPalette.line,
  );
}
