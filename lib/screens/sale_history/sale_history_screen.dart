import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/utils/date_time_service.dart';
import '../../models/payment_mode.dart';
import '../../models/sale_history_model.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/sale_history_provider.dart';
import '../../widgets/animations/animated_currency_text.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sale History Screen
// Presentation layer only. All provider calls, repository interactions, and
// business logic are unchanged. Only this file is modified.
// ─────────────────────────────────────────────────────────────────────────────

class SaleHistoryScreen extends StatefulWidget {
  const SaleHistoryScreen({super.key});

  @override
  State<SaleHistoryScreen> createState() => _SaleHistoryScreenState();
}

class _SaleHistoryScreenState extends State<SaleHistoryScreen> {
  static const int _navigationIndex = 3;

  // Day-heading format: "5 September"
  static final DateFormat _dayHeadingFormat = DateFormat('d MMMM');

  // Full day format with year for accessibility / edge cases
  static final DateFormat _dayFullFormat = DateFormat('d MMMM yyyy');

  bool _wasActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SaleHistoryProvider>().loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isActive = context.select<NavigationProvider, bool>(
      (p) => p.currentIndex == _navigationIndex,
    );
    final provider = context.watch<SaleHistoryProvider>();
    final dateService = context.read<DateTimeService>();

