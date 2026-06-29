import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_x.dart';

class NavItem {
  const NavItem(this.icon, this.selectedIcon, this.label);
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

const _items = [
  NavItem(Icons.groups_outlined, Icons.groups, 'Candidates'),
  NavItem(Icons.search_outlined, Icons.search, 'Search'),
  NavItem(Icons.insights_outlined, Icons.insights, 'Insights'),
  NavItem(Icons.memory_outlined, Icons.memory, 'Models'),
];

/// Adaptive scaffold: a bottom [NavigationBar] on phones, a side
/// [NavigationRail] with brand mark on tablets / desktop / web.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _go(int index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 760;

    if (wide) {
      return Scaffold(
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 3),
      child: Material(
        color: selected ? context.colors.brandSubtle : Colors.transparent,
        borderRadius: AppRadius.card,
        child: InkWell(
          borderRadius: AppRadius.card,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  selected ? item.selectedIcon : item.icon,
                  size: 22,
                  color: selected ? context.colors.brand : context.colors.textMuted,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelLarge?.copyWith(
                      color: selected
                          ? context.colors.brand
                          : context.colors.textSecondary,
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
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppPalette.indigo500, AppPalette.indigo700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.eco_outlined, color: Colors.white, size: 20),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            'EdgeTal',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.titleLarge,
          ),
        ),
      ],
    );
  }
}
