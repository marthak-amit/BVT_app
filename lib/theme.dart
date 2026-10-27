import 'package:flutter/material.dart';

class BvtColors {
  static const saffron = Color(0xFFE07A1F);
  static const deepSaffron = Color(0xFFC25E0C);
  static const maroon = Color(0xFF7A2E0E);
  static const gold = Color(0xFFC9A227);
  static const cream = Color(0xFFFFF8EE);
  static const sand = Color(0xFFF6E7CF);
  static const ink = Color(0xFF2B1B10);
  static const muted = Color(0xFF7C6A5B);
  static const green = Color(0xFF2E7D32);
  static const red = Color(0xFFC62828);
  static const whatsapp = Color(0xFF25D366);
}

ThemeData buildTheme({bool dark = false, double fontScale = 1}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: BvtColors.saffron,
    brightness: dark ? Brightness.dark : Brightness.light,
    primary: dark ? const Color(0xFFFFB066) : BvtColors.deepSaffron,
    surface: dark ? const Color(0xFF1E1713) : BvtColors.cream,
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: dark ? const Color(0xFF16110E) : BvtColors.cream,
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? const Color(0xFF1E1713) : BvtColors.cream,
      foregroundColor: dark ? Colors.white : BvtColors.maroon,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: dark ? Colors.white : BvtColors.maroon,
      ),
    ),
    cardTheme: CardThemeData(
      color: dark ? const Color(0xFF241C17) : Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: dark ? Colors.white12 : const Color(0xFFEBD9BC)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: scheme.primary),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF241C17) : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2CFAE)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: dark ? Colors.white24 : const Color(0xFFE2CFAE)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(color: dark ? Colors.white24 : const Color(0xFFE2CFAE)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? const Color(0xFF1E1713) : Colors.white,
      indicatorColor: BvtColors.saffron.withValues(alpha: 0.2),
      labelTextStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
    ),
    dividerTheme: DividerThemeData(color: dark ? Colors.white12 : const Color(0xFFEBD9BC), space: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
