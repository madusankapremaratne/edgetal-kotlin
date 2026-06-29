import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_x.dart';

/// Consistent page chrome: a clean header (title, subtitle, actions) over a
/// width-constrained body. Replaces per-screen AppBars for a calmer, more
/// editorial feel suited to long review sessions.
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions = const [],
    this.leading,
    this.scrollableBody = false,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget> actions;
  final Widget? leading;

  /// When true the body is wrapped in its own scroll view with page padding.
  final bool scrollableBody;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: AppSpacing.contentMaxWidth),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(
                  title: title,
                  subtitle: subtitle,
                  actions: actions,
                  leading: leading,
                ),
                const SizedBox(height: AppSpacing.xl),
                Expanded(
                  child: scrollableBody
                      ? SingleChildScrollView(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.xxl),
                          child: body,
                        )
                      : body,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.actions,
    required this.leading,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.text.headlineSmall),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: context.text.bodyMedium),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        ...actions,
      ],
    );
  }
}
