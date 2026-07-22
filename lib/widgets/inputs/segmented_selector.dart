import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class SegmentedSelectorItem<T> {
  const SegmentedSelectorItem({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}

class SegmentedSelector<T> extends StatelessWidget {
  const SegmentedSelector({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
  });

  final List<SegmentedSelectorItem<T>> items;
  final T selectedValue;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          ChoiceChip(
            selected: item.value == selectedValue,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.icon != null) ...[
                  Icon(item.icon, size: 16),
                  const SizedBox(width: 6),
                ],
                Text(item.label),
              ],
            ),
            selectedColor: AppColors.primaryMuted,
            backgroundColor: AppColors.surfaceElevated,
            side: const BorderSide(color: AppColors.border),
            onSelected: (_) => onChanged(item.value),
          ),
      ],
    );
  }
}
