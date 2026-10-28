import 'package:flutter/material.dart';

class AppTheme {
  // Paleta Estilo Neón / Fiesta Nocturna
  static const Color bgDark = Color(0xFF090614);
  static const Color bgCard = Color(0xFF150E2A);
  static const Color bgCardLight = Color(0xFF211740);

  static const Color neonPink = Color(0xFFFF2A85);
  static const Color neonCyan = Color(0xFF00F0FF);
  static const Color neonPurple = Color(0xFF9D4EDD);
  static const Color neonYellow = Color(0xFFFFD600);
  static const Color neonGreen = Color(0xFF00E676);
  static const Color neonOrange = Color(0xFFFF6D00);
  static const Color neonRed = Color(0xFFFF1744);

  static const LinearGradient mainBgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF090614),
      Color(0xFF140B29),
      Color(0xFF0B0518),
    ],
  );

  static const LinearGradient pinkPurpleGradient = LinearGradient(
    colors: [neonPink, neonPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanBlueGradient = LinearGradient(
    colors: [neonCyan, Color(0xFF0077FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldOrangeGradient = LinearGradient(
    colors: [neonYellow, neonOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<BoxShadow> neonGlow(Color color, {double blur = 18, double spread = 1}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.45),
        blurRadius: blur,
        spreadRadius: spread,
      ),
    ];
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary: neonPink,
        secondary: neonCyan,
        tertiary: neonYellow,
        surface: bgCard,
        error: neonRed,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: Colors.white,
        ),
      ),
    );
  }
}
