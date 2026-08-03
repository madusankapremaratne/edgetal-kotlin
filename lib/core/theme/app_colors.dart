import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Semantic colors that aren't expressed well by [ColorScheme] alone.
///
/// Exposed as a [ThemeExtension] so widgets can read theme-aware tokens via
/// `Theme.of(context).extension<AppColors>()` (see the `context.colors`
/// helper in `theme_x.dart`).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.brand,
    required this.brandSubtle,
    required this.onBrandSubtle,
    required this.privacy,
    required this.privacySubtle,
    required this.onPrivacySubtle,
    required this.warning,
    required this.warningSubtle,
    required this.info,
    required this.infoSubtle,
    required this.surfaceSubtle,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.highlightSemantic,
    required this.highlightExact,
  });

  final Color brand;
  final Color brandSubtle;
  final Color onBrandSubtle;
  final Color privacy;
  final Color privacySubtle;
  final Color onPrivacySubtle;
  final Color warning;
  final Color warningSubtle;
  final Color info;
  final Color infoSubtle;
  final Color surfaceSubtle;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  /// Background tint for semantic (vector) match highlighting.
  final Color highlightSemantic;

  /// Background tint for exact keyword match highlighting.
  final Color highlightExact;

  static const AppColors light = AppColors(
    brand: AppPalette.oceanTeal,
    brandSubtle: Color(0xFFEAF5F8),
    onBrandSubtle: Color(0xFF2C6B7B),
    privacy: AppPalette.privacyEmerald,
    privacySubtle: Color(0xFFEAF8F0),
    onPrivacySubtle: Color(0xFF1E6B3D),
    warning: AppPalette.warmGold,
    warningSubtle: Color(0xFFFDF8E8),
    info: AppPalette.vibrantAmber,
    infoSubtle: Color(0xFFFAF0E8),
    surfaceSubtle: AppPalette.slate100,
    border: AppPalette.softIceBlue,
    borderStrong: AppPalette.oceanTeal,
    textPrimary: AppPalette.midnightNavy,
    textSecondary: AppPalette.slate600,
    textMuted: AppPalette.slate400,
    highlightSemantic: Color(0x33A9D0E5),
    highlightExact: Color(0x66EFBB47),
  );

  static const AppColors dark = AppColors(
    brand: AppPalette.oceanTeal,
    brandSubtle: Color(0x2B4B9CB3),
    onBrandSubtle: AppPalette.softIceBlue,
    privacy: AppPalette.privacyEmerald,
    privacySubtle: Color(0x2B2E9E5B),
    onPrivacySubtle: Color(0xFF76D89B),
    warning: AppPalette.warmGold,
    warningSubtle: Color(0x2BEFBB47),
    info: AppPalette.vibrantAmber,
    infoSubtle: Color(0x2BE8842E),
    surfaceSubtle: AppPalette.darkSurfaceElevated,
    border: AppPalette.darkBorder,
    borderStrong: Color(0xFF334155),
    textPrimary: Color(0xFFE8ECF4),
    textSecondary: Color(0xFF9AA6BD),
    textMuted: AppPalette.slate500,
    highlightSemantic: Color(0x334B9CB3),
    highlightExact: Color(0x66EFBB47),
  );

  @override
  AppColors copyWith({
    Color? brand,
    Color? brandSubtle,
    Color? onBrandSubtle,
    Color? privacy,
    Color? privacySubtle,
    Color? onPrivacySubtle,
    Color? warning,
    Color? warningSubtle,
    Color? info,
    Color? infoSubtle,
    Color? surfaceSubtle,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? highlightSemantic,
    Color? highlightExact,
  }) {
    return AppColors(
      brand: brand ?? this.brand,
      brandSubtle: brandSubtle ?? this.brandSubtle,
      onBrandSubtle: onBrandSubtle ?? this.onBrandSubtle,
      privacy: privacy ?? this.privacy,
      privacySubtle: privacySubtle ?? this.privacySubtle,
      onPrivacySubtle: onPrivacySubtle ?? this.onPrivacySubtle,
      warning: warning ?? this.warning,
      warningSubtle: warningSubtle ?? this.warningSubtle,
      info: info ?? this.info,
      infoSubtle: infoSubtle ?? this.infoSubtle,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      highlightSemantic: highlightSemantic ?? this.highlightSemantic,
      highlightExact: highlightExact ?? this.highlightExact,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      brand: Color.lerp(brand, other.brand, t)!,
      brandSubtle: Color.lerp(brandSubtle, other.brandSubtle, t)!,
      onBrandSubtle: Color.lerp(onBrandSubtle, other.onBrandSubtle, t)!,
      privacy: Color.lerp(privacy, other.privacy, t)!,
      privacySubtle: Color.lerp(privacySubtle, other.privacySubtle, t)!,
      onPrivacySubtle: Color.lerp(onPrivacySubtle, other.onPrivacySubtle, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSubtle: Color.lerp(warningSubtle, other.warningSubtle, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoSubtle: Color.lerp(infoSubtle, other.infoSubtle, t)!,
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      highlightSemantic: Color.lerp(highlightSemantic, other.highlightSemantic, t)!,
      highlightExact: Color.lerp(highlightExact, other.highlightExact, t)!,
    );
  }
}
