import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../providers/navigation_provider.dart';

class FloatingBottomNav extends StatelessWidget {
  const FloatingBottomNav({super.key});

  static const double reservedHeight = 96;

  static const _items = [
    _BottomNavItem(
      tooltip: 'Dashboard',
      icon: Icons.space_dashboard_rounded,
      targetIndex: 1,
    ),
    _BottomNavItem(
      tooltip: 'Sales',
      icon: Icons.point_of_sale_rounded,
      targetIndex: 0,
    ),
    _BottomNavItem(
      tooltip: 'Products',
      icon: Icons.inventory_2_rounded,
      targetIndex: 2,
    ),
    _BottomNavItem(
      tooltip: 'History',
      icon: Icons.history_rounded,
      targetIndex: 3,
    ),
    _BottomNavItem(
      tooltip: 'Analytics',
      icon: Icons.analytics_outlined,
      targetIndex: 4,
    ),
    _BottomNavItem(
      tooltip: 'Settings',
      icon: Icons.settings_rounded,
      targetIndex: 5,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = context.select<NavigationProvider, int>(
      (provider) => provider.currentIndex,
    );

    return SafeArea(
      minimum: const EdgeInsets.only(bottom: AppDimens.spacingMedium),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in _items)
                _BottomNavButton(
                  item: item,
                  selected: currentIndex == item.targetIndex,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavButton extends StatelessWidget {
  const _BottomNavButton({required this.item, required this.selected});

  final _BottomNavItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: item.tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () {
            context.read<NavigationProvider>().selectIndex(item.targetIndex);
          },
          child: Container(
            width: 56,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.primaryMuted : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              item.icon,
              color: selected ? AppColors.textPrimary : AppColors.textMuted,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem {
  const _BottomNavItem({
    required this.tooltip,
    required this.icon,
    required this.targetIndex,
  });

  final String tooltip;
  final IconData icon;
  final int targetIndex;
}
