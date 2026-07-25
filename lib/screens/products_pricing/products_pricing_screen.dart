import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_text_styles.dart';

class ProductsPricingScreen extends StatelessWidget {
  const ProductsPricingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.spacingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Products & Pricing', style: AppTextStyles.screenTitle),
          const SizedBox(height: AppDimens.spacingLarge),
          Container(
            padding: const EdgeInsets.all(AppDimens.spacingLarge),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Products & Pricing', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 8),
                Text(
                  'Product and pricing management will be added here.',
                  style: AppTextStyles.body,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
