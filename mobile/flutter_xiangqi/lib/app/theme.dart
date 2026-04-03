import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Xiangqi Design System
//
// Palette inspired by the web version:
//   • Parchment / warm ivory backgrounds
//   • Antique gold border + accent
//   • Deep crimson red for primary actions
//   • Dark brown for text and structural elements
// ─────────────────────────────────────────────────────────────────────────────

class XiangqiColors {
  XiangqiColors._();

  // Core palette
  static const Color parchment     = Color(0xFFFAF0DC); // warm ivory panel bg
  static const Color parchmentDark = Color(0xFFF5E6C8); // slightly deeper
  static const Color gold          = Color(0xFFB8860B); // antique gold
  static const Color goldLight     = Color(0xFFD4AF37); // brighter gold accent
  static const Color goldDark      = Color(0xFF8B6914); // deep gold border
  static const Color crimson       = Color(0xFFC0392B); // deep red → START GAME
  static const Color crimsonDark   = Color(0xFF96281B); // hover/pressed red
  static const Color crimsonLight  = Color(0xFFE74C3C); // lighter shade
  static const Color darkBrown     = Color(0xFF3E1F00); // near-black brown text
  static const Color medBrown      = Color(0xFF6B3A2A); // mid-toned brown
  static const Color lightBrown    = Color(0xFF8B5E3C); // label text
  static const Color overlayDark   = Color(0xCC1A0A00); // dark scrim over bg

  // Board
  static const Color boardWood   = Color(0xFFF5CBA7);
  static const Color boardLine   = Color(0xFF6D4C41);
  static const Color boardBorder = Color(0xFF4E342E);
  static const Color riverBlue   = Color(0xFFCCE5F3);
}

class XiangqiTextStyles {
  XiangqiTextStyles._();

  static const TextStyle displayTitle = TextStyle(
    fontFamily: 'serif',
    fontSize: 42,
    fontWeight: FontWeight.w900,
    letterSpacing: 6,
    color: XiangqiColors.darkBrown,
    height: 1.1,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 5,
    color: XiangqiColors.medBrown,
  );

  static const TextStyle label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 2.5,
    color: XiangqiColors.lightBrown,
  );

  static const TextStyle dropdownValue = TextStyle(
    fontSize: 14,
    color: XiangqiColors.darkBrown,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle startButton = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    letterSpacing: 4,
    color: Colors.white,
  );

  static const TextStyle bannerText = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 1,
    color: XiangqiColors.parchment,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Decoration helpers
// ─────────────────────────────────────────────────────────────────────────────

class XiangqiDecorations {
  XiangqiDecorations._();

  /// Gold-bordered parchment panel (the centered card).
  static BoxDecoration get panel => BoxDecoration(
    color: XiangqiColors.parchment,
    border: Border.all(color: XiangqiColors.gold, width: 1.5),
    boxShadow: const [
      BoxShadow(
        color: Color(0x88000000),
        blurRadius: 32,
        spreadRadius: 4,
        offset: Offset(0, 8),
      ),
    ],
  );

  /// Subtle inner shadow for dropdown fields.
  static BoxDecoration dropdownField(Color borderColor) => BoxDecoration(
    color: XiangqiColors.parchment,
    border: Border(bottom: BorderSide(color: borderColor, width: 1)),
  );

  /// Dark brown header bar (AppBar).
  static const Color appBarBg = XiangqiColors.darkBrown;
}

// ─────────────────────────────────────────────────────────────────────────────
// MaterialTheme
// ─────────────────────────────────────────────────────────────────────────────

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: XiangqiColors.crimson,
        brightness: Brightness.light,
      ).copyWith(
        primary: XiangqiColors.crimson,
        secondary: XiangqiColors.gold,
        surface: XiangqiColors.parchment,
        onSurface: XiangqiColors.darkBrown,
        error: XiangqiColors.crimsonDark,
      ),
      scaffoldBackgroundColor: XiangqiColors.darkBrown,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: XiangqiColors.darkBrown,
        foregroundColor: XiangqiColors.goldLight,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 3,
          color: XiangqiColors.goldLight,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: XiangqiColors.crimson,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: XiangqiColors.crimsonDark.withAlpha(180),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          textStyle: XiangqiTextStyles.startButton,
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: Color(0xFF5A2D00),
        labelStyle: TextStyle(color: XiangqiColors.parchment, fontSize: 13),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: XiangqiColors.darkBrown,
        contentTextStyle: TextStyle(color: XiangqiColors.parchment),
      ),
    );
  }
}
