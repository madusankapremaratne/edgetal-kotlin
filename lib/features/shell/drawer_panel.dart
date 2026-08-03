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
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppPalette.warmGold,
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
                            color: AppPalette.midnightNavy,
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
            const Divider(color: AppPalette.softIceBlue, height: 1),
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
            const Divider(color: AppPalette.softIceBlue, height: 1),
            // Muted Sign Out (Page 9 spec)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: ListTile(
                leading: const Icon(Icons.logout, color: AppPalette.slate400, size: 20),
                title: Text(
                  'Sign out',
                  style: context.text.bodyMedium?.copyWith(
                    color: AppPalette.slate400,
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
    return ListTile(
      leading: Icon(icon, color: AppPalette.midnightNavy, size: 22),
      title: Text(
        label,
        style: context.text.labelLarge?.copyWith(
          color: AppPalette.midnightNavy,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: badgeCount != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppPalette.vibrantAmber,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}
