import 'package:flutter/material.dart';

import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_text_styles.dart';

class SaleHistoryScreen extends StatelessWidget {
  const SaleHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.spacingLarge),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text('Sale History', style: AppTextStyles.screenTitle),
      ),
    );
  }
}
