import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/product_catalog.dart';
import '../../providers/sales_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/sale_history_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../models/payment_mode.dart';
import '../../models/cart_item.dart';
import '../../widgets/animations/animated_currency_text.dart';
import '../../widgets/feedback/floating_success_banner.dart';
import '../../widgets/feedback/success_toast.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final _quantityController = TextEditingController();
  final _quantityFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SalesProvider>();
      provider.refreshCurrentPrice();
      context.read<CustomerProvider>().loadCustomers();
      _quantityController.text = provider.quantity.toString();
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _quantityFocus.dispose();
    super.dispose();
  }

  void _syncQuantityField(int qty) {
    final text = qty.toString();
    if (_quantityController.text != text) {
      _quantityController.text = text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesProvider>();
    _syncQuantityField(provider.quantity);

    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const verticalPadding = 32.0;
            final availableHeight = (constraints.maxHeight - verticalPadding)
                .clamp(0.0, double.infinity);

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: SizedBox(
                height: availableHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── LEFT PANEL ─────────────────────────────────────────
                    Expanded(
                      flex: 55,
                      child: _LeftPanel(
                        provider: provider,
                        quantityController: _quantityController,
                        quantityFocus: _quantityFocus,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // ── RIGHT PANEL ────────────────────────────────────────
                    Expanded(flex: 45, child: _RightPanel(provider: provider)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LEFT PANEL — Product selection, variant, quantity, add to cart
// ═══════════════════════════════════════════════════════════════════════════

class _LeftPanel extends StatelessWidget {
  const _LeftPanel({
    required this.provider,
    required this.quantityController,
    required this.quantityFocus,
  });

  final SalesProvider provider;
  final TextEditingController quantityController;
  final FocusNode quantityFocus;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 620;
        final sectionGap = isCompact ? 12.0 : 20.0;
        final labelGap = isCompact ? 6.0 : 10.0;
        final gridHeight = (((constraints.maxWidth - 24) / 4) / 2.4 * 2 + 8)
            .clamp(96.0, isCompact ? 100.0 : 140.0)
            .clamp(0.0, constraints.maxHeight * 0.30);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PanelLabel('PRODUCT'),
            SizedBox(height: isCompact ? 8 : 12),
            _ProductGrid(provider: provider, height: gridHeight),
            SizedBox(height: sectionGap),
            const _PanelLabel('SIZE / VARIANT'),
            SizedBox(height: labelGap),
            _VariantChips(provider: provider),
            SizedBox(height: sectionGap),
            const _PanelLabel('QUANTITY'),
            SizedBox(height: labelGap),
            _QuantityRow(
              provider: provider,
              controller: quantityController,
              focusNode: quantityFocus,
            ),
            SizedBox(height: sectionGap),
            _PriceReadout(provider: provider),
            const Spacer(),
            _AddToCartButton(provider: provider),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

// ── Panel section label ──────────────────────────────────────────────────

class _PanelLabel extends StatelessWidget {
  const _PanelLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ── Product grid ─────────────────────────────────────────────────────────

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.provider, required this.height});
  final SalesProvider provider;
  final double height;

  @override
  Widget build(BuildContext context) {
    final products = ProductCatalog.products;
    return SizedBox(
      height: height,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          mainAxisExtent: (height - 8) / 2,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          final isSelected = provider.selectedProduct?.id == product.id;
          return _ProductTile(
            product: product,
            isSelected: isSelected,
            onTap: () {
              provider.selectProduct(product);
              provider.refreshCurrentPrice();
            },
          );
        },
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.isSelected,
    required this.onTap,
  });

  final CatalogProduct product;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          splashColor: AppColors.primary.withValues(alpha: 0.18),
          highlightColor: AppColors.primary.withValues(alpha: 0.10),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                product.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.background
                      : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Variant chips ────────────────────────────────────────────────────────

class _VariantChips extends StatelessWidget {
  const _VariantChips({required this.provider});
  final SalesProvider provider;

  @override
  Widget build(BuildContext context) {
    final variants =
        provider.selectedProduct?.quantityVariants ??
        ProductCatalog.quantityVariants;
    return Row(
      children: variants.map((v) {
        final isSelected = provider.selectedVariant == v;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _SelectableChip(
            label: v,
            isSelected: isSelected,
            onTap: () {
              provider.selectVariant(v);
              provider.refreshCurrentPrice();
            },
          ),
        );
      }).toList(),
    );
  }
}

// ── Generic selectable chip ──────────────────────────────────────────────

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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
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

// ── Quantity row ─────────────────────────────────────────────────────────

class _QuantityRow extends StatelessWidget {
  const _QuantityRow({
    required this.provider,
    required this.controller,
    required this.focusNode,
  });

  final SalesProvider provider;
  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Decrement
        _QuantityButton(
          icon: Icons.remove,
          onTap: provider.quantity > 1
              ? () => provider.setQuantity(provider.quantity - 1)
              : null,
        ),
        const SizedBox(width: 10),
        // Text field
        SizedBox(
          width: 72,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceElevated,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
            onChanged: (v) {
              final parsed = int.tryParse(v.trim()) ?? 1;
              provider.setQuantity(parsed);
            },
          ),
        ),
        const SizedBox(width: 10),
        // Increment
        _QuantityButton(
          icon: Icons.add,
          onTap: () => provider.setQuantity(provider.quantity + 1),
        ),
      ],
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: onTap == null ? 0.35 : 1.0,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Icon(icon, color: AppColors.textSecondary, size: 18),
          ),
        ),
      ),
    );
  }
}

