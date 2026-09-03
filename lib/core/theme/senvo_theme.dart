import 'package:flutter/material.dart';
import '../../core/risk/risk_enums.dart';

class SenvoThemeColors extends ThemeExtension<SenvoThemeColors> {
  final Color background;
  final Color surface;
  final Color surface2;
  final Color border;
  final Color text;
  final Color muted;
  final Color accent;
  
  final Color riskNormal;
  final Color riskWatch;
  final Color riskAlert;
  final Color riskEmergency;

  const SenvoThemeColors({
    required this.background,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.text,
    required this.muted,
    required this.accent,
    required this.riskNormal,
    required this.riskWatch,
    required this.riskAlert,
    required this.riskEmergency,
  });

  @override
  ThemeExtension<SenvoThemeColors> copyWith({
    Color? background,
    Color? surface,
    Color? surface2,
    Color? border,
    Color? text,
    Color? muted,
    Color? accent,
    Color? riskNormal,
    Color? riskWatch,
    Color? riskAlert,
    Color? riskEmergency,
  }) {
    return SenvoThemeColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      border: border ?? this.border,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      accent: accent ?? this.accent,
      riskNormal: riskNormal ?? this.riskNormal,
      riskWatch: riskWatch ?? this.riskWatch,
      riskAlert: riskAlert ?? this.riskAlert,
      riskEmergency: riskEmergency ?? this.riskEmergency,
    );
  }

  @override
  ThemeExtension<SenvoThemeColors> lerp(ThemeExtension<SenvoThemeColors>? other, double t) {
    if (other is! SenvoThemeColors) {
      return this;
    }
    return SenvoThemeColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      border: Color.lerp(border, other.border, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      riskNormal: Color.lerp(riskNormal, other.riskNormal, t)!,
      riskWatch: Color.lerp(riskWatch, other.riskWatch, t)!,
      riskAlert: Color.lerp(riskAlert, other.riskAlert, t)!,
      riskEmergency: Color.lerp(riskEmergency, other.riskEmergency, t)!,
    );
  }
}

class SenvoColors {
  static const SenvoThemeColors dark = SenvoThemeColors(
    background: Color(0xFF0F1B24),
    surface: Color(0xFF16232D),
    surface2: Color(0xFF1D2C36),
    border: Color(0xFF26363F),
    text: Color(0xFFEDF3F2),
    muted: Color(0xFF8FA3A0),
    accent: Color(0xFF4FD1C5),
    riskNormal: Color(0xFF3B6E5E),
    riskWatch: Color(0xFFC98A3A),
    riskAlert: Color(0xFFC1441E),
    riskEmergency: Color(0xFF8B1A1A),
  );

  static const SenvoThemeColors light = SenvoThemeColors(
    background: Color(0xFFF7FAFC),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFEDF2F7),
    border: Color(0xFFE2E8F0),
    text: Color(0xFF1A202C),
    muted: Color(0xFF718096),
    accent: Color(0xFF319795),
    riskNormal: Color(0xFF38A169),
    riskWatch: Color(0xFFDD6B20),
    riskAlert: Color(0xFFE53E3E),
    riskEmergency: Color(0xFF9B2C2C),
  );
}

extension SenvoThemeContext on BuildContext {
  SenvoThemeColors get themeColors => Theme.of(this).extension<SenvoThemeColors>() ?? SenvoColors.dark;

  Color colorForHealthRisk(HealthRiskLevel level) {
    switch (level) {
      case HealthRiskLevel.normal:
        return themeColors.riskNormal;
      case HealthRiskLevel.watch:
        return themeColors.riskWatch;
      case HealthRiskLevel.alert:
        return themeColors.riskAlert;
      case HealthRiskLevel.emergency:
        return themeColors.riskEmergency;
    }
  }

  Color colorForRisk(RiskLevel level) {
    switch (level) {
      case RiskLevel.unknown:
        return themeColors.muted;
      case RiskLevel.low:
        return themeColors.riskNormal;
      case RiskLevel.moderate:
        return themeColors.riskWatch;
      case RiskLevel.elevated:
        return themeColors.riskAlert;
      case RiskLevel.high:
      case RiskLevel.critical:
        return themeColors.riskEmergency;
    }
  }

