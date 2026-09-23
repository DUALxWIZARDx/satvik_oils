import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/product_catalog.dart';
import '../../models/analytics_model.dart';
import '../../models/customer_model.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/customer_provider.dart';
import '../../widgets/cards/expandable_card_modal.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _loaded = false;

  static const _tints = [
    Color(0xFFCDA36A),
    Color(0xFF8FBFA8),
    Color(0xFFB99B73),
    Color(0xFF8D8A78),
    Color(0xFFD6C15E),
    Color(0xFFE2B84E),
    Color(0xFFAEB295),
    Color(0xFFC9957D),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().load();
      context.read<CustomerProvider>().loadCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalyticsProvider>();
    final report = provider.report;

    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.spacingLarge,
            vertical: AppDimens.spacingMedium,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Analytics', style: AppTextStyles.screenTitle),
                  const SizedBox(height: 6),
                  const Text(
                    'A clear view of your business performance.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppDimens.spacingLarge),
                  _AnalysisControls(
                    mode: provider.mode,
                    periodLabel: provider.periodLabel,
                    onModeChanged: provider.selectMode,
                    onPeriodPressed: () => _pickPeriod(provider),
                  ),
                  const SizedBox(height: 28),
                  Expanded(
                    child: provider.isLoading && report == null
                        ? const Center(child: CircularProgressIndicator())
                        : provider.error != null && report == null
                        ? _AnalyticsError(message: provider.error!)
                        : AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInOut,
                            child: _AnalyticsBody(
                              key: ValueKey(
                                '${provider.mode}-${provider.periodLabel}',
                              ),
                              provider: provider,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickPeriod(AnalyticsProvider provider) async {
    final selected = await showDialog<_AnalyticsSelection>(
      context: context,
      builder: (_) => _PeriodPickerDialog(
        mode: provider.mode,
        month: provider.selectedMonth,
        quarter: provider.selectedQuarter,
        year: provider.selectedYear,
      ),
    );
    if (selected == null) return;
    switch (selected.mode) {
      case AnalyticsMode.monthly:
        await provider.selectMonth(DateTime(selected.year, selected.month));
      case AnalyticsMode.quarterly:
        await provider.selectQuarter(selected.quarter, selected.year);
      case AnalyticsMode.annual:
        await provider.selectYear(selected.year);
    }
  }
}

class _AnalyticsSelection {
  const _AnalyticsSelection.monthly(this.year, this.month)
    : mode = AnalyticsMode.monthly,
      quarter = 1;
  const _AnalyticsSelection.quarterly(this.year, this.quarter)
    : mode = AnalyticsMode.quarterly,
      month = 1;
  const _AnalyticsSelection.annual(this.year)
    : mode = AnalyticsMode.annual,
      month = 1,
      quarter = 1;

  final AnalyticsMode mode;
  final int year;
  final int month;
  final int quarter;
}

class _AnalysisControls extends StatelessWidget {
  const _AnalysisControls({
    required this.mode,
    required this.periodLabel,
    required this.onModeChanged,
    required this.onPeriodPressed,
  });

  final AnalyticsMode mode;
  final String periodLabel;
  final ValueChanged<AnalyticsMode> onModeChanged;
  final VoidCallback onPeriodPressed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 560;
        final selector = _ModeSelector(mode: mode, onChanged: onModeChanged);
        final period = _PeriodButton(
          label: periodLabel,
          onPressed: onPeriodPressed,
        );
        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [selector, const SizedBox(height: 12), period],
          );
        }
        return Row(children: [selector, const Spacer(), period]);
      },
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.mode, required this.onChanged});

  final AnalyticsMode mode;
  final ValueChanged<AnalyticsMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final value in AnalyticsMode.values)
            _ModeSegment(
              label: value.name.toUpperCase(),
              selected: mode == value,
              onTap: () => onChanged(value),
            ),
        ],
      ),
    );
  }
}

