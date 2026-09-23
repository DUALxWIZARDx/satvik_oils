import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/analytics_model.dart';
import '../../models/customer_model.dart';
import '../../providers/customer_provider.dart';
import '../../providers/reports_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsProvider>().load();
      context.read<CustomerProvider>().loadCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = context.watch<ReportsProvider>();
    final c = context.watch<CustomerProvider>();
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.spacingLarge),
          child: ListView(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Analytics', style: AppTextStyles.screenTitle),
                  ),
                  _PeriodPicker(provider: r),
                ],
              ),
              const SizedBox(height: 16),
              if (r.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (r.report != null) ...[
                _Overview(report: r.report!),
                const SizedBox(height: 14),
                _Comparison(report: r.report!),
                const SizedBox(height: 14),
                _Trends(report: r.report!),
                const SizedBox(height: 14),
                _Products(report: r.report!),
                const SizedBox(height: 14),
                _Payments(report: r.report!),
              ],
              const SizedBox(height: 14),
              _Membership(provider: c),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodPicker extends StatelessWidget {
  const _PeriodPicker({required this.provider});
  final ReportsProvider provider;
  @override
  Widget build(BuildContext context) => PopupMenuButton<AnalyticsPeriod>(
    color: AppColors.surface,
    onSelected: (p) async {
      if (p == AnalyticsPeriod.custom) {
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          initialDateRange: provider.range,
        );
        if (range != null) await provider.setPeriod(p, range: range);
      } else {
        await provider.setPeriod(p);
      }
    },
    itemBuilder: (_) => const [
      PopupMenuItem(value: AnalyticsPeriod.month, child: Text('Month')),
      PopupMenuItem(value: AnalyticsPeriod.year, child: Text('Year')),
      PopupMenuItem(value: AnalyticsPeriod.custom, child: Text('Custom range')),
    ],
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_month_outlined,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            provider.period.name.toUpperCase(),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class _Overview extends StatelessWidget {
  const _Overview({required this.report});
  final AnalyticsReport report;
  @override
  Widget build(BuildContext context) => _Card(
    title: 'SALES OVERVIEW',
    child: Wrap(
      spacing: 34,
      runSpacing: 12,
      children: [
        _Metric(
          '₹${report.summary.revenue.toStringAsFixed(0)}',
          'Total Revenue',
        ),
        _Metric('₹${report.summary.profit.toStringAsFixed(0)}', 'Total Profit'),
        _Metric('${report.summary.orders}', 'Total Orders'),
        _Metric(
          '₹${report.summary.aov.toStringAsFixed(0)}',
          'Average Order Value',
        ),
      ],
    ),
  );
}

class _Comparison extends StatelessWidget {
  const _Comparison({required this.report});
  final AnalyticsReport report;
  String x(double now, double old) =>
      old == 0 ? '—' : '${((now - old) / old * 100).toStringAsFixed(1)}%';
  @override
  Widget build(BuildContext context) => _Card(
    title: 'VS PREVIOUS PERIOD',
    child: Wrap(
      spacing: 30,
      children: [
        _Metric(x(report.summary.revenue, report.previous.revenue), 'Revenue'),
        _Metric(x(report.summary.profit, report.previous.profit), 'Profit'),
        _Metric(
          x(
            report.summary.orders.toDouble(),
            report.previous.orders.toDouble(),
          ),
          'Orders',
        ),
      ],
    ),
  );
}

class _Trends extends StatelessWidget {
  const _Trends({required this.report});
  final AnalyticsReport report;
  @override
  Widget build(BuildContext context) => _Card(
    title: 'SALES TRENDS',
    child: report.days.isEmpty
        ? const Text(
            'No sales in this period.',
            style: TextStyle(color: AppColors.textMuted),
          )
        : Column(
            children: report.days
                .map(
                  (d) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 75,
                          child: Text(
                            '${d.date.day}/${d.date.month}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: report.summary.revenue == 0
                                ? 0
                                : d.summary.revenue / report.summary.revenue,
                            color: AppColors.primary,
                            backgroundColor: AppColors.surfaceElevated,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '₹${d.summary.revenue.toStringAsFixed(0)}  ₹${d.summary.profit.toStringAsFixed(0)}  ${d.summary.orders} orders',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
  );
}

class _Products extends StatelessWidget {
  const _Products({required this.report});
  final AnalyticsReport report;
  @override
  Widget build(BuildContext context) {
    final products = [...report.products]
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
    return _Card(
      title: 'PRODUCT PERFORMANCE',
      child: Column(
        children: products
            .map(
              (p) => ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  p.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '${p.quantity.toStringAsFixed(0)} units · ₹${p.revenue.toStringAsFixed(0)} revenue · ₹${p.profit.toStringAsFixed(0)} profit',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                children: p.variants
                    .map(
                      (v) => ListTile(
                        title: Text(
                          v.variant,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        trailing: Text(
                          '${v.quantity.toStringAsFixed(0)} · ₹${v.revenue.toStringAsFixed(0)} · ₹${v.profit.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Payments extends StatelessWidget {
  const _Payments({required this.report});
  final AnalyticsReport report;
  @override
  Widget build(BuildContext context) => _Card(
    title: 'PAYMENT ANALYSIS',
    child: Column(
      children: report.payments
          .map(
            (p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      p.mode.label,
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                  Text(
                    '₹${p.revenue.toStringAsFixed(0)} · ${p.orders} orders',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    ),
  );
}

class _Membership extends StatelessWidget {
  const _Membership({required this.provider});
  final CustomerProvider provider;
  @override
  Widget build(BuildContext context) {
    final members = provider.membershipCustomers;
    return _Card(
      title: 'MEMBERSHIP CUSTOMERS',
      action: TextButton(
        onPressed: () => _edit(context),
        child: const Text('Edit'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${members.length} active membership customers',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
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
                onPressed: () => _edit(context, customer),
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _edit(BuildContext context, [CustomerModel? customer]) => showDialog(
    context: context,
    builder: (_) => _MemberEditor(customer: customer),
  );
}

class _MemberEditor extends StatefulWidget {
  const _MemberEditor({this.customer});
  final CustomerModel? customer;
  @override
  State<_MemberEditor> createState() => _MemberEditorState();
}

class _MemberEditorState extends State<_MemberEditor> {
  late final n = TextEditingController(text: widget.customer?.name),
      p = TextEditingController(text: widget.customer?.phone),
      a = TextEditingController(text: widget.customer?.address);
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.customer == null
          ? 'Add Membership Customer'
          : 'Edit Membership Customer',
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: n,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        TextField(
          controller: p,
          decoration: const InputDecoration(labelText: 'Phone Number'),
        ),
        TextField(
          controller: a,
          decoration: const InputDecoration(labelText: 'Address'),
        ),
        const Text('Membership fee: ₹500'),
      ],
    ),
    actions: [
      if (widget.customer != null)
        TextButton(
          onPressed: () async {
            final customerProvider = context.read<CustomerProvider>();
            final ok = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('Remove Membership?'),
                content: const Text(
                  'Customer and historical sales will remain.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text('Remove'),
                  ),
                ],
              ),
            );
            if (ok == true) {
              await customerProvider.removeMembership(widget.customer!);
              if (!context.mounted) return;
              Navigator.pop(context);
            }
          },
          child: const Text('Remove Membership'),
        ),
      FilledButton(
        onPressed: () async {
          final customerProvider = context.read<CustomerProvider>();
          await customerProvider.saveMembership(
            customer: widget.customer,
            name: n.text,
            phone: p.text,
            address: a.text,
          );
          if (!context.mounted) return;
          Navigator.pop(context);
        },
        child: const Text('Save'),
      ),
    ],
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child, this.action});
  final String title;
  final Widget child;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              action ?? const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.value, this.label);
  final String value, label;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
      Text(
        label,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
      ),
    ],
  );
}
