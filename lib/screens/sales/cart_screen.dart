import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/cards/glass_card.dart';
import '../../providers/sales_provider.dart';
import '../../models/cart_item.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.spacingLarge),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: GlassCard(
                padding: const EdgeInsets.all(AppDimens.spacingLarge),
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Cart', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: AppDimens.spacingLarge),
                    Expanded(
                      child: provider.cart.isEmpty
                          ? Center(child: Text('Your cart is empty', style: AppTextStyles.body))
                          : ListView.separated(
                              itemCount: provider.cart.length,
                              separatorBuilder: (_, __) => const SizedBox(height: AppDimens.spacingSmall),
                              itemBuilder: (context, index) {
                                final CartItem item = provider.cart[index];
                                return _CartItemRow(item: item);
                              },
                            ),
                    ),
                    const SizedBox(height: AppDimens.spacingLarge),
                    // Discount chips
                    Wrap(
                      spacing: AppDimens.spacingSmall,
                      children: [5, 7, 10, 12, 15].map((p) {
                        final selected = provider.orderDiscountPercent == p;
                        return ChoiceChip(
                          label: Text('$p%'),
                          selected: selected,
                          onSelected: (_) => provider.setOrderDiscountPercent(selected ? 0 : p),
                          backgroundColor: AppColors.surfaceElevated,
                          selectedColor: AppColors.primary,
                          labelStyle: selected ? AppTextStyles.body.copyWith(color: AppColors.textPrimary) : AppTextStyles.body,
                          side: BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppDimens.spacingLarge),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Subtotal', style: AppTextStyles.label),
                        Text('₹${provider.subtotal.toStringAsFixed(2)}', style: AppTextStyles.metric),
                      ],
                    ),
                    const SizedBox(height: AppDimens.spacingSmall),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Discount (${provider.orderDiscountPercent}%)', style: AppTextStyles.label),
                        Text('-₹${provider.discountAmount.toStringAsFixed(2)}', style: AppTextStyles.metric),
                      ],
                    ),
                    const SizedBox(height: AppDimens.spacingSmall),
                    Divider(color: AppColors.border),
                    const SizedBox(height: AppDimens.spacingSmall),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Final Total', style: AppTextStyles.label),
                        Text('₹${provider.finalTotal.toStringAsFixed(2)}', style: AppTextStyles.metric),
                      ],
                    ),
                    const SizedBox(height: AppDimens.spacingSmall),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Payment Mode', style: AppTextStyles.label),
                        Text(provider.selectedPaymentMode.label, style: AppTextStyles.body),
                      ],
                    ),
                    const SizedBox(height: AppDimens.spacingLarge),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: provider.isSaving
                                ? null
                                : () {
                                    Navigator.of(context).pop();
                                  },
                            child: const Text('+ ADD PRODUCT'),
                          ),
                        ),
                        const SizedBox(width: AppDimens.spacingSmall),
                        Expanded(
                          child: FilledButton(
                            onPressed: provider.isSaving
                                ? null
                                : () async {
                                    await provider.saveOrder();
                                    if (provider.error == null) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order saved')));
                                        Navigator.of(context).pop();
                                      }
                                    } else {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${provider.error!}')));
                                      }
                                    }
                                  },
                            child: provider.isSaving ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('SAVE ORDER'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CartItemRow extends StatelessWidget {
  const _CartItemRow({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<SalesProvider>();

    return Container(
      padding: const EdgeInsets.all(AppDimens.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: AppTextStyles.body),
                const SizedBox(height: 6),
                Text('${item.variant} × ${item.quantity}', style: AppTextStyles.label),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${item.lineTotal.toStringAsFixed(0)}', style: AppTextStyles.body),
              TextButton(
                onPressed: () => provider.removeCartItem(item),
                child: const Text('Remove'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