class _ModeSegment extends StatelessWidget {
  const _ModeSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryMuted : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.textPrimary : AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  const _PeriodButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.textPrimary,
      backgroundColor: AppColors.surface,
      side: const BorderSide(color: AppColors.border),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    icon: const Icon(Icons.calendar_month_outlined, size: 18),
    label: AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: Text(
        label,
        key: ValueKey(label),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

class _AnalyticsError extends StatelessWidget {
  const _AnalyticsError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      padding: const EdgeInsets.all(AppDimens.spacingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(message, style: AppTextStyles.body),
    ),
  );
}

class _PeriodPickerDialog extends StatefulWidget {
  const _PeriodPickerDialog({
    required this.mode,
    required this.month,
    required this.quarter,
    required this.year,
  });

  final AnalyticsMode mode;
  final DateTime month;
  final int quarter;
  final int year;

  @override
  State<_PeriodPickerDialog> createState() => _PeriodPickerDialogState();
}

class _PeriodPickerDialogState extends State<_PeriodPickerDialog> {
  static const _firstYear = 2020;
  static const _lastYear = 2100;
  late int _selectedYear = widget.year;
  late final int _selectedMonth = widget.month.month;
  late final int _selectedQuarter = widget.quarter;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    child: Container(
      width: 420,
      padding: const EdgeInsets.all(AppDimens.spacingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'SELECT ${widget.mode.name.toUpperCase()} PERIOD',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppDimens.spacingMedium),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedYear,
                isExpanded: true,
                dropdownColor: AppColors.surfaceElevated,
                style: const TextStyle(color: AppColors.textPrimary),
                items: [
                  for (var year = _firstYear; year <= _lastYear; year++)
                    DropdownMenuItem(value: year, child: Text('$year')),
                ],
                onChanged: (year) {
                  if (year != null) setState(() => _selectedYear = year);
                },
              ),
            ),
          ),
          const SizedBox(height: AppDimens.spacingMedium),
          if (widget.mode == AnalyticsMode.monthly)
            Wrap(
              spacing: AppDimens.spacingSmall,
              runSpacing: AppDimens.spacingSmall,
              children: [
                for (var month = 1; month <= 12; month++)
                  _PickerChoice(
                    label: DateFormat.MMM().format(DateTime(2000, month)),
                    selected: _selectedMonth == month,
                    onTap: () => Navigator.pop(
                      context,
                      _AnalyticsSelection.monthly(_selectedYear, month),
                    ),
                  ),
              ],
            )
          else if (widget.mode == AnalyticsMode.quarterly)
            Row(
              children: [
                for (var quarter = 1; quarter <= 4; quarter++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: quarter == 4 ? 0 : 8),
                      child: _PickerChoice(
                        label: 'Q$quarter',
                        selected: _selectedQuarter == quarter,
                        onTap: () => Navigator.pop(
                          context,
                          _AnalyticsSelection.quarterly(_selectedYear, quarter),
                        ),
                      ),
                    ),
                  ),
              ],
            )
          else
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => Navigator.pop(
                context,
                _AnalyticsSelection.annual(_selectedYear),
              ),
              child: Text('USE $_selectedYear'),
            ),
        ],
      ),
    ),
  );
}

class _PickerChoice extends StatelessWidget {
  const _PickerChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 160),
    decoration: BoxDecoration(
      color: selected ? AppColors.primary : AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: selected ? AppColors.primary : AppColors.border,
      ),
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? AppColors.background : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ),
  );
}

class _AnalyticsBody extends StatelessWidget {
  const _AnalyticsBody({super.key, required this.provider});

  final AnalyticsProvider provider;

