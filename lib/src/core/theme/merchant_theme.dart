import 'package:flutter/material.dart';

class MerchantTheme {
  // ─── Color Palette ───
  static const Color bgDark = Color(0xFF0A1A0F);
  static const Color bgCard = Color(0xFF0D2B15);
  static const Color bgCardInner = Color(0xFF0F3318);
  static const Color accentGreen = Color(0xFF00FF41);
  static const Color dimGreen = Color(0xFF1B5E20);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF81C784);
  static const Color textMuted = Color(0xFF4CAF50);
  static const Color tabInactive = Color(0xFF9E9E9E);
  static const Color rejectRed = Color(0xFF00FF41);
  static const Color navBarBg = Color(0xFF0D1F12);
  static const Color dividerColor = Color(0xFF1B3D22);

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgDark,
        colorScheme: const ColorScheme.dark(
          primary: accentGreen,
          secondary: accentGreen,
          surface: bgCard,
          onPrimary: Color(0xFF003300),
          onSecondary: Color(0xFF003300),
          onSurface: textPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: bgDark,
          foregroundColor: textPrimary,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: bgCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: dimGreen, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: navBarBg,
          indicatorColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: accentGreen,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              );
            }
            return const TextStyle(
              color: tabInactive,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: accentGreen, size: 24);
            }
            return const IconThemeData(color: tabInactive, size: 24);
          }),
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: accentGreen,
          unselectedLabelColor: tabInactive,
          indicatorColor: accentGreen,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: dividerColor,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        useMaterial3: true,
      );
}
