import 'package:flutter/material.dart';

import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_text_styles.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.spacingLarge),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text('Settings', style: AppTextStyles.screenTitle),
      ),
    );
  }
}
