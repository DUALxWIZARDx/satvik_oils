import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/date_time_service.dart';
import '../../models/dashboard_model.dart';
import '../../models/payment_mode.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/navigation_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _navigationIndex = 1;
  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs ',
    decimalDigits: 2,
  );
  bool _wasActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadToday();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isActive = context.select<NavigationProvider, bool>(
      (provider) => provider.currentIndex == _navigationIndex,
    );
    final provider = context.watch<DashboardProvider>();
    final dateTimeService = context.watch<DateTimeService>();
    final currentDateTime = dateTimeService.currentDateTime;
    final todayFormatted = dateTimeService.formatLongDate(currentDateTime);
    debugPrint('Dashboard receives: $currentDateTime');
    debugPrint('Dashboard renders subtitle: $todayFormatted');

    if (isActive && !_wasActive) {
      _wasActive = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<DashboardProvider>().loadToday(forceReload: true);
        }
      });
    } else if (!isActive && _wasActive) {
      _wasActive = false;
    }

    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.spacingLarge,
            vertical: AppDimens.spacingMedium,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DashboardHeader(
                provider: provider,
                todayFormatted: todayFormatted,
              ),
              const SizedBox(height: AppDimens.spacingMedium),
              if (provider.isLoading && !provider.hasLoaded)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                )
              else if (provider.errorMessage != null)
                Expanded(
                  child: _DashboardErrorState(message: provider.errorMessage!),
                )
              else
                Expanded(
                  child: _DashboardContent(
                    provider: provider,
                    currencyFormat: _currencyFormat,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.provider,
    required this.todayFormatted,
  });

  final DashboardProvider provider;
  final String todayFormatted;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dashboard', style: AppTextStyles.screenTitle),
            const SizedBox(height: 2),
            Text(
              todayFormatted,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: provider.isLoading
              ? null
              : () => provider.loadToday(forceReload: true),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            backgroundColor: AppColors.surface,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: provider.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : const Icon(Icons.refresh_rounded, size: 18),
          label: const Text(
            'Refresh',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.provider,
    required this.currencyFormat,
  });

  final DashboardProvider provider;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    final summary = provider.summary;
    final hasOrders = provider.hasOrdersToday;

    return LayoutBuilder(
      builder: (context, constraints) {
        final recentOrdersPanel = _RecentOrdersPanel(
          orders: provider.recentOrders,
          currencyFormat: currencyFormat,
        );
        final metricsPanel = _DashboardMetrics(
          summary: summary,
          hasOrders: hasOrders,
          currencyFormat: currencyFormat,
        );

        if (constraints.maxWidth < 850) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 340, child: metricsPanel),
                const SizedBox(height: AppDimens.spacingMedium),
                SizedBox(height: 420, child: recentOrdersPanel),
              ],
            ),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 1, child: recentOrdersPanel),
            const SizedBox(width: AppDimens.spacingMedium),
            Expanded(flex: 1, child: metricsPanel),
          ],
        );
      },
    );
  }
}

class _DashboardMetrics extends StatelessWidget {
  const _DashboardMetrics({
    required this.summary,
    required this.hasOrders,
    required this.currencyFormat,
  });

  final DashboardSummary? summary;
  final bool hasOrders;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _KpiCard(
                  label: "TODAY'S REVENUE",
                  value: hasOrders
                      ? currencyFormat.format(summary!.salesRevenue)
                      : '-',
                  emptyMessage: hasOrders ? null : 'No sales today',
                  icon: Icons.payments_outlined,
                  accentColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppDimens.spacingMedium),
              Expanded(
                child: _KpiCard(
                  label: "TODAY'S PROFIT",
                  value: hasOrders
                      ? currencyFormat.format(summary!.profit)
                      : '-',
                  emptyMessage: hasOrders ? null : 'No profit yet',
                  icon: Icons.trending_up_rounded,
                  accentColor: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.spacingMedium),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _KpiCard(
                  label: "TODAY'S ORDERS",
                  value: hasOrders ? summary!.orderCount.toString() : '-',
                  emptyMessage: hasOrders ? null : 'No orders today',
                  icon: Icons.shopping_bag_outlined,
                  accentColor: const Color(0xFF5B9EE1),
                ),
              ),
              const SizedBox(width: AppDimens.spacingMedium),
              Expanded(
                child: _KpiCard(
                  label: 'AVERAGE ORDER VALUE',
                  value: hasOrders
                      ? currencyFormat.format(summary!.averageOrderValue)
                      : '-',
                  emptyMessage: hasOrders ? null : 'No orders today',
                  icon: Icons.receipt_long_outlined,
                  accentColor: const Color(0xFFAB7FF8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    this.emptyMessage,
    required this.icon,
    required this.accentColor,
  });

  final String label;
  final String value;
  final String? emptyMessage;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(38),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(31),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: accentColor),
              ),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 30,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (emptyMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              emptyMessage!,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ] else ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Updated live',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          const Spacer(),
        ],
      ),
    );
  }
}