  @override
  Widget build(BuildContext context) {
    final report = provider.report;
    if (report == null) return const SizedBox.shrink();

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppDimens.spacingLarge),
      children: [
        const _SectionHeading(
          title: 'OVERVIEW',
          subtitle: 'Performance for the selected period',
        ),
        const SizedBox(height: AppDimens.spacingMedium),
        _Overview(summary: report.summary),
        const SizedBox(height: 36),
        const _SectionHeading(
          title: 'PRODUCT ANALYSIS',
          subtitle: 'Select a product to explore its variant performance',
        ),
        const SizedBox(height: AppDimens.spacingMedium),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = AppDimens.spacingMedium;
            final columns = ((constraints.maxWidth + spacing) / (230 + spacing))
                .floor()
                .clamp(2, 4);
            final width =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (
                  var index = 0;
                  index < ProductCatalog.products.length;
                  index++
                )
                  SizedBox(
                    width: width,
                    child: _ProductCard(
                      product: ProductCatalog.products[index],
                      performance: provider.performanceFor(
                        ProductCatalog.products[index],
                      ),
                      totalRevenue: report.summary.revenue,
                      periodLabel: provider.periodTableLabel,
                      tint: _AnalyticsScreenState._tints[index],
                      heroTag:
                          'analytics-product-${ProductCatalog.products[index].id}',
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 36),
        _PaymentAnalysis(
          payments: report.payments,
          totalRevenue: report.summary.revenue,
        ),
        const SizedBox(height: 36),
        const _MembershipSection(),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: AppTextStyles.sectionTitle),
      if (subtitle != null) ...[
        const SizedBox(height: 4),
        Text(
          subtitle!,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ],
  );
}

class _Overview extends StatelessWidget {
  const _Overview({required this.summary});
  final AnalyticsSummary summary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _MetricCard(
            label: 'TOTAL REVENUE',
            value: _money(summary.revenue),
            icon: Icons.account_balance_wallet_outlined,
            accent: AppColors.primary,
          ),
          _MetricCard(
            label: 'TOTAL PROFIT',
            value: _money(summary.profit),
            icon: Icons.trending_up_rounded,
            accent: AppColors.accent,
          ),
          _MetricCard(
            label: 'TOTAL ORDERS',
            value: '${summary.orders}',
            icon: Icons.shopping_bag_outlined,
            accent: const Color(0xFF5B9EE1),
          ),
          _MetricCard(
            label: 'AVERAGE ORDER VALUE',
            value: _money(summary.aov),
            icon: Icons.receipt_long_outlined,
            accent: const Color(0xFFAB7FF8),
          ),
        ];
        final compact = constraints.maxWidth < 760;
        return Wrap(
          spacing: AppDimens.spacingMedium,
          runSpacing: AppDimens.spacingMedium,
          children: [
            for (final card in cards)
              SizedBox(
                width: compact
                    ? (constraints.maxWidth - AppDimens.spacingMedium) / 2
                    : (constraints.maxWidth - AppDimens.spacingMedium * 3) / 4,
                child: card,
              ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppDimens.spacingMedium),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.16),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: accent, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 18),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 25,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.performance,
    required this.totalRevenue,
    required this.periodLabel,
    required this.tint,
    required this.heroTag,
  });

  final CatalogProduct product;
  final ProductPerformance performance;
  final double totalRevenue;
  final String periodLabel;
  final Color tint;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    final contribution = totalRevenue == 0
        ? 0.0
        : performance.revenue / totalRevenue * 100;
    final variants = {
      for (final variant in performance.variants) variant.variant: variant,
    };

    return ExpandableCardModal(
      heroTag: heroTag,
      tintColor: tint,
      collapsedChild: Padding(
        padding: const EdgeInsets.all(AppDimens.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.water_drop_rounded, color: tint, size: 18),
                ),
                const Spacer(),
                const Icon(
                  Icons.open_in_full_rounded,
                  color: AppColors.textMuted,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '${_litres(performance.litresSold)} sold',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      expandedChild: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 42),
              child: Text(
                product.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Divider(color: tint.withValues(alpha: 0.35)),
            Text(
              'VARIANT PERFORMANCE',
              style: TextStyle(color: tint, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _TableHeader(periodLabel: periodLabel),
            for (final variant in product.quantityVariants)
              _VariantRow(
                variant: variant,
                quantity: variants[variant]?.quantity ?? 0,
              ),
            const SizedBox(height: 26),
            Text(
              'PRODUCT $periodLabel SUMMARY',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _SummaryRow(
              label: 'Revenue Contribution',
              value: '${contribution.toStringAsFixed(1)}%',
            ),
            _SummaryRow(label: 'Revenue', value: _money(performance.revenue)),
            _SummaryRow(
              label: 'Total Litres Sold',
              value: _litres(performance.litresSold),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.periodLabel});
  final String periodLabel;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        const Expanded(
          child: Text('Variant', style: TextStyle(color: AppColors.textMuted)),
        ),
        Text(
          'Units Sold ($periodLabel)',
          style: const TextStyle(color: AppColors.textMuted),
        ),
      ],
    ),
  );
}

