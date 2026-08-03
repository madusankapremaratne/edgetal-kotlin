import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_x.dart';
import '../../core/widgets/app_widgets.dart';

class AccountGateModal extends StatelessWidget {
  const AccountGateModal({super.key, required this.onContinue});

  final VoidCallback onContinue;

  static Future<void> show(BuildContext context, {required VoidCallback onContinue}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AccountGateModal(onContinue: onContinue),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        MediaQuery.of(context).padding.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppPalette.oceanTeal.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'SYNC & SHORTLISTS',
                  style: context.text.labelSmall?.copyWith(
                    color: AppPalette.oceanTeal,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Not now',
                  style: context.text.labelLarge?.copyWith(
                    color: AppPalette.oceanTeal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Save your shortlists across sessions',
            style: context.text.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'This only stores your account and app settings. Your candidate profiles, resume data, and AI search indices NEVER leave this device.',
            style: context.text.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Icon(Icons.shield_outlined, color: AppPalette.privacyEmerald, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '100% On-device privacy guarantee',
                  style: context.text.labelMedium?.copyWith(
                    color: AppPalette.privacyEmerald,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: AppGradientButton(
              onPressed: () {
                Navigator.pop(context);
                onContinue();
              },
              label: 'Continue to Create Free Account',
            ),
          ),
        ],
      ),
    );
  }
}
