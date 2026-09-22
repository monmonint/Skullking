import 'package:flutter/material.dart';

/// Thème nautique original : nuit marine, accents teal/cyan.
/// Aucun graphisme ScoreNow.
class AppTheme {
  static const Color bg = Color(0xFF06141B);
  static const Color bgLift = Color(0xFF0C2832);
  static const Color surface = Color(0xFF0E2430);
  static const Color surface2 = Color(0xFF143646);
  static const Color accent = Color(0xFF2AD4C8);
  static const Color accentDeep = Color(0xFF128F86);
  static const Color gold = Color(0xFFE4B15A);
  static const Color danger = Color(0xFFFF6B6B);
  static const Color success = Color(0xFF3DDC97);
  static const Color text = Color(0xFFE8F4F6);
  static const Color muted = Color(0xFF8EAEB8);
  static const Color cardBorder = Color(0xFF1E4C5C);
  static const Color ink = Color(0xFF042226);

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accent,
        surface: surface,
        error: danger,
        onPrimary: ink,
        onSecondary: ink,
        onSurface: text,
      ),
      scaffoldBackgroundColor: bg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: text,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: ink,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: const BorderSide(color: cardBorder, width: 1.4),
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        labelStyle: const TextStyle(color: muted),
        hintStyle: const TextStyle(color: muted),
      ),
      dividerColor: cardBorder,
      dialogTheme: const DialogThemeData(backgroundColor: surface),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface2,
        selectedColor: accent,
        disabledColor: surface2,
        labelStyle: const TextStyle(color: text, fontWeight: FontWeight.w600),
        secondaryLabelStyle:
            const TextStyle(color: ink, fontWeight: FontWeight.w800),
        side: const BorderSide(color: cardBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return muted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accent.withValues(alpha: 0.35);
          }
          return surface2;
        }),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: accent,
        textColor: text,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: accent),
    );
    return base;
  }
}
