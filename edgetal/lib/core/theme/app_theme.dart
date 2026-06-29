import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_palette.dart';
import 'app_spacing.dart';

/// Builds the light and dark [ThemeData] for EdgeTal.
///
/// Design intent: generous whitespace, hairline borders instead of heavy
/// shadows, a single confident brand accent, and Inter for a clean,
/// internationally-legible feel (important for a pan-European audience).
class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light, AppColors.light);
  static ThemeData dark() => _build(Brightness.dark, AppColors.dark);

  static ThemeData _build(Brightness brightness, AppColors colors) {
    final isLight = brightness == Brightness.light;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: colors.brand,
      onPrimary: AppPalette.white,
      primaryContainer: colors.brandSubtle,
      onPrimaryContainer: colors.onBrandSubtle,
      secondary: colors.privacy,
      onSecondary: AppPalette.white,
      secondaryContainer: colors.privacySubtle,
      onSecondaryContainer: colors.onPrivacySubtle,
      tertiary: colors.info,
      onTertiary: AppPalette.white,
      tertiaryContainer: colors.infoSubtle,
      onTertiaryContainer: colors.info,
      error: isLight ? AppPalette.red600 : AppPalette.red500,
      onError: AppPalette.white,
      errorContainer: isLight ? AppPalette.red50 : const Color(0x1FEF4444),
      onErrorContainer: isLight ? AppPalette.red600 : const Color(0xFFFCA5A5),
      surface: isLight ? AppPalette.white : AppPalette.darkSurface,
      onSurface: colors.textPrimary,
      surfaceContainerLowest: isLight ? AppPalette.white : AppPalette.darkBg,
      surfaceContainerLow: isLight ? AppPalette.slate50 : AppPalette.darkSurface,
      surfaceContainer: isLight ? AppPalette.slate50 : AppPalette.darkSurfaceElevated,
      surfaceContainerHigh: colors.surfaceSubtle,
      surfaceContainerHighest: colors.surfaceSubtle,
      onSurfaceVariant: colors.textSecondary,
      outline: colors.border,
      outlineVariant: colors.border,
      shadow: Colors.black,
      scrim: Colors.black54,
      inverseSurface: isLight ? AppPalette.slate900 : AppPalette.slate100,
      onInverseSurface: isLight ? AppPalette.slate50 : AppPalette.slate900,
      inversePrimary: colors.brand,
    );

    final baseTextTheme = GoogleFonts.interTextTheme(
      isLight ? ThemeData.light().textTheme : ThemeData.dark().textTheme,
    );

    final textTheme = baseTextTheme.copyWith(
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: colors.textPrimary,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: colors.textPrimary,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: colors.textPrimary,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: colors.textPrimary,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        color: colors.textPrimary,
        height: 1.5,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        color: colors.textSecondary,
        height: 1.5,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        color: colors.textSecondary,
        height: 1.45,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: colors.textSecondary,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: colors.textMuted,
        letterSpacing: 0.3,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isLight ? AppPalette.slate50 : AppPalette.darkBg,
      textTheme: textTheme,
      extensions: [colors],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: isLight ? AppPalette.slate50 : AppPalette.darkBg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle:
            isLight ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardLg,
          side: BorderSide(color: colors.border),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceSubtle,
        side: BorderSide(color: colors.border),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.chip),
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.brand,
          foregroundColor: AppPalette.white,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          textStyle: textTheme.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.field),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textPrimary,
          minimumSize: const Size(0, 48),
          side: BorderSide(color: colors.borderStrong),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          textStyle: textTheme.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.field),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.brand,
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
        border: OutlineInputBorder(
          borderRadius: AppRadius.field,
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.field,
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.field,
          borderSide: BorderSide(color: colors.brand, width: 1.6),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colors.brandSubtle,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? colors.brand : colors.textMuted,
            size: 24,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: colors.brandSubtle,
        selectedIconTheme: IconThemeData(color: colors.brand),
        unselectedIconTheme: IconThemeData(color: colors.textMuted),
        selectedLabelTextStyle:
            textTheme.labelMedium?.copyWith(color: colors.brand),
        unselectedLabelTextStyle: textTheme.labelMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.brand,
        linearTrackColor: colors.surfaceSubtle,
        circularTrackColor: colors.surfaceSubtle,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardLg),
      ),
    );
  }
}
