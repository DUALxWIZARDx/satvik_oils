import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/cart_item.dart';
import '../../models/payment_mode.dart';
import '../../providers/sales_provider.dart';
import '../../widgets/animations/animated_currency_text.dart';
import '../../widgets/feedback/floating_success_banner.dart';
import '../../widgets/feedback/success_toast.dart';

/// Stand-alone full-screen cart view.
/// All provider calls are identical to the original — only the presentation
/// layer has changed to match the new POS design language.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Cart list ──────────────────────────────────────────────
              Expanded(flex: 58, child: _CartListPanel(provider: provider)),
              const SizedBox(width: 16),
              // ── Controls sidebar ───────────────────────────────────────
              SizedBox(
                width: 320,
                child: _CartSidebarPanel(provider: provider),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LEFT — Cart item list
// ═══════════════════════════════════════════════════════════════════════════

class _CartListPanel extends StatelessWidget {
  const _CartListPanel({required this.provider});
  final SalesProvider provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          _PanelHeader(
            icon: Icons.shopping_cart_outlined,
            title: 'ORDER',
            badge: provider.cart.isEmpty
                ? null
                : '${provider.cart.length} item${provider.cart.length == 1 ? '' : 's'}',
          ),
          const Divider(color: AppColors.border, height: 1),
          // Items
          Expanded(
            child: provider.cart.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    itemCount: provider.cart.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = provider.cart[index];
                      return _CartItemRow(
                        item: item,
                        onRemove: () => provider.removeCartItem(item),
                      );
                    },
                  ),
          ),
          // Back button
          const Divider(color: AppColors.border, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SizedBox(
              height: 46,
              child: OutlinedButton.icon(
                onPressed: provider.isSaving
                    ? null
                    : () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text(
                  'ADD MORE PRODUCTS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RIGHT — Discount, payment, totals, save order
// ═══════════════════════════════════════════════════════════════════════════

class _CartSidebarPanel extends StatelessWidget {
  const _CartSidebarPanel({required this.provider});
  final SalesProvider provider;

  @override
  Widget build(BuildContext context) {
    final hasItems = provider.cart.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PanelHeader(
            icon: Icons.receipt_long_outlined,
            title: 'SUMMARY',
          ),
          const Divider(color: AppColors.border, height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Discount
                  const _SectionLabel('DISCOUNT'),
                  const SizedBox(height: 8),
                  _DiscountChips(provider: provider),
                  const SizedBox(height: 16),
                  // Payment mode
                  const _SectionLabel('PAYMENT'),
                  const SizedBox(height: 8),
                  _PaymentChips(provider: provider),
                  const SizedBox(height: 16),
                  // Totals
                  _TotalsBlock(provider: provider),
                ],
              ),
            ),
          ),
          // Save Order
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: _SaveOrderButton(provider: provider, hasItems: hasItems),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shared sub-widgets
// ═══════════════════════════════════════════════════════════════════════════

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.icon, required this.title, this.badge});

  final IconData icon;
  final String title;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 16),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const Spacer(),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryMuted,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 40,
            color: AppColors.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 10),
          const Text(
            'No items yet',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Go back and add products to the order',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Cart item row ─────────────────────────────────────────────────────────

class _CartItemRow extends StatelessWidget {
  const _CartItemRow({required this.item, required this.onRemove});

  final CartItem item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Accent dot
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.variant}  ×  ${item.quantity}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Price + remove
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedCurrencyText(
                value: item.lineTotal,
                currencySymbol: '₹',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              GestureDetector(
                onTap: onRemove,
                child: const Text(
                  'Remove',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Discount chips ────────────────────────────────────────────────────────

class _DiscountChips extends StatelessWidget {
  const _DiscountChips({required this.provider});
  final SalesProvider provider;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [5, 7, 10, 12, 15].map((p) {
        final isSelected = provider.orderDiscountPercent == p;
        return _SelectableChip(
          label: '$p%',
          isSelected: isSelected,
          onTap: () => provider.setOrderDiscountPercent(isSelected ? 0 : p),
        );
      }).toList(),
    );
  }
}

// ── Payment chips ─────────────────────────────────────────────────────────

class _PaymentChips extends StatelessWidget {
  const _PaymentChips({required this.provider});
  final SalesProvider provider;

  static const _icons = {
    PaymentMode.cash: Icons.payments_outlined,
    PaymentMode.upi: Icons.qr_code_rounded,
    PaymentMode.card: Icons.credit_card_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: PaymentMode.values.map((mode) {
        final isSelected = provider.selectedPaymentMode == mode;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _PaymentModeChip(
            mode: mode,
            icon: _icons[mode]!,
            isSelected: isSelected,
            onTap: () => provider.setPaymentMode(mode),
          ),
        );
      }).toList(),
    );
  }
}

class _PaymentModeChip extends StatelessWidget {
  const _PaymentModeChip({
    required this.mode,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final PaymentMode mode;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryMuted : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  mode.label,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Generic selectable chip ───────────────────────────────────────────────

class _SelectableChip extends StatelessWidget {
  const _SelectableChip({
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          splashColor: AppColors.primary.withValues(alpha: 0.18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.background
                    : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Totals block ──────────────────────────────────────────────────────────

class _TotalsBlock extends StatelessWidget {
  const _TotalsBlock({required this.provider});
  final SalesProvider provider;

  @override
  Widget build(BuildContext context) {
    final hasDiscount = provider.orderDiscountPercent > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _TotalRow(
            label: 'Subtotal',
            value: AnimatedCurrencyText(
              value: provider.subtotal,
              currencySymbol: '₹',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            labelStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            valueStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (hasDiscount) ...[
            const SizedBox(height: 6),
            _TotalRow(
              label: 'Discount (${provider.orderDiscountPercent}%)',
              value: AnimatedCurrencyText(
                value: provider.discountAmount,
                currencySymbol: '₹',
                prefix: '−',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              labelStyle: const TextStyle(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              valueStyle: const TextStyle(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 8),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 10),
          _TotalRow(
            label: 'Total',
            value: AnimatedCurrencyText(
              value: provider.finalTotal,
              currencySymbol: '₹',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            labelStyle: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            valueStyle: const TextStyle(
              color: AppColors.primary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
  });

  final String label;
  final Widget value;
  final TextStyle labelStyle;
  final TextStyle valueStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: labelStyle),
        value,
      ],
    );
  }
}

// ── Save Order button ─────────────────────────────────────────────────────

class _SaveOrderButton extends StatelessWidget {
  const _SaveOrderButton({required this.provider, required this.hasItems});

  final SalesProvider provider;
  final bool hasItems;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: (!hasItems || provider.isSaving)
            ? null
            : () async {
                await provider.saveOrder();
                if (!context.mounted) return;
                if (provider.error == null) {
                  FloatingSuccessBanner.showOrderSaved(context);
                  Navigator.of(context).pop();
                } else {
                  SuccessToast.show(context, 'Error: ${provider.error!}');
                }
              },
        style: FilledButton.styleFrom(
          backgroundColor: hasItems
              ? AppColors.primary
              : AppColors.surfaceElevated,
          foregroundColor: AppColors.background,
          disabledBackgroundColor: AppColors.surfaceElevated,
          disabledForegroundColor: AppColors.textMuted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: provider.isSaving
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.background,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                    color: hasItems
                        ? AppColors.background
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'SAVE ORDER',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: hasItems
                          ? AppColors.background
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
