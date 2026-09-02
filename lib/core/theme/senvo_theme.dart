import 'package:flutter/material.dart';
import '../../core/risk/risk_enums.dart';

class SenvoColors {
  static const Color background = Color(0xFF0F1B24);
  static const Color surface = Color(0xFF16232D);
  static const Color surface2 = Color(0xFF1D2C36);
  static const Color border = Color(0xFF26363F);
  static const Color text = Color(0xFFEDF3F2);
  static const Color muted = Color(0xFF8FA3A0);
  static const Color accent = Color(0xFF4FD1C5);
  
  static const Color riskNormal = Color(0xFF3B6E5E);
  static const Color riskWatch = Color(0xFFC98A3A);
  static const Color riskAlert = Color(0xFFC1441E);
  static const Color riskEmergency = Color(0xFF8B1A1A);
  
  static Color colorForHealthRisk(HealthRiskLevel level) {
    switch (level) {
      case HealthRiskLevel.normal:
        return riskNormal;
      case HealthRiskLevel.watch:
        return riskWatch;
      case HealthRiskLevel.alert:
        return riskAlert;
      case HealthRiskLevel.emergency:
        return riskEmergency;
    }
  }

  static Color colorForRisk(RiskLevel level) {
    switch (level) {
      case RiskLevel.unknown:
        return muted;
      case RiskLevel.low:
        return riskNormal;
      case RiskLevel.moderate:
        return riskWatch;
      case RiskLevel.elevated:
        return riskAlert;
      case RiskLevel.high:
      case RiskLevel.critical:
        return riskEmergency;
    }
  }

  static Color colorForDataFreshness(DataFreshness freshness) {
    switch (freshness) {
      case DataFreshness.fresh:
      case DataFreshness.recent:
        return riskNormal;
      case DataFreshness.stale:
        return riskWatch;
      case DataFreshness.expired:
      case DataFreshness.unavailable:
        return muted;
    }
  }
}

class SenvoSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class SenvoRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
}

class SenvoTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: SenvoColors.background,
      primaryColor: SenvoColors.accent,
      colorScheme: const ColorScheme.dark(
        primary: SenvoColors.accent,
        surface: SenvoColors.surface,
        onSurface: SenvoColors.text,
      ),
      cardTheme: CardThemeData(
        color: SenvoColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SenvoRadius.lg),
          side: const BorderSide(color: SenvoColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: SenvoColors.border,
        thickness: 1,
        space: SenvoSpacing.lg,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Space Grotesk', color: SenvoColors.text, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(fontFamily: 'Space Grotesk', color: SenvoColors.text, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(fontFamily: 'Space Grotesk', color: SenvoColors.text, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(fontFamily: 'Space Grotesk', color: SenvoColors.text, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontFamily: 'Space Grotesk', color: SenvoColors.text, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(fontFamily: 'Space Grotesk', color: SenvoColors.text, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(fontFamily: 'Space Grotesk', color: SenvoColors.text, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontFamily: 'Space Grotesk', color: SenvoColors.text, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontFamily: 'Space Grotesk', color: SenvoColors.text, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontFamily: 'Inter', color: SenvoColors.text),
        bodyMedium: TextStyle(fontFamily: 'Inter', color: SenvoColors.text),
        bodySmall: TextStyle(fontFamily: 'Inter', color: SenvoColors.muted),
        labelLarge: TextStyle(fontFamily: 'Inter', color: SenvoColors.muted, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(fontFamily: 'Inter', color: SenvoColors.muted, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(fontFamily: 'Inter', color: SenvoColors.muted, fontWeight: FontWeight.w500),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: SenvoColors.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Space Grotesk',
          color: SenvoColors.text,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: SenvoColors.text),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: SenvoColors.surface,
        selectedItemColor: SenvoColors.accent,
        unselectedItemColor: SenvoColors.muted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