class _RecentOrdersPanel extends StatelessWidget {
  const _RecentOrdersPanel({
    required this.orders,
    required this.currencyFormat,
  });

  final List<RecentOrderSummary> orders;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(38),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Recent Orders', style: AppTextStyles.sectionTitle),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '${orders.length} today',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.spacingMedium),
            if (orders.isEmpty)
              const Expanded(
                child: _EmptyOrdersState(
                  message: 'No orders saved today.',
                ),
              )
            else
              Expanded(
                child: Column(
                  children: [
                    const _TableHeaderRow(),
                    const SizedBox(height: 6),
                    Expanded(
                      child: ListView.separated(
                        itemCount: orders.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          color: AppColors.border.withAlpha(102),
                        ),
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          return _OrderDataRow(
                            oilSummary: order.oilSummary,
                            time: order.time,
                            amountFormatted: currencyFormat.format(
                              order.totalAmount,
                            ),
                            paymentMode: order.paymentMode,
                          );
                        },
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

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow();

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(
      color: AppColors.textMuted,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withAlpha(153),
            width: 1,
          ),
        ),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 5,
            child: Text('OILS BOUGHT', style: headerStyle),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'TIME',
              textAlign: TextAlign.center,
              style: headerStyle,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'AMOUNT',
              textAlign: TextAlign.right,
              style: headerStyle,
            ),
          ),
          SizedBox(width: AppDimens.spacingMedium),
          Expanded(
            flex: 3,
            child: Text(
              'PAYMENT',
              textAlign: TextAlign.center,
              style: headerStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderDataRow extends StatelessWidget {
  const _OrderDataRow({
    required this.oilSummary,
    required this.time,
    required this.amountFormatted,
    required this.paymentMode,
  });

  final String oilSummary;
  final String time;
  final String amountFormatted;
  final PaymentMode paymentMode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              oilSummary,
              softWrap: true,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              time,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              amountFormatted,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppDimens.spacingMedium),
          Expanded(
            flex: 3,
            child: Center(
              child: _PaymentMethodBadge(paymentMode: paymentMode),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodBadge extends StatelessWidget {
  const _PaymentMethodBadge({required this.paymentMode});

  final PaymentMode paymentMode;

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color borderColor;
    final Color textColor;

    switch (paymentMode) {
      case PaymentMode.cash:
        bgColor = const Color(0xFF1B3322);
        borderColor = AppColors.primaryMuted;
        textColor = AppColors.primary;
        break;
      case PaymentMode.upi:
        bgColor = const Color(0xFF1B2A3A);
        borderColor = const Color(0xFF2C4563);
        textColor = const Color(0xFF64B5F6);
        break;
      case PaymentMode.card:
        bgColor = const Color(0xFF332B1B);
        borderColor = const Color(0xFF5E4929);
        textColor = AppColors.accent;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        paymentMode.label.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _EmptyOrdersState extends StatelessWidget {
  const _EmptyOrdersState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 44,
            color: AppColors.textMuted.withAlpha(128),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Completed sales will appear here in real time.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardErrorState extends StatelessWidget {
  const _DashboardErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppDimens.spacingLarge),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.danger.withAlpha(128)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: AppColors.danger,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

