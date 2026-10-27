import 'package:flutter/material.dart';

class BvtColors {
  static const saffron = Color(0xFFE8862A);
  static const deepSaffron = Color(0xFFC4600F);
  static const maroon = Color(0xFF6B2410);
  static const gold = Color(0xFFD4A62A);
  static const cream = Color(0xFFFFFAF2);
  static const sand = Color(0xFFF8EBD6);
  static const ink = Color(0xFF2A1A10);
  static const muted = Color(0xFF85705F);
  static const green = Color(0xFF2E7D4F);
  static const red = Color(0xFFC62828);
  static const whatsapp = Color(0xFF25D366);
  static const line = Color(0xFFF0E1C8);
}

const kFontFallback = ['NotoDeva'];

List<BoxShadow> softShadow([double a = 0.08]) => [
      BoxShadow(color: const Color(0xFF6B2410).withValues(alpha: a), blurRadius: 18, offset: const Offset(0, 6)),
    ];

ThemeData buildTheme({bool dark = false}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: BvtColors.saffron,
    brightness: dark ? Brightness.dark : Brightness.light,
    primary: dark ? const Color(0xFFFFB066) : BvtColors.deepSaffron,
    surface: dark ? const Color(0xFF1E1713) : BvtColors.cream,
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true, fontFamily: 'Poppins');
  final text = base.textTheme.apply(fontFamily: 'Poppins', fontFamilyFallback: kFontFallback, bodyColor: dark ? Colors.white : BvtColors.ink, displayColor: dark ? Colors.white : BvtColors.ink);
  final cardColor = dark ? const Color(0xFF261D18) : Colors.white;
  return base.copyWith(
    textTheme: text,
    primaryTextTheme: text,
    scaffoldBackgroundColor: dark ? const Color(0xFF16110E) : BvtColors.cream,
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? const Color(0xFF1E1713) : BvtColors.cream,
      foregroundColor: dark ? Colors.white : BvtColors.maroon,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontFamily: 'Poppins', fontFamilyFallback: kFontFallback, fontSize: 19, fontWeight: FontWeight.w700, color: dark ? Colors.white : BvtColors.maroon),
    ),
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: dark ? Colors.white10 : BvtColors.line)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        backgroundColor: BvtColors.deepSaffron,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 52),
        foregroundColor: BvtColors.deepSaffron,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: const BorderSide(color: BvtColors.deepSaffron, width: 1.2),
        textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: BvtColors.deepSaffron, textStyle: const TextStyle(fontWeight: FontWeight.w600))),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: BvtColors.line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: dark ? Colors.white24 : BvtColors.line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: BvtColors.deepSaffron, width: 1.6)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: cardColor,
      selectedColor: BvtColors.saffron.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      side: BorderSide(color: dark ? Colors.white24 : BvtColors.line),
      labelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w500),
      showCheckmark: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      elevation: 12,
      shadowColor: const Color(0x33000000),
      surfaceTintColor: Colors.transparent,
      backgroundColor: dark ? const Color(0xFF1E1713) : Colors.white,
      indicatorColor: BvtColors.saffron.withValues(alpha: 0.2),
      labelTextStyle: const WidgetStatePropertyAll(TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600)),
    ),
    dividerTheme: DividerThemeData(color: dark ? Colors.white12 : BvtColors.line, space: 1),
    snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor: BvtColors.ink, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
    listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 16)),
    dialogTheme: DialogThemeData(backgroundColor: cardColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: cardColor, surfaceTintColor: Colors.transparent, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26)))),
    segmentedButtonTheme: SegmentedButtonThemeData(style: ButtonStyle(shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), textStyle: const WidgetStatePropertyAll(TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13)))),
  );
}
