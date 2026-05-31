import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Palette ────────────────────────────────────────────────────
  static const bg = Color(0xFF0A0A0F);
  static const surface = Color(0xFF13131A);
  static const card = Color(0xFF1C1C26);
  static const border = Color(0xFF2A2A38);
  static const accent = Color(0xFF00E5C3);       // teal-green neon
  static const accentDim = Color(0xFF00C4A8);
  static const danger = Color(0xFFFF4E6A);
  static const warning = Color(0xFFFFB84D);
  static const textPrimary = Color(0xFFF0F0FF);
  static const textSecondary = Color(0xFF8080A0);
  static const textMuted = Color(0xFF4A4A60);

  static ThemeData get theme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      primary: accent,
      secondary: accentDim,
      surface: surface,
      error: danger,
    ),
    textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.spaceGrotesk(color: textPrimary, fontWeight: FontWeight.w700),
      displayMedium: GoogleFonts.spaceGrotesk(color: textPrimary, fontWeight: FontWeight.w700),
      headlineLarge: GoogleFonts.spaceGrotesk(color: textPrimary, fontWeight: FontWeight.w600),
      headlineMedium: GoogleFonts.spaceGrotesk(color: textPrimary, fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.spaceGrotesk(color: textPrimary, fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.dmSans(color: textPrimary),
      bodyMedium: GoogleFonts.dmSans(color: textSecondary),
    ),
    cardTheme: const CardThemeData(
      color: card,
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    dividerColor: border,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accent, width: 1.5),
      ),
      labelStyle: const TextStyle(color: textSecondary),
      hintStyle: const TextStyle(color: textMuted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: accent,
      unselectedItemColor: textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}
