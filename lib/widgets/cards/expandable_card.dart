import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';

class ExpandableCard extends StatelessWidget {
  const ExpandableCard({
    super.key,
    required this.header,
    required this.child,
    required this.expanded,
    required this.onToggle,
  });

  final Widget header;
  final Widget child;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceElevated,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.spacingMedium),
              child: Row(
                children: [
                  Expanded(child: header),
                  Icon(expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppDimens.spacingMedium),
              child: child,
            ),
          ],
        ],
      ),
    );
  }
}
