import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Palette ──────────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  static const bg = Color(0xFF000000); // Pure Black
  static const surface = Color(0xFF0C0C0C); // Very dark gray
  static const surfaceElevated = Color(0xFF141414); // Slightly lighter gray
  static const surfaceBorder = Color(0xFF262626); // Dark border

  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFA0A0A0); // Neutral light gray
  static const textMuted = Color(0xFF6B6B6B); // Neutral dark gray

  // Risk bands
  static const riskLow = Color(0xFF00E5A0);
  static const riskLowEnd = Color(0xFF00BCD4);
  static const riskMed = Color(0xFFFFC107);
  static const riskMedEnd = Color(0xFFFF5F7E);
  static const riskHigh = Color(0xFFFF4040);
  static const riskHighEnd = Color(0xFFFF8C00);

  // Readiness
  static const readinessGreen = Color(0xFF00E5A0);
  static const readinessCyan = Color(0xFF00D4FF);
  static const readinessAmber = Color(0xFFFFC107);
  static const readinessPink = Color(0xFFFF5F7E);

  // Accent (Shifted from Blue to stark White for monochromatic brutalism)
  static const accent = Color(0xFFFFFFFF); // Pure White
  static const accentEnd = Color(0xFFD4D4D4); // Light Gray

  // Chart (White and semantic red)
  static const chartLine1 = Color(0xFFFFFFFF);
  static const chartLine2 = Color(0xFFFF5F7E);
  static const chartGrid = Color(0xFF262626); // Dark border

  // Status (Removed blue, using stark monochrome & semantic)
  static const live = Color(0xFF00E5A0);
  static const pending = Color(0xFFFFC107);
  static const finished = Color(0xFF8FA3BF);
  static const notStarted = Color(0xFFFFFFFF); // White instead of blue

  // Gradients
  static const gradientAccent = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFA0A0A0)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const gradientLow = LinearGradient(
    colors: [riskLow, riskLowEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const gradientMed = LinearGradient(
    colors: [riskMed, riskMedEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const gradientHigh = LinearGradient(
    colors: [riskHigh, riskHighEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const gradientBg = LinearGradient(
    colors: [Color(0xFF000000), Color(0xFF050505)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient gradientForRisk(String band) {
    switch (band.toUpperCase()) {
      case 'LOW':
        return gradientLow;
      case 'MED':
      case 'MEDIUM':
        return gradientMed;
      case 'HIGH':
        return gradientHigh;
      default:
        return gradientLow;
    }
  }

  static Color colorForRisk(String band) {
    switch (band.toUpperCase()) {
      case 'LOW':
        return riskLow;
      case 'MED':
      case 'MEDIUM':
        return riskMed;
      case 'HIGH':
        return riskHigh;
      default:
        return riskLow;
    }
  }
}

// ── Typography ────────────────────────────────────────────────────────────────
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _sora(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.textPrimary,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.sora(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  static TextStyle _mono(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.textPrimary,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        color: color,
      );

  // Display
  static TextStyle displayLarge =
      _sora(32, weight: FontWeight.w700, letterSpacing: -0.5);
  static TextStyle displayMedium =
      _sora(24, weight: FontWeight.w700, letterSpacing: -0.3);
  static TextStyle displaySmall =
      _sora(20, weight: FontWeight.w600, letterSpacing: -0.2);

  // Headline
  static TextStyle headlineLarge = _sora(18, weight: FontWeight.w600);
  static TextStyle headlineMedium = _sora(16, weight: FontWeight.w600);
  static TextStyle headlineSmall = _sora(14, weight: FontWeight.w600);

  // Body
  static TextStyle bodyLarge = _sora(15,
      weight: FontWeight.w400, color: AppColors.textPrimary, height: 1.5);
  static TextStyle bodyMedium = _sora(13,
      weight: FontWeight.w400, color: AppColors.textSecondary, height: 1.5);
  static TextStyle bodySmall = _sora(11,
      weight: FontWeight.w400, color: AppColors.textMuted, height: 1.4);

  // Label
  static TextStyle labelLarge =
      _sora(13, weight: FontWeight.w600, letterSpacing: 0.3);
  static TextStyle labelMedium =
      _sora(11, weight: FontWeight.w600, letterSpacing: 0.5);
  static TextStyle labelSmall =
      _sora(10, weight: FontWeight.w700, letterSpacing: 0.8);

  // Mono / Numeric
  static TextStyle monoLarge = _mono(28, weight: FontWeight.w700);
  static TextStyle monoMedium = _mono(18, weight: FontWeight.w600);
  static TextStyle monoSmall =
      _mono(12, weight: FontWeight.w500, color: AppColors.textSecondary);

  // Caption
  static TextStyle caption = _sora(10,
      weight: FontWeight.w500, color: AppColors.textMuted, letterSpacing: 0.5);
}

// ── Theme ─────────────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.accentEnd,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.riskHigh,
      ),
      textTheme: GoogleFonts.soraTextTheme(
        ThemeData.dark().textTheme.apply(
              bodyColor: AppColors.textPrimary,
              displayColor: AppColors.textPrimary,
            ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: AppTextStyles.headlineLarge,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.textPrimary, // Stark white instead of blue
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.surfaceBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.surfaceBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
              color: AppColors.textPrimary,
              width: 1.5), // White border on focus
        ),
        hintStyle: AppTextStyles.bodyMedium,
        labelStyle: AppTextStyles.labelMedium,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.surfaceBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.textPrimary, // Stark white button
          foregroundColor: AppColors.bg, // Black text
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: AppTextStyles.labelLarge.copyWith(color: AppColors.bg),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.surfaceBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
