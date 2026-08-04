import 'package:flutter/material.dart';

/// DunkMax palette — sampled from the reference app: near-black gym court
/// background, a warm orange primary/CTA, and a couple of accent hues used
/// sparingly for onboarding icons.
abstract class DunkColors {
  static const Color background = Color(0xFF0A0A0B);
  static const Color surface = Color(0xFF161618);
  static const Color surfaceRaised = Color(0xFF1F1F22);
  static const Color stroke = Color(0xFF2A2A2E);

  static const Color primary = Color(0xFFF26A21);
  static const Color primaryBright = Color(0xFFF5842A);
  static const Color primaryDeep = Color(0xFFE8631E);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9A9AA0);
  static const Color textTertiary = Color(0xFF6E6E76);

  // Accent hues for onboarding category icons.
  static const Color accentGreen = Color(0xFF2E9E6B);
  static const Color accentPurple = Color(0xFF6C63FF);

  /// The CTA button gradient (bright → deep orange, top-left to bottom-right).
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBright, primaryDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

abstract class DunkTheme {
  static ThemeData build() {
    const colorScheme = ColorScheme.dark(
      surface: DunkColors.background,
      primary: DunkColors.primary,
      onPrimary: Colors.white,
      secondary: DunkColors.primaryBright,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: DunkColors.background,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: DunkColors.textPrimary,
        displayColor: DunkColors.textPrimary,
      ),
      splashFactory: InkRipple.splashFactory,
    );
  }

  /// Big all-caps headline used on onboarding screens.
  static const TextStyle onboardingTitle = TextStyle(
    fontSize: 34,
    height: 1.08,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
    color: DunkColors.textPrimary,
  );

  static const TextStyle onboardingSubtitle = TextStyle(
    fontSize: 17,
    height: 1.3,
    fontWeight: FontWeight.w400,
    color: DunkColors.textSecondary,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: DunkColors.textPrimary,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: DunkColors.textSecondary,
  );
}
