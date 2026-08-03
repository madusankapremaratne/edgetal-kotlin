import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_x.dart';

/// Consistent page chrome: a clean header (title, subtitle, actions) over a
/// width-constrained body. Replaces per-screen AppBars for a calmer, more
/// editorial feel suited to long review sessions.
///
/// Content fades and rises in once when the page first mounts — a single
/// AnimationController that runs once in [initState], so it never restarts on
/// ordinary rebuilds (e.g. typing in a filter field).
class PageScaffold extends StatefulWidget {
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
  State<PageScaffold> createState() => _PageScaffoldState();
}

class _PageScaffoldState extends State<PageScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  )..forward();

  late final Animation<double> _fade =
      CurvedAnimation(parent: _controller, curve: Curves.easeOut);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A Material ancestor so screens work whether they're hosted inside the
    // shell's Scaffold (tabs) or pushed directly by the root navigator
    // (Import, candidate Details) — TextField/InkWell require one.
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
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
                    title: widget.title,
                    subtitle: widget.subtitle,
                    actions: widget.actions,
                    leading: widget.leading,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Expanded(
                    child: FadeTransition(
                      opacity: _fade,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.02),
                          end: Offset.zero,
                        ).animate(_fade),
                        child: widget.scrollableBody
                            ? SingleChildScrollView(
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.xxl),
                                child: widget.body,
                              )
                            : widget.body,
                      ),
                    ),
                  ),
                ],
              ),
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
    final scaffold = Scaffold.maybeOf(context);
    final hasDrawer = scaffold?.hasDrawer ?? false;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: AppSpacing.md),
        ] else if (hasDrawer) ...[
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Menu',
            onPressed: () => scaffold?.openDrawer(),
          ),
          const SizedBox(width: AppSpacing.sm),
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
