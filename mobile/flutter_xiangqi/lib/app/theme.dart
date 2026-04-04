import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Xiangqi Design System
//
// Palette taken 1-to-1 from  staticfiles/games/css/start-screen.css  :root
// ─────────────────────────────────────────────────────────────────────────────

class XiangqiColors {
  XiangqiColors._();

  // ── Background ───────────────────────────────────────────────────────────
  static const Color bgDark      = Color(0xFF0A0503); // blacker outer edge
  static const Color bgMid       = Color(0xFF4A1510); // red/hollow centre

  // ── Frame / scroll rod wood ──────────────────────────────────────────────
  static const Color frameLight  = Color(0xFFA06B3D);
  static const Color frameMid    = Color(0xFF8D5A30);
  static const Color frameDark   = Color(0xFF6A3F1F);

  // ── Parchment ────────────────────────────────────────────────────────────
  static const Color parchment     = Color(0xFFF7F0E0); // aged ivory
  static const Color parchmentDark = Color(0xFFF5EDD8); // dropdown bg

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textTitle   = Color(0xFF4A2C0A); // warm ink-brown title
  static const Color textBody    = Color(0xFF4B2D1E); // body/value text
  static const Color textMuted   = Color(0xFF7A5020); // subtitle / labels

  // Keep legacy aliases used elsewhere in the app
  static const Color darkBrown   = Color(0xFF3E1F00);
  static const Color medBrown    = Color(0xFF7A5020);
  static const Color lightBrown  = Color(0xFF7A5020);
  static const Color overlayDark = Color(0xCC1A0A00);

  // ── Button – red lacquer ─────────────────────────────────────────────────
  static const Color crimson     = Color(0xFFC42028); // top of gradient
  static const Color crimsonDark = Color(0xFF8C1318); // bottom of gradient
  static const Color crimsonLight= Color(0xFFD62530); // hover top

  // ── Gold / brass ─────────────────────────────────────────────────────────
  static const Color gold        = Color(0xFFCAA76A); // main gold
  static const Color goldLight   = Color(0xFFD4AF37); // bright accent
  static const Color goldDark    = Color(0xFF8B692A); // deep border gold

  // ── Scroll rod gradient stops (top bar) ──────────────────────────────────
  static const List<Color> scrollRodColors = [
    Color(0xFFC8A058),
    Color(0xFF8C5E26),
    Color(0xFF6B4418),
    Color(0xFFB08040),
  ];

  // ── Board ────────────────────────────────────────────────────────────────
  static const Color boardWood   = Color(0xFFF5CBA7);
  static const Color boardLine   = Color(0xFF6D4C41);
  static const Color boardBorder = Color(0xFF4E342E);
  static const Color riverBlue   = Color(0xFFCCE5F3);
}

// ─────────────────────────────────────────────────────────────────────────────
// Text Styles – Google Fonts matching the web's Cinzel + Noto Serif combo
// ─────────────────────────────────────────────────────────────────────────────

class XiangqiTextStyles {
  XiangqiTextStyles._();

  /// "XIANGQI" — large Cinzel display title, warm ink-brown
  static TextStyle get displayTitle => GoogleFonts.cinzel(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    letterSpacing: 5,
    color: XiangqiColors.textTitle,
    height: 1.1,
    shadows: const [
      Shadow(color: Color(0x2C000000), offset: Offset(0, 2), blurRadius: 4),
    ],
  );

  /// "PREPARE FOR BATTLE" — smaller Cinzel, muted brown, letter-spaced
  static TextStyle get subtitle => GoogleFonts.cinzel(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 3,
    color: XiangqiColors.textMuted,
  );

  /// Form labels — "DIFFICULTY:" / "PLAY AS:"
  static TextStyle get label => GoogleFonts.cinzel(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 2,
    color: XiangqiColors.textMuted,
  );

  /// Dropdown selected value — Noto Serif, warm brown
  static TextStyle get dropdownValue => GoogleFonts.notoSerif(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: XiangqiColors.textBody,
  );

  /// "START GAME" button — Cinzel, letter-spaced, warm ivory
  static TextStyle get startButton => GoogleFonts.cinzel(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 5,
    color: const Color(0xFFF5E8C0), // warm ivory matching web
  );

  /// AppBar / banner text
  static TextStyle get bannerText => GoogleFonts.cinzel(
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

  /// Inner parchment panel body — aged ivory with subtle sheen + border.
  /// The gold scroll rods are added by FramedPanel as positioned widgets.
  static BoxDecoration get panel => BoxDecoration(
    color: XiangqiColors.parchment,
    // Very subtle gradient: white sheen at top fading out
    gradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFCF5E8), // slightly brighter top
        Color(0xFFF7F0E0), // main parchment
      ],
      stops: [0.0, 0.18],
    ),
    // Thin lacquer-brown border lines, matching web exactly
    border: Border(
      top:    BorderSide(color: Color(0x59885A2A), width: 1),// 35% opacity
      bottom: BorderSide(color: Color(0x59885A2A), width: 1),
      left:   BorderSide(color: Color(0x2E885A2A), width: 1),// 18% opacity
      right:  BorderSide(color: Color(0x2E885A2A), width: 1),
    ),
    boxShadow: const [
      BoxShadow(
        color: Color(0x8C14070A),
        blurRadius: 60,
        offset: Offset(0, 20),
      ),
      BoxShadow(
        color: Color(0x5914070A),
        blurRadius: 18,
        offset: Offset(0, 6),
      ),
    ],
  );

  /// Dropdown field — transparent with only a bottom line
  static BoxDecoration dropdownField(Color borderColor) => BoxDecoration(
    color: Colors.transparent,
    border: Border(bottom: BorderSide(color: borderColor, width: 1)),
  );

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
      scaffoldBackgroundColor: XiangqiColors.bgDark,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: XiangqiColors.darkBrown,
        foregroundColor: XiangqiColors.goldLight,
        elevation: 0,
        titleTextStyle: XiangqiTextStyles.bannerText,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: XiangqiColors.crimson,
          foregroundColor: const Color(0xFFF5E8C0),
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
