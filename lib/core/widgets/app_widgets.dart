import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_spacing.dart';
import '../theme/theme_x.dart';

/// A bordered, flat surface — the primary container in the minimal design.
///
/// When [onTap] is set, the card gives a subtle press-scale and a light
/// haptic tick so tapping feels tactile, not just visual (ripple alone).
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardInsets,
    this.onTap,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: widget.color ?? context.scheme.surface,
        borderRadius: AppRadius.cardLg,
        border: Border.all(color: widget.borderColor ?? context.colors.border),
      ),
      padding: widget.padding,
      child: widget.child,
    );
    if (widget.onTap == null) return card;

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onTap!();
          },
          onHighlightChanged: (v) => setState(() => _pressed = v),
          borderRadius: AppRadius.cardLg,
          child: card,
        ),
      ),
    );
  }
}

/// Section label + optional trailing action, used across screens.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.text.titleMedium),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: context.text.bodySmall),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Centered empty / zero-state with an icon, message and optional action.
///
/// The icon "breathes" gently so an empty screen still feels alive rather
/// than inert.
class EmptyState extends StatefulWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.04).animate(
                CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
              ),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: context.colors.surfaceSubtle,
                  borderRadius: AppRadius.cardLg,
                ),
                child: Icon(widget.icon, size: 30, color: context.colors.textMuted),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(widget.title, style: context.text.titleMedium, textAlign: TextAlign.center),
            if (widget.message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.message!,
                style: context.text.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (widget.action != null) ...[
              const SizedBox(height: AppSpacing.xl),
              widget.action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Small status pill (skill chips, segment labels, badges).
class AppPill extends StatelessWidget {
  const AppPill({
    super.key,
    required this.label,
    this.color,
    this.background,
    this.icon,
  });

  final String label;
  final Color? color;
  final Color? background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? context.colors.textSecondary;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: icon == null ? 10 : 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background ?? context.colors.surfaceSubtle,
        borderRadius: AppRadius.chip,
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: context.text.labelSmall?.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}

/// Reusable monogram avatar coloured deterministically from a seed string.
class Monogram extends StatelessWidget {
  const Monogram({super.key, required this.text, this.size = 44, this.seed});

  final String text;
  final double size;
  final String? seed;

  @override
  Widget build(BuildContext context) {
    final palette = [
      context.colors.brand,
      context.colors.privacy,
      context.colors.info,
      context.colors.warning,
    ];
    final key = (seed ?? text);
    final color = palette[key.isEmpty ? 0 : key.codeUnitAt(0) % palette.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size / 3.2),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: context.text.titleMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}

/// Fades and slides a child in once, with a delay proportional to [index].
/// Drop this around list items to turn an abrupt appearance into a gentle
/// cascade — purely cosmetic, no effect on layout or state.
class StaggeredEntrance extends StatelessWidget {
  const StaggeredEntrance({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final delayMs = index.clamp(0, 10) * 45;
    const riseMs = 300;
    final totalMs = delayMs + riseMs;
    final delayFraction = delayMs / totalMs;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: totalMs),
      curve: Interval(delayFraction, 1.0, curve: Curves.easeOutCubic),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 14),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Three softly bouncing dots — used in place of a bare spinner for "the
/// on-device model is thinking" moments (search, analysis), so waiting reads
/// as active work rather than a stall.
class LoadingDots extends StatefulWidget {
  const LoadingDots({super.key, this.color});

  final Color? color;

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? context.colors.brand;
    return SizedBox(
      height: 18,
      width: 52,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (i) {
              final t = (_controller.value - i * 0.2) % 1.0;
              final bounce = t < 0.5 ? (t / 0.5) : (1 - (t - 0.5) / 0.5);
              return Transform.translate(
                offset: Offset(0, -6 * bounce.clamp(0.0, 1.0)),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

/// Shared fade + gentle scale transition for [AnimatedSwitcher], so state
/// changes across screens (loading → content, idle → results) share one
/// consistent motion instead of a hard cut.
Widget fadeThroughTransition(Widget child, Animation<double> animation) {
  return FadeTransition(
    opacity: animation,
    child: ScaleTransition(
      scale: Tween<double>(begin: 0.98, end: 1).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOut),
      ),
      child: child,
    ),
  );
}
