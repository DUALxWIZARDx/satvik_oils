import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/sales_provider.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimens.topBarHeight,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Menu',
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          const SizedBox(width: 12),
          Text('Satvik Oils', style: AppTextStyles.brand),
          const Spacer(),
          Selector<SalesProvider, double>(
            selector: (_, provider) => provider.todaysSalesRevenue,
            builder: (_, revenue, _) => _Metric(
              label: "Today's Sales",
              value: '₹${revenue.toStringAsFixed(2)}',
            ),
          ),
          const SizedBox(width: 24),
          Selector<SalesProvider, int>(
            selector: (_, provider) => provider.todaysOrdersCount,
            builder: (_, orders, _) =>
                _Metric(label: "Today's Orders", value: orders.toString()),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.metric),
        ],
      ),
    );
  }
}
