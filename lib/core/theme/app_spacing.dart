import 'package:flutter/widgets.dart';

import 'app_palette.dart';

/// 4-pt spacing scale and shared radii. Keeping these centralized is what makes
/// the layout feel consistent and "minimal" rather than ad-hoc.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Max content width on large screens so reading lines stay comfortable.
  static const double contentMaxWidth = 880;

  static const EdgeInsets pageInsets = EdgeInsets.all(lg);
  static const EdgeInsets cardInsets = EdgeInsets.all(lg);
}

class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 999;

  static const BorderRadius card = BorderRadius.all(Radius.circular(md));
  static const BorderRadius cardLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius cardXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius field = BorderRadius.all(Radius.circular(md));
  static const BorderRadius chip = BorderRadius.all(Radius.circular(pill));
}

/// Soft, brand-tinted shadow tokens — replaces the old hairline-only look
/// with real depth. Colored from the brand navy/teal instead of plain black
/// so shadows read as "soft light" rather than a harsh drop-shadow.
class AppShadow {
  AppShadow._();

  static List<BoxShadow> soft(Color tint) => [
        BoxShadow(
          color: tint.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> card(Color tint) => [
        BoxShadow(
          color: tint.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: tint.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> floating(Color tint) => [
        BoxShadow(
          color: tint.withValues(alpha: 0.18),
          blurRadius: 28,
          offset: const Offset(0, 12),
        ),
      ];

  /// Dark-mode variants lean lower-opacity + a faint brand glow rather than
  /// black, since black shadows disappear against already-dark surfaces.
  static List<BoxShadow> softDark(Color glow) => [
        BoxShadow(
          color: AppPalette.slate950.withValues(alpha: 0.4),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: glow.withValues(alpha: 0.05),
          blurRadius: 16,
        ),
      ];

  static List<BoxShadow> cardDark(Color glow) => [
        BoxShadow(
          color: AppPalette.slate950.withValues(alpha: 0.5),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: glow.withValues(alpha: 0.06),
          blurRadius: 20,
        ),
      ];
}
