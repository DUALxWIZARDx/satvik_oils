import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/product_catalog.dart';
import '../../providers/sales_provider.dart';
import '../../models/payment_mode.dart';
import '../../widgets/cards/glass_card.dart';
import 'cart_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesProvider>().refreshCurrentPrice();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesProvider>();

    return ColoredBox(
      color: AppColors.background,
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.spacingLarge),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: GlassCard(
              padding: const EdgeInsets.all(AppDimens.spacingLarge),
              borderRadius: BorderRadius.circular(18),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Sales', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: AppDimens.spacingLarge),
                    DropdownButtonFormField<CatalogProduct>(
                      initialValue: provider.selectedProduct,
                      decoration: InputDecoration(
                        labelText: 'Product',
                        labelStyle: AppTextStyles.label,
                        filled: true,
                        fillColor: AppColors.surfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 12,
                        ),
                      ),
                      items: ProductCatalog.products
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.name),
                              ))
                          .toList(),
                      onChanged: (p) {
                        if (p != null) {
                          provider.selectProduct(p);
                          provider.refreshCurrentPrice();
                        }
                      },
                    ),
                    const SizedBox(height: AppDimens.spacingLarge),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: provider.selectedVariant,
                            decoration: InputDecoration(
                              labelText: 'Variant',
                              labelStyle: AppTextStyles.label,
                              filled: true,
                              fillColor: AppColors.surfaceElevated,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 12,
                              ),
                            ),
                            items: provider.selectedProduct?.quantityVariants
                                    .map((v) => DropdownMenuItem(
                                          value: v,
                                          child: Text(v),
                                        ))
                                    .toList() ??
                                ProductCatalog.quantityVariants
                                    .map((v) => DropdownMenuItem(
                                          value: v,
                                          child: Text(v),
                                        ))
                                    .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                provider.selectVariant(v);
                                provider.refreshCurrentPrice();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: AppDimens.spacingLarge),
                        SizedBox(
                          width: 140,
                          child: TextFormField(
                            initialValue: provider.quantity.toString(),
                            decoration: InputDecoration(
                              labelText: 'Quantity',
                              labelStyle: AppTextStyles.label,
                              filled: true,
                              fillColor: AppColors.surfaceElevated,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 12,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Enter quantity';
                              final parsed = int.tryParse(v.trim());
                              if (parsed == null || parsed <= 0) return 'Enter a valid quantity';
                              return null;
                            },
                            onChanged: (v) {
                              final parsed = int.tryParse(v.trim()) ?? 1;
                              provider.setQuantity(parsed);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimens.spacingLarge),
                    DropdownButtonFormField<PaymentMode>(
                      initialValue: provider.selectedPaymentMode,
                      decoration: InputDecoration(
                        labelText: 'Payment Mode',
                        labelStyle: AppTextStyles.label,
                        filled: true,
                        fillColor: AppColors.surfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 12,
                        ),
                      ),
                      items: PaymentMode.values
                          .map((m) => DropdownMenuItem(
                                value: m,
                                child: Text(m.label),
                              ))
                          .toList(),
                      onChanged: (m) {
                        if (m != null) {
                          provider.setPaymentMode(m);
                        }
                      },
                    ),
                    const SizedBox(height: AppDimens.spacingLarge),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: provider.isSaving
                                ? null
                                : () {
                                    provider.selectProduct(ProductCatalog.products.first);
                                    provider.setQuantity(1);
                                    provider.refreshCurrentPrice();
                                  },
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: AppDimens.spacingSmall),
                        Expanded(
                          child: FilledButton(
                            onPressed: provider.isSaving
                                ? null
                                : () async {
                                    if (!_formKey.currentState!.validate()) return;
                                    await provider.addToCart();
                                    if (!mounted) return;
                                    // navigate to cart
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const CartScreen()),
                                    );
                                  },
                            child: const Text('ADD TO CART'),
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
