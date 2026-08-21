import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class M3ExpressiveTheme {
  // Brand colors tailored for Swedish ÖPNV (Nordic Cyan, Dynamic Transit Navy, Gold accent)
  static const Color primarySeed = Color(0xFF0065A9); // Swedish Transit Royal Blue
  static const Color secondarySeed = Color(0xFF00A896); // Nordic Cyan/Teal
  static const Color tertiarySeed = Color(0xFFFFB703); // Expressive Yellow/Gold

  // Custom transit status colors
  static const Color statusOnTime = Color(0xFF10B981); // Vibrant Emerald
  static const Color statusDelayed = Color(0xFFF59E0B); // Amber / Orange
  static const Color statusCancelled = Color(0xFFEF4444); // Crimson Red
  static const Color statusPlatformChange = Color(0xFF8B5CF6); // Expressive Violet

  static ThemeData lightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primarySeed,
      brightness: Brightness.light,
      primary: primarySeed,
      secondary: secondarySeed,
      tertiary: tertiarySeed,
      surface: const Color(0xFFF8FAFC),
      surfaceContainerLowest: const Color(0xFFFFFFFF),
      surfaceContainerLow: const Color(0xFFF1F5F9),
      surfaceContainer: const Color(0xFFE2E8F0),
      surfaceContainerHigh: const Color(0xFFCBD5E1),
      surfaceContainerHighest: const Color(0xFF94A3B8),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w600, letterSpacing: -0.2),
        bodyLarge: GoogleFonts.inter(fontWeight: FontWeight.w400),
        bodyMedium: GoogleFonts.inter(fontWeight: FontWeight.w400),
        labelLarge: GoogleFonts.outfit(fontWeight: FontWeight.w600, letterSpacing: 0.1),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: colorScheme.surfaceContainerLowest,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        elevation: 3,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        showDragHandle: true,
      ),
    );
  }

  static ThemeData darkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primarySeed,
      brightness: Brightness.dark,
      primary: const Color(0xFF38BDF8), // Electric Sky Blue
      secondary: const Color(0xFF2DD4BF), // Dynamic Teal
      tertiary: const Color(0xFFFBBF24), // Dynamic Warm Gold
      surface: const Color(0xFF0F172A), // Slate 900
      surfaceContainerLowest: const Color(0xFF020617), // Slate 950
      surfaceContainerLow: const Color(0xFF1E293B), // Slate 800
      surfaceContainer: const Color(0xFF334155), // Slate 700
      surfaceContainerHigh: const Color(0xFF475569),
      surfaceContainerHighest: const Color(0xFF64748B),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w600, letterSpacing: -0.2),
        bodyLarge: GoogleFonts.inter(fontWeight: FontWeight.w400),
        bodyMedium: GoogleFonts.inter(fontWeight: FontWeight.w400),
        labelLarge: GoogleFonts.outfit(fontWeight: FontWeight.w600, letterSpacing: 0.1),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: colorScheme.surfaceContainerLow,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        elevation: 4,
        backgroundColor: colorScheme.surfaceContainerLowest,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        showDragHandle: true,
      ),
    );
  }
}