// ── Price readout ────────────────────────────────────────────────────────

class _PriceReadout extends StatelessWidget {
  const _PriceReadout({required this.provider});
  final SalesProvider provider;

  @override
  Widget build(BuildContext context) {
    final hasPrice = provider.currentPrice != null;
    final unitPrice = provider.currentPrice?.sellingPrice ?? 0.0;
    final lineTotal = unitPrice * provider.quantity;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'UNIT PRICE',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                hasPrice
                    ? AnimatedCurrencyText(
                        value: unitPrice,
                        currencySymbol: '₹',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : const Text(
                        '—',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ],
            ),
          ),
          Container(width: 1, height: 36, color: AppColors.border),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LINE TOTAL',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  hasPrice
                      ? AnimatedCurrencyText(
                          value: lineTotal,
                          currencySymbol: '₹',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : const Text(
                          '—',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add to Cart button ───────────────────────────────────────────────────

class _AddToCartButton extends StatelessWidget {
  const _AddToCartButton({required this.provider});
  final SalesProvider provider;

  @override
  Widget build(BuildContext context) {
    final canAdd = !provider.isSaving && provider.selectedProduct != null;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: canAdd
            ? () async {
                await provider.addToCart();
                if (!context.mounted) return;
                if (provider.error == null) {
                  SuccessToast.show(context, 'Added to cart');
                } else {
                  SuccessToast.show(context, 'Error: ${provider.error!}');
                }
              }
            : null,
        icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
        label: const Text(
          'ADD TO CART',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.background,
          disabledBackgroundColor: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RIGHT PANEL — Cart summary, discount, payment, save order
// ═══════════════════════════════════════════════════════════════════════════

class _RightPanel extends StatelessWidget {
  const _RightPanel({required this.provider});
  final SalesProvider provider;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 620;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CartHeader(
                itemCount: provider.cart.length,
                isEditing: provider.isEditingOrder,
              ),
              const Divider(color: AppColors.border, height: 1),
              Expanded(
                child: provider.cart.isEmpty
                    ? const _EmptyCartState()
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
              const Divider(color: AppColors.border, height: 1),
              _CartControls(provider: provider, compact: isCompact),
            ],
          ),
        );
      },
    );
  }
}

// ── Cart header ──────────────────────────────────────────────────────────

class _CartHeader extends StatelessWidget {
  const _CartHeader({required this.itemCount, required this.isEditing});
  final int itemCount;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            color: AppColors.textMuted,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            isEditing ? 'EDIT ORDER' : 'ORDER',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const Spacer(),
          if (itemCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryMuted,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$itemCount item${itemCount == 1 ? '' : 's'}',
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

// ── Empty cart state ─────────────────────────────────────────────────────

class _EmptyCartState extends StatelessWidget {
  const _EmptyCartState();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 120;

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: isCompact ? 28 : 40,
                color: AppColors.textMuted.withValues(alpha: 0.5),
              ),
              SizedBox(height: isCompact ? 6 : 10),
              const Text(
                'No items yet',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (!isCompact) ...[
                const SizedBox(height: 4),
                const Text(
                  'Select a product and tap Add to Cart',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ],
          ),
        );
      },
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
          // Product dot
          Padding(
            padding: const EdgeInsets.only(top: 3),
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
          // Line total + remove
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

// ── Cart bottom controls (discount + payment + totals + save) ────────────

class _CartControls extends StatelessWidget {
  const _CartControls({required this.provider, required this.compact});
  final SalesProvider provider;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hasItems = provider.cart.isNotEmpty;
    final sectionGap = compact ? 4.0 : 14.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, compact ? 4 : 14, 16, compact ? 6 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel('CUSTOMER'),
          SizedBox(height: compact ? 2 : 6),
          _CustomerPicker(provider: provider),
          SizedBox(height: sectionGap),
          // Discount chips
          const _SectionLabel('DISCOUNT'),
          SizedBox(height: compact ? 2 : 8),
          _DiscountChips(provider: provider),
          SizedBox(height: sectionGap),
          // Payment mode
          const _SectionLabel('PAYMENT'),
          SizedBox(height: compact ? 2 : 8),
          _PaymentChips(provider: provider),
          SizedBox(height: sectionGap),
          // Totals
          _TotalsBlock(provider: provider),
          SizedBox(height: compact ? 4 : 16),
          // Save Order
          _SaveOrderButton(provider: provider, hasItems: hasItems),
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

// ── Discount chips ────────────────────────────────────────────────────────

class _CustomerPicker extends StatelessWidget {
  const _CustomerPicker({required this.provider});
  final SalesProvider provider;

  @override
  Widget build(BuildContext context) {
    final customers = context.watch<CustomerProvider>().membershipCustomers;
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: provider.selectedCustomer?.id,
          isExpanded: true,
          dropdownColor: AppColors.surfaceElevated,
          hint: const Text(
            'Walk-in customer',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Walk-in customer'),
            ),
            ...customers.map(
              (customer) => DropdownMenuItem<String?>(
                value: customer.id,
                child: Text(
                  customer.isMembership
                      ? '${customer.name}  • Member'
                      : customer.name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: (id) => provider.selectCustomer(
            id == null
                ? null
                : customers.firstWhere((customer) => customer.id == id),
          ),
        ),
      ),
    );
  }
}

class _DiscountChips extends StatelessWidget {
  const _DiscountChips({required this.provider});
  final SalesProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.hasMembershipDiscount) {
      return const Text(
        'Membership discount applied (5%)',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    return Row(
      children: [5, 7, 10, 12, 15].map((p) {
        final isSelected = provider.orderDiscountPercent == p;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: _SelectableChip(
            label: '$p%',
            isSelected: isSelected,
            onTap: () => provider.setOrderDiscountPercent(isSelected ? 0 : p),
          ),
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

// ── Totals block ──────────────────────────────────────────────────────────

class _TotalsBlock extends StatelessWidget {
  const _TotalsBlock({required this.provider});
  final SalesProvider provider;

  @override
  Widget build(BuildContext context) {
    final hasDiscount = provider.effectiveDiscountPercent > 0;

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
              label: provider.hasMembershipDiscount
                  ? 'Membership discount (5%)'
                  : 'Discount (${provider.effectiveDiscountPercent}%)',
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
    final isEditing = provider.isEditingOrder;
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
                  if (isEditing) {
                    context.read<SaleHistoryProvider>().loadOrders(
                      forceReload: true,
                    );
                    context.read<DashboardProvider>().loadToday(
                      forceReload: true,
                    );
                    context.read<AnalyticsProvider>().load();
                    context.read<NavigationProvider>().selectIndex(3);
                  }
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
                    isEditing ? 'UPDATE ORDER' : 'SAVE ORDER',
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
