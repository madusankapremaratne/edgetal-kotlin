import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_x.dart';

class DrawerPanel extends StatelessWidget {
  const DrawerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: context.scheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header Profile Section (Page 9 spec)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppPalette.warmGold,
                          Color.lerp(AppPalette.warmGold, Colors.white, 0.25)!,
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: AppShadow.soft(AppPalette.warmGold),
                    ),
                    child: Text(
                      'AK',
                      style: context.text.titleMedium?.copyWith(
                        color: AppPalette.midnightNavy,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alex Kim',
                          style: context.text.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.colors.textPrimary,
                          ),
                        ),
                        Text(
                          'alex@edgetal.com',
                          style: context.text.bodySmall?.copyWith(
                            color: context.colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: context.colors.border, height: 1),
            const SizedBox(height: AppSpacing.md),
            // Menu Items
            _DrawerTile(
              icon: Icons.home_outlined,
              label: 'Home',
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
              label: 'Backup & Export',
              onTap: () {
                Navigator.pop(context);
                context.push('/backup');
              },
            ),
            _DrawerTile(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              badgeCount: 3,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _DrawerTile(
              icon: Icons.settings_outlined,
              label: 'Settings & Models',
              onTap: () {
                Navigator.pop(context);
                context.go('/models');
              },
            ),
            const Spacer(),
            Divider(color: context.colors.border, height: 1),
            // Muted Sign Out (Page 9 spec)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: ListTile(
                leading: Icon(Icons.logout, color: context.colors.textMuted, size: 20),
                title: Text(
                  'Sign out',
                  style: context.text.bodyMedium?.copyWith(
                    color: context.colors.textMuted,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
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