    // Reload when the tab becomes active — same logic as before.
    if (isActive && !_wasActive) {
      _wasActive = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<SaleHistoryProvider>().loadOrders(forceReload: true);
        }
      });
    } else if (!isActive && _wasActive) {
      _wasActive = false;
    }

    // Order count for the current month (respects search filter).
    final orders = provider.orders;
    final orderCount = orders.length;

    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.spacingLarge,
            vertical: AppDimens.spacingMedium,
          ),
          // ── Width constraint: caps content at 720 px and centres it.
          // Leaves generous breathing room on wide landscape tablets while
          // keeping the layout dense enough to feel premium, not stretched.
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ────────────────────────────────────────────
                  _HistoryHeader(
                    provider: provider,
                    dateService: dateService,
                    orderCount: orderCount,
                    isLoading: provider.isLoading,
                    onCalendarTap: () => _chooseMonth(context, provider),
                  ),
                  const SizedBox(height: AppDimens.spacingMedium),
                  // ── Search bar ────────────────────────────────────────
                  _SearchBar(onChanged: provider.setSearchQuery),
                  const SizedBox(height: AppDimens.spacingMedium),
                  // ── Body ──────────────────────────────────────────────
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _buildBody(context, provider, dateService),
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

  Widget _buildBody(
    BuildContext context,
    SaleHistoryProvider provider,
    DateTimeService dateService,
  ) {
    if (provider.isLoading && !provider.hasLoaded) {
      return const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (provider.errorMessage != null) {
      return _ErrorState(
        key: const ValueKey('error'),
        message: provider.errorMessage!,
        onRetry: () => provider.loadOrders(forceReload: true),
      );
    }

    final orders = provider.orders;

    if (orders.isEmpty) {
      return _EmptyState(
        key: const ValueKey('empty'),
        hasSearch: provider.searchQuery.trim().isNotEmpty,
      );
    }

    return _OrderListView(
      key: const ValueKey('list'),
      orders: orders,
      dayHeadingFormat: _dayHeadingFormat,
      dayFullFormat: _dayFullFormat,
      dateService: dateService,
      onDelete: _handleDelete,
      onEdit: _handleEdit,
    );
  }

  Future<void> _chooseMonth(
    BuildContext context,
    SaleHistoryProvider provider,
  ) async {
    final month = await showDialog<DateTime>(
      context: context,
      builder: (_) => _MonthPickerDialog(selectedMonth: provider.selectedMonth),
    );
    if (month != null && context.mounted) {
      await provider.selectMonth(month);
    }
  }

  /// Called when the user confirms a delete on an order card.
  /// 1. Delegates the SQLite delete to the provider (optimistic removal).
  /// 2. Refreshes the Dashboard so its stats stay accurate.
  Future<void> _handleDelete(String orderKey) async {
    final historyProvider = context.read<SaleHistoryProvider>();
    final dashboardProvider = context.read<DashboardProvider>();

    await historyProvider.deleteOrder(orderKey);

    if (!mounted) return;
    // Refresh dashboard stats without blocking the UI.
    dashboardProvider.loadToday(forceReload: true);
    context.read<AnalyticsProvider>().load();
  }

  Future<void> _handleEdit(String orderKey) async {
    final salesProvider = context.read<SalesProvider>();
    await salesProvider.beginEditOrder(orderKey);
    if (!mounted) return;
    if (salesProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load order: ${salesProvider.error}')),
      );
      return;
    }
    context.read<NavigationProvider>().selectIndex(0);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Header — matches Dashboard header pattern exactly
// ═════════════════════════════════════════════════════════════════════════════

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({
    required this.provider,
    required this.dateService,
    required this.orderCount,
    required this.isLoading,
    required this.onCalendarTap,
  });

  final SaleHistoryProvider provider;
  final DateTimeService dateService;
  final int orderCount;
  final bool isLoading;
  final VoidCallback onCalendarTap;

  @override
  Widget build(BuildContext context) {
    final monthLabel = dateService.formatMonthYear(provider.selectedMonth);
    final countLabel = isLoading
        ? 'Loading…'
        : '$orderCount order${orderCount == 1 ? '' : 's'}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Left: title + count ────────────────────────────────────────
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              monthLabel,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              countLabel,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const Spacer(),
        // ── Right: calendar button — same style as Dashboard Refresh ───
        OutlinedButton.icon(
          onPressed: onCalendarTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            backgroundColor: AppColors.surface,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.calendar_month_rounded, size: 17),
          label: const Text(
            'Month',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Search bar — styled to match the app's input language
// ═════════════════════════════════════════════════════════════════════════════

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        hintText: 'Search by product or payment mode…',
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.textMuted,
          size: 20,
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Order list — day-grouped, scrolls as one continuous list
// ═════════════════════════════════════════════════════════════════════════════

class _OrderListView extends StatelessWidget {
  const _OrderListView({
    super.key,
    required this.orders,
    required this.dayHeadingFormat,
    required this.dayFullFormat,
    required this.dateService,
    required this.onDelete,
    required this.onEdit,
  });

  final List<SaleHistoryOrder> orders;
  final DateFormat dayHeadingFormat;
  final DateFormat dayFullFormat;
  final DateTimeService dateService;
  final Future<void> Function(String orderKey) onDelete;
  final Future<void> Function(String orderKey) onEdit;

  /// Groups orders into an ordered list of (day, [orders]) pairs.
  /// Preserves the newest-first ordering from the repository.
  List<MapEntry<DateTime, List<SaleHistoryOrder>>> _groupByDay() {
    final map = <DateTime, List<SaleHistoryOrder>>{};
    for (final order in orders) {
      final day = DateTime(
        order.createdAt.year,
        order.createdAt.month,
        order.createdAt.day,
      );
      map.putIfAbsent(day, () => []).add(order);
    }
    // Keys retain insertion order (Dart LinkedHashMap).
    return map.entries.toList();
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupByDay();
    final today = dateService.today;
    final yesterday = today.subtract(const Duration(days: 1));

    // Build a flat list of items: alternating day headers and order cards.
    // This avoids nested ListViews and scroll conflicts entirely.
    final items = <_ListItem>[];
    for (final entry in groups) {
      items.add(
        _DayHeaderItem(
          day: entry.key,
          today: today,
          yesterday: yesterday,
          headingFormat: dayHeadingFormat,
          fullFormat: dayFullFormat,
        ),
      );
      for (final order in entry.value) {
        items.add(
          _OrderCardItem(order: order, onDelete: onDelete, onEdit: onEdit),
        );
      }
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is _DayHeaderItem) {
          return _DayHeading(item: item);
        }
        if (item is _OrderCardItem) {
          // AnimatedSize collapses the card to zero height when the provider
          // removes it from _allOrders, giving a smooth disappearance.
          return AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOutCubic,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OrderCard(
                order: item.order,
                dateService: dateService,
                onDelete: item.onDelete,
                onEdit: item.onEdit,
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ── Sealed list item types (no actual sealing needed — just plain classes) ──

abstract class _ListItem {}

class _DayHeaderItem extends _ListItem {
  _DayHeaderItem({
    required this.day,
    required this.today,
    required this.yesterday,
    required this.headingFormat,
    required this.fullFormat,
  });

  final DateTime day;
  final DateTime today;
  final DateTime yesterday;
  final DateFormat headingFormat;
  final DateFormat fullFormat;

  String get label {
    if (day == today) return 'Today · ${headingFormat.format(day)}';
    if (day == yesterday) return 'Yesterday · ${headingFormat.format(day)}';
    return headingFormat.format(day);
  }
}

class _OrderCardItem extends _ListItem {
  _OrderCardItem({
    required this.order,
    required this.onDelete,
    required this.onEdit,
  });
  final SaleHistoryOrder order;
  final Future<void> Function(String orderKey) onDelete;
  final Future<void> Function(String orderKey) onEdit;
}

// ═════════════════════════════════════════════════════════════════════════════
// Day heading separator
// ═════════════════════════════════════════════════════════════════════════════

class _DayHeading extends StatelessWidget {
  const _DayHeading({required this.item});
  final _DayHeaderItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(
        children: [
          Text(
            item.label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Divider(color: AppColors.border, height: 1)),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Order card
// ═════════════════════════════════════════════════════════════════════════════

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.dateService,
    required this.onDelete,
    required this.onEdit,
  });

  final SaleHistoryOrder order;
  final DateTimeService dateService;
  final Future<void> Function(String orderKey) onDelete;
  final Future<void> Function(String orderKey) onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Main content row ───────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: time + payment badge + oil lines
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            dateService.formatTime(order.createdAt),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _PaymentBadge(mode: order.paymentMode),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...order.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.only(top: 2, right: 8),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${item.productName}  '
                                  '${item.quantityVariant} × '
                                  '${_formatQty(item.quantity)}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Right: total amount
                AnimatedCurrencyText(
                  value: order.totalAmount,
                  currencySymbol: '₹',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            // ── Bottom row: delete button pinned to the right ──────────
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _EditButton(onTap: () => onEdit(order.orderKey)),
                const SizedBox(width: 8),
                _DeleteButton(onTap: () => _confirmDelete(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (ctx, anim, _, child) {
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, _, _) => const _DeleteConfirmDialog(),
    );

    if (confirmed == true) {
      await onDelete(order.orderKey);
    }
  }

  static String _formatQty(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }
}

class _EditButton extends StatelessWidget {
  const _EditButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.edit_outlined, size: 16),
      label: const Text('EDIT'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(0, 34),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Delete button — circular red icon button, bottom-right of each card
// ═════════════════════════════════════════════════════════════════════════════

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onTap});
  final VoidCallback onTap;

  // Matches the size and feel of the Products & Pricing UPDATE PRICE button.
  static const double _size = 34.0;
  static const Color _bg = Color(0xFF3D1A1A);
  static const Color _border = Color(0xFF6B2828);
  static const Color _icon = Color(0xFFE06A5F); // AppColors.danger

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: _bg,
        shape: BoxShape.circle,
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE06A5F).withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          splashColor: const Color(0xFFE06A5F).withValues(alpha: 0.22),
          highlightColor: const Color(0xFFE06A5F).withValues(alpha: 0.12),
          child: const Icon(
            Icons.delete_outline_rounded,
            size: 16,
            color: _icon,
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Delete confirmation dialog — fade + scale entrance, no logic
// ═════════════════════════════════════════════════════════════════════════════

class _DeleteConfirmDialog extends StatelessWidget {
  const _DeleteConfirmDialog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF6B2828)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.40),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            padding: const EdgeInsets.all(AppDimens.spacingLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Icon + title ───────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3D1A1A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF6B2828)),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: AppColors.danger,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Delete Sale?',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.spacingMedium),
                // ── Message ────────────────────────────────────────────
                const Text(
                  'Are you sure you want to permanently delete this sale?',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'This action cannot be undone.',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppDimens.spacingLarge),
                // ── Actions ────────────────────────────────────────────
                Row(
                  children: [
                    // Cancel
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimens.spacingSmall),
                    // Confirm Delete
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.danger,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Confirm Delete',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Payment mode badge — replicates Dashboard's _PaymentMethodBadge exactly
// ═════════════════════════════════════════════════════════════════════════════

class _PaymentBadge extends StatelessWidget {
  const _PaymentBadge({required this.mode});
  final PaymentMode mode;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    final Color text;

    switch (mode) {
      case PaymentMode.cash:
        bg = const Color(0xFF1B3322);
        border = AppColors.primaryMuted;
        text = AppColors.primary;
        break;
      case PaymentMode.upi:
        bg = const Color(0xFF1B2A3A);
        border = const Color(0xFF2C4563);
        text = const Color(0xFF64B5F6);
        break;
      case PaymentMode.card:
        bg = const Color(0xFF332B1B);
        border = const Color(0xFF5E4929);
        text = AppColors.accent;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Text(
        mode.label.toUpperCase(),
        style: TextStyle(
          color: text,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Empty state — mirrors Dashboard's _EmptyOrdersState pattern
// ═════════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key, required this.hasSearch});
  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: AppColors.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 14),
          Text(
            hasSearch ? 'No matching orders' : 'No sales found',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasSearch
                ? 'Try a different product name or payment mode.'
                : 'Select another month using the calendar.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Error state — mirrors Products & Pricing _ErrorState pattern
// ═════════════════════════════════════════════════════════════════════════════

class _ErrorState extends StatelessWidget {
  const _ErrorState({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppDimens.spacingLarge),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
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
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Month picker dialog — visual refresh, logic unchanged
// ═════════════════════════════════════════════════════════════════════════════

class _MonthPickerDialog extends StatefulWidget {
  const _MonthPickerDialog({required this.selectedMonth});
  final DateTime selectedMonth;

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _selectedYear;
  static const int _minimumYear = 2026;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.selectedMonth.year < _minimumYear
        ? _minimumYear
        : widget.selectedMonth.year;
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = [for (var y = _minimumYear; y <= currentYear + 10; y++) y];
    final months = DateFormat.MMMM().dateSymbols.MONTHS;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 64),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.spacingLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Dialog header ──────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primaryMuted,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Choose Month',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    // Year selector — same dropdown, updated styling
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedYear,
                          dropdownColor: AppColors.surfaceElevated,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textMuted,
                            size: 18,
                          ),
                          isDense: true,
                          items: years
                              .map(
                                (y) => DropdownMenuItem(
                                  value: y,
                                  child: Text(y.toString()),
                                ),
                              )
                              .toList(),
                          onChanged: (y) {
                            if (y != null) {
                              setState(() => _selectedYear = y);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.spacingLarge),
                // ── Month grid ─────────────────────────────────────────
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 400 ? 4 : 3;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 12,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: AppDimens.spacingSmall,
                        mainAxisSpacing: AppDimens.spacingSmall,
                        childAspectRatio: 2.4,
                      ),
                      itemBuilder: (context, i) {
                        final month = DateTime(_selectedYear, i + 1);
                        final isSelected =
                            month.year == widget.selectedMonth.year &&
                            month.month == widget.selectedMonth.month;
                        return _MonthChip(
                          label: months[i],
                          isSelected: isSelected,
                          onTap: () => Navigator.of(context).pop(month),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Month chip — same logic as before, styled to match app chip language ──

class _MonthChip extends StatelessWidget {
  const _MonthChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          splashColor: AppColors.primary.withValues(alpha: 0.18),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.background
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
