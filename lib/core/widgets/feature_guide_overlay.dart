import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/theme_x.dart';
import 'app_widgets.dart';

class GuideStep {
  const GuideStep({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}

class FeatureGuideOverlay extends StatefulWidget {
  const FeatureGuideOverlay({
    super.key,
    required this.steps,
    required this.onCompleted,
    required this.onDismiss,
  });

  final List<GuideStep> steps;
  final VoidCallback onCompleted;
  final VoidCallback onDismiss;

  static void show(
    BuildContext context, {
    required List<GuideStep> steps,
    required VoidCallback onCompleted,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) => FeatureGuideOverlay(
        steps: steps,
        onCompleted: onCompleted,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  State<FeatureGuideOverlay> createState() => _FeatureGuideOverlayState();
}

class _FeatureGuideOverlayState extends State<FeatureGuideOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentStep < widget.steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      widget.onDismiss();
      widget.onCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentStep];
    final total = widget.steps.length;
    final isLast = _currentStep == total - 1;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Material(
          color: Colors.transparent,
          child: AppCard(
            color: context.scheme.surface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: context.colors.brand.withValues(
                                alpha: 0.1 + (_pulseController.value * 0.1)),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.colors.brand.withValues(
                                  alpha: 0.3 + (_pulseController.value * 0.4)),
                            ),
                          ),
                          child: Icon(step.icon,
                              color: context.colors.brand, size: 22),
                        );
                      },
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppPill(
                            label: 'Guide ${ _currentStep + 1} of $total',
                            color: context.colors.brand,
                            background: context.colors.brandSubtle,
                          ),
                          const SizedBox(height: 4),
                          Text(step.title, style: context.text.titleSmall),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () {
                        widget.onDismiss();
                        widget.onCompleted();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  step.description,
                  style: context.text.bodyMedium?.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Row(
                      children: [
                        for (var i = 0; i < total; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 4),
                            width: i == _currentStep ? 16 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == _currentStep
                                  ? context.colors.brand
                                  : context.colors.border,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        widget.onDismiss();
                        widget.onCompleted();
                      },
                      child: const Text('Skip all'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppGradientButton(
                      label: isLast ? 'Got it' : 'Next',
                      onPressed: _next,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
