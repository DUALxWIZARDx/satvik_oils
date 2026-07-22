import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/navigation_provider.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  static const _items = [
    _MenuItem(label: 'Sales', icon: Icons.point_of_sale_outlined),
    _MenuItem(label: 'Sale History', icon: Icons.receipt_long_outlined),
    _MenuItem(label: 'Reports', icon: Icons.bar_chart_outlined),
    _MenuItem(label: 'Settings', icon: Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = context.select<NavigationProvider, int>(
      (provider) => provider.currentIndex,
    );

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Satvik Oils', style: AppTextStyles.brand),
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),
            for (var index = 0; index < _items.length; index++)
              _NavigationTile(
                item: _items[index],
                selected: currentIndex == index,
                onTap: () {
                  context.read<NavigationProvider>().selectIndex(index);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _NavigationTile extends StatelessWidget {
  const _NavigationTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _MenuItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        selected: selected,
        leading: Icon(item.icon),
        title: Text(item.label),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        selectedColor: AppColors.textPrimary,
        selectedTileColor: AppColors.primaryMuted,
        iconColor: selected ? AppColors.textPrimary : AppColors.textSecondary,
        textColor: selected ? AppColors.textPrimary : AppColors.textSecondary,
        onTap: onTap,
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}