  Color colorForDataFreshness(DataFreshness freshness) {
    switch (freshness) {
      case DataFreshness.fresh:
      case DataFreshness.recent:
        return themeColors.riskNormal;
      case DataFreshness.stale:
        return themeColors.riskWatch;
      case DataFreshness.expired:
      case DataFreshness.unavailable:
        return themeColors.muted;
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
      scaffoldBackgroundColor: SenvoColors.dark.background,
      primaryColor: SenvoColors.dark.accent,
      extensions: const [SenvoColors.dark],
      colorScheme: ColorScheme.dark(
        primary: SenvoColors.dark.accent,
        surface: SenvoColors.dark.surface,
        onSurface: SenvoColors.dark.text,
      ),
      cardTheme: CardThemeData(
        color: SenvoColors.dark.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SenvoRadius.lg),
          side: BorderSide(color: SenvoColors.dark.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: SenvoColors.dark.border,
        thickness: 1,
        space: SenvoSpacing.lg,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(fontFamily: 'Space Grotesk', color: SenvoColors.dark.text, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(fontFamily: 'Space Grotesk', color: SenvoColors.dark.text, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(fontFamily: 'Space Grotesk', color: SenvoColors.dark.text, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(fontFamily: 'Space Grotesk', color: SenvoColors.dark.text, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontFamily: 'Space Grotesk', color: SenvoColors.dark.text, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(fontFamily: 'Space Grotesk', color: SenvoColors.dark.text, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(fontFamily: 'Space Grotesk', color: SenvoColors.dark.text, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontFamily: 'Space Grotesk', color: SenvoColors.dark.text, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontFamily: 'Space Grotesk', color: SenvoColors.dark.text, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontFamily: 'Inter', color: SenvoColors.dark.text),
        bodyMedium: TextStyle(fontFamily: 'Inter', color: SenvoColors.dark.text),
        bodySmall: TextStyle(fontFamily: 'Inter', color: SenvoColors.dark.muted),
        labelLarge: TextStyle(fontFamily: 'Inter', color: SenvoColors.dark.muted, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(fontFamily: 'Inter', color: SenvoColors.dark.muted, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(fontFamily: 'Inter', color: SenvoColors.dark.muted, fontWeight: FontWeight.w500),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: SenvoColors.dark.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Space Grotesk',
          color: SenvoColors.dark.text,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: SenvoColors.dark.text),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: SenvoColors.dark.surface,
        selectedItemColor: SenvoColors.dark.accent,
        unselectedItemColor: SenvoColors.dark.muted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: SenvoColors.light.background,
      primaryColor: SenvoColors.light.accent,
      extensions: const [SenvoColors.light],
      colorScheme: ColorScheme.light(
        primary: SenvoColors.light.accent,
        surface: SenvoColors.light.surface,
        onSurface: SenvoColors.light.text,
      ),
      cardTheme: CardThemeData(
        color: SenvoColors.light.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SenvoRadius.lg),
          side: BorderSide(color: SenvoColors.light.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: SenvoColors.light.border,
        thickness: 1,
        space: SenvoSpacing.lg,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(fontFamily: 'Space Grotesk', color: SenvoColors.light.text, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(fontFamily: 'Space Grotesk', color: SenvoColors.light.text, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(fontFamily: 'Space Grotesk', color: SenvoColors.light.text, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(fontFamily: 'Space Grotesk', color: SenvoColors.light.text, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontFamily: 'Space Grotesk', color: SenvoColors.light.text, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(fontFamily: 'Space Grotesk', color: SenvoColors.light.text, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(fontFamily: 'Space Grotesk', color: SenvoColors.light.text, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontFamily: 'Space Grotesk', color: SenvoColors.light.text, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontFamily: 'Space Grotesk', color: SenvoColors.light.text, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontFamily: 'Inter', color: SenvoColors.light.text),
        bodyMedium: TextStyle(fontFamily: 'Inter', color: SenvoColors.light.text),
        bodySmall: TextStyle(fontFamily: 'Inter', color: SenvoColors.light.muted),
        labelLarge: TextStyle(fontFamily: 'Inter', color: SenvoColors.light.muted, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(fontFamily: 'Inter', color: SenvoColors.light.muted, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(fontFamily: 'Inter', color: SenvoColors.light.muted, fontWeight: FontWeight.w500),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: SenvoColors.light.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Space Grotesk',
          color: SenvoColors.light.text,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: SenvoColors.light.text),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: SenvoColors.light.surface,
        selectedItemColor: SenvoColors.light.accent,
        unselectedItemColor: SenvoColors.light.muted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
