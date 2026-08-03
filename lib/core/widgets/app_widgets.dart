import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_x.dart';

/// A soft-shadowed surface — the primary container in the modernized design.
///
/// When [onTap] is set, the card gives a subtle press-scale and a light
/// haptic tick so tapping feels tactile, not just visual (ripple alone).
/// Set [elevated] to false for dense list rows where a flat, bordered-only
/// look still reads better than a shadow.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardInsets,
    this.onTap,
    this.color,
    this.borderColor,
    this.elevated = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final bool elevated;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tint = context.isDark ? context.colors.brand : AppPalette.midnightNavy;
    final shadow = widget.elevated
        ? (context.isDark ? AppShadow.cardDark(tint) : AppShadow.card(tint))
        : null;

    final card = Container(
      decoration: BoxDecoration(
        color: widget.color ?? context.scheme.surface,
        borderRadius: AppRadius.cardXl,
        border: Border.all(
          color: widget.borderColor ??
              context.colors.border.withValues(alpha: widget.elevated ? 0.6 : 1),
        ),
        boxShadow: shadow,
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
          borderRadius: AppRadius.cardXl,
          child: card,
        ),
      ),
    );
  }
}

/// Primary-emphasis CTA button with a brand gradient fill and soft glow
/// shadow. Use sparingly — one per screen for the main action (e.g. "Add
/// Candidate", "Import", onboarding "Continue").
class AppGradientButton extends StatelessWidget {
  const AppGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.field,
          gradient: AppPalette.brandGradient(),
          boxShadow: disabled
              ? null
              : AppShadow.soft(context.colors.brand).map((s) {
                  return BoxShadow(
                    color: context.colors.brand.withValues(alpha: 0.35),
                    blurRadius: s.blurRadius,
                    offset: s.offset,
                  );
                }).toList(),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppRadius.field,
            onTap: disabled
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onPressed!();
                  },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: Colors.white),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    label,
                    style: context.text.labelLarge?.copyWith(color: Colors.white),
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
                  borderRadius: AppRadius.cardXl,
                  boxShadow: AppShadow.soft(context.colors.brand),
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
    this.filled = false,
  });

  final String label;
  final Color? color;
  final Color? background;
  final IconData? icon;

  /// High-emphasis variant: solid/gradient fill with white text, used for
  /// standout badges like top fit-scores instead of a subtle tint chip.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : (color ?? context.colors.textSecondary);
    final baseColor = color ?? context.colors.brand;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: icon == null ? 10 : 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: filled ? null : (background ?? context.colors.surfaceSubtle),
        gradient: filled
            ? LinearGradient(
                colors: [baseColor, Color.lerp(baseColor, Colors.white, 0.2)!],
              )
            : null,
        borderRadius: AppRadius.chip,
        border: filled ? null : Border.all(color: context.colors.border),
        boxShadow: filled ? AppShadow.soft(baseColor) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall?.copyWith(color: fg),
            ),
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.16),
            color.withValues(alpha: 0.06),
          ],
        ),
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