class _PaymentAnalysis extends StatelessWidget {
  const _PaymentAnalysis({required this.payments, required this.totalRevenue});

  final List<PaymentPerformance> payments;
  final double totalRevenue;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _SectionHeading(
        title: 'PAYMENT ANALYSIS',
        subtitle: 'Revenue split by payment method',
      ),
      const SizedBox(height: AppDimens.spacingMedium),
      Container(
        padding: const EdgeInsets.all(AppDimens.spacingMedium),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            for (final payment in payments)
              _PaymentRow(payment: payment, totalRevenue: totalRevenue),
          ],
        ),
      ),
    ],
  );
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment, required this.totalRevenue});

  final PaymentPerformance payment;
  final double totalRevenue;

  @override
  Widget build(BuildContext context) {
    final contribution = totalRevenue == 0
        ? 0.0
        : payment.revenue / totalRevenue * 100;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              payment.mode.label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Text(
            '${_money(payment.revenue)} · '
            '${contribution.toStringAsFixed(1)}% · ${payment.orders} orders',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _VariantRow extends StatelessWidget {
  const _VariantRow({required this.variant, required this.quantity});
  final String variant;
  final double quantity;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(
          child: Text(
            variant,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        Text(
          _quantity(quantity),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      ],
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _MembershipSection extends StatelessWidget {
  const _MembershipSection();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();
    final members = provider.membershipCustomers;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'MEMBERSHIP CUSTOMERS',
                  style: AppTextStyles.sectionTitle,
                ),
              ),
              Text(
                '${members.length} active',
                style: const TextStyle(color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Add membership customer',
                onPressed: () => _edit(context),
                icon: const Icon(Icons.person_add_alt_1_outlined),
              ),
            ],
          ),
          if (members.isEmpty)
            const Text(
              'No active membership customers.',
              style: TextStyle(color: AppColors.textMuted),
            )
          else
            ...members.map(
              (customer) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  customer.name,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                subtitle: Text(
                  '${customer.phone}\n${customer.address}',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                trailing: IconButton(
                  tooltip: 'Edit membership customer',
                  onPressed: () => _edit(context, customer),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _edit(BuildContext context, [CustomerModel? customer]) {
    showDialog<void>(
      context: context,
      builder: (_) => _MembershipEditor(customer: customer),
    );
  }
}

class _MembershipEditor extends StatefulWidget {
  const _MembershipEditor({this.customer});
  final CustomerModel? customer;

  @override
  State<_MembershipEditor> createState() => _MembershipEditorState();
}

class _MembershipEditorState extends State<_MembershipEditor> {
  late final _name = TextEditingController(text: widget.customer?.name ?? '');
  late final _phone = TextEditingController(text: widget.customer?.phone ?? '');
  late final _address = TextEditingController(
    text: widget.customer?.address ?? '',
  );

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.customer == null
          ? 'Add Membership Customer'
          : 'Edit Membership Customer',
    ),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: _phone,
            decoration: const InputDecoration(labelText: 'Phone Number'),
          ),
          TextField(
            controller: _address,
            decoration: const InputDecoration(labelText: 'Address'),
          ),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Membership fee: ₹500'),
          ),
        ],
      ),
    ),
    actions: [
      if (widget.customer != null)
        TextButton(
          onPressed: _removeMembership,
          child: const Text('Remove Membership'),
        ),
      FilledButton(onPressed: _save, child: const Text('Save')),
    ],
  );

  Future<void> _save() async {
    try {
      await context.read<CustomerProvider>().saveMembership(
        customer: widget.customer,
        name: _name.text,
        phone: _phone.text,
        address: _address.text,
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _removeMembership() async {
    final customerProvider = context.read<CustomerProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Membership?'),
        content: const Text('Customer and historical sales will remain.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await customerProvider.removeMembership(widget.customer!);
    if (mounted) Navigator.pop(context);
  }
}

String _money(double value) => NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
).format(value);

String _quantity(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2);

String _litres(double value) => '${_quantity(value)} L';
