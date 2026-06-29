import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Convenience accessors so widgets read `context.colors.brand`,
/// `context.text.titleMedium`, etc. without boilerplate.
extension ThemeX on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
  ColorScheme get scheme => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
