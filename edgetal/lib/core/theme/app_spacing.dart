import 'package:flutter/widgets.dart';

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
  static const BorderRadius field = BorderRadius.all(Radius.circular(md));
  static const BorderRadius chip = BorderRadius.all(Radius.circular(pill));
}
