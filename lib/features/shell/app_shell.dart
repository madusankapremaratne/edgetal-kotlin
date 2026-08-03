import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_x.dart';
import 'drawer_panel.dart';

class NavItem {
  const NavItem(this.icon, this.selectedIcon, this.label);
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

const _items = [
  NavItem(Icons.groups_outlined, Icons.groups, 'Candidates'),
  NavItem(Icons.search_outlined, Icons.search, 'Search'),
  NavItem(Icons.work_outline, Icons.work, 'Jobs'),
  NavItem(Icons.memory_outlined, Icons.memory, 'Models'),
];

/// Adaptive scaffold: a bottom [NavigationBar] on phones, a side
/// [NavigationRail] with brand mark on tablets / desktop / web.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _go(int index) {
    if (index != navigationShell.currentIndex) HapticFeedback.selectionClick();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 760;

    if (wide) {
      return Scaffold(
        drawer: const DrawerPanel(),
        body: Row(
          children: [
            _Rail(
              currentIndex: navigationShell.currentIndex,
              onSelected: _go,
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      drawer: const DrawerPanel(),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _go,
        destinations: [
          for (final item in _items)
            NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: item.label,
            ),
        ],
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.currentIndex, required this.onSelected});
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: context.scheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
              child: _BrandMark(),
            ),
            for (var i = 0; i < _items.length; i++)
              _RailTile(
                item: _items[i],
                selected: i == currentIndex,
                onTap: () => onSelected(i),
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Icon(Icons.lock_outline,
                      size: 14, color: context.colors.privacy),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'On-device · GDPR by design',
                      style: context.text.labelSmall
                          ?.copyWith(color: context.colors.privacy),
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

class _RailTile extends StatelessWidget {
  const _RailTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  static const _duration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.card,
        child: InkWell(
          borderRadius: AppRadius.card,
          onTap: onTap,
          child: AnimatedContainer(
            duration: _duration,
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: selected ? context.colors.brandSubtle : Colors.transparent,
              borderRadius: AppRadius.card,
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.md),
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: _duration,
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    selected ? item.selectedIcon : item.icon,
                    key: ValueKey(selected),
                    size: 22,
                    color: selected ? context.colors.brand : context.colors.textMuted,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: _duration,
                    style: context.text.labelLarge!.copyWith(
                      color: selected
                          ? context.colors.brand
                          : context.colors.textSecondary,
                    ),
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: context.colors.brand.withAlpha(40),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/logos/Icon Only.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'EdgeTal',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: context.colors.brandSubtle,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: context.colors.brand.withAlpha(60),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      'BETA',
                      style: context.text.labelSmall?.copyWith(
                        color: context.colors.brand,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'On-Device Intelligence',
                style: context.text.labelSmall?.copyWith(
                  color: context.colors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
