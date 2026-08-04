import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_x.dart';
import '../../core/widgets/app_widgets.dart';
import '../candidates/candidates_controller.dart';
import '../jobs/jobs_controller.dart';

class DrawerPanel extends ConsumerWidget {
  const DrawerPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final candidatesState = ref.watch(candidatesControllerProvider);
    final jobsState = ref.watch(jobsControllerProvider);

    final candidateCount = candidatesState.resumes.length;
    final jobCount = jobsState.jobs.length;

    return Drawer(
      backgroundColor: context.scheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Local Privacy Workspace Header (Zero-Cloud Verified)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.colors.brandSubtle,
                  borderRadius: AppRadius.cardXl,
                  border: Border.all(
                    color: context.colors.brand.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: AppShadow.soft(context.colors.brand),
                          ),
                          child: Image.asset(
                            'assets/logos/icon-navy.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Private Workspace',
                                style: context.text.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              AppPill(
                                label: '🔒 100% On-Device Vault',
                                color: context.colors.privacy,
                                background: context.colors.privacySubtle,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        _StatChip(
                          icon: Icons.people_outline,
                          label: '$candidateCount Candidates',
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _StatChip(
                          icon: Icons.work_outline,
                          label: '$jobCount Jobs',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Divider(color: context.colors.border, height: 1),
            const SizedBox(height: AppSpacing.sm),
            // Menu Items
            _DrawerTile(
              icon: Icons.home_outlined,
              label: 'Home & Talent Pool',
              onTap: () {
                Navigator.pop(context);
                context.go('/candidates');
              },
            ),
            _DrawerTile(
              icon: Icons.work_outline,
              label: 'Jobs & Pipelines',
              onTap: () {
                Navigator.pop(context);
                context.go('/jobs');
              },
            ),
            _DrawerTile(
              icon: Icons.help_outline,
              label: 'Help / How It Works',
              onTap: () {
                Navigator.pop(context);
                context.push('/help');
              },
            ),
            _DrawerTile(
              icon: Icons.backup_outlined,
              label: 'Backup & Encrypted Export',
              onTap: () {
                Navigator.pop(context);
                context.push('/backup');
              },
            ),
            _DrawerTile(
              icon: Icons.settings_outlined,
              label: 'Settings & On-Device Models',
              onTap: () {
                Navigator.pop(context);
                context.go('/models');
              },
            ),
            const Spacer(),
            Divider(color: context.colors.border, height: 1),
            // Muted Privacy Guarantee Indicator
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined,
                      color: context.colors.privacy, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'GDPR Verified · Zero Cloud Sync',
                      style: context.text.labelSmall?.copyWith(
                        color: context.colors.privacy,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: context.scheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.colors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: context.colors.brand),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: context.text.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badgeCount,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.field,
        child: InkWell(
          borderRadius: AppRadius.field,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.colors.brandSubtle,
                    borderRadius: AppRadius.field,
                  ),
                  child: Icon(icon, color: context.colors.brand, size: 19),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: context.text.labelLarge?.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (badgeCount != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: AppPalette.insightGradient,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: AppShadow.soft(AppPalette.vibrantAmber),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
