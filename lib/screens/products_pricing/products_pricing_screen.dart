import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/product_catalog.dart';
import '../../providers/products_pricing_provider.dart';
import '../../repositories/product_repository.dart' show CurrentProductPrice;
import '../../widgets/cards/product_pricing_card.dart';
import '../../widgets/feedback/update_price_dialog.dart';

class ProductsPricingScreen extends StatefulWidget {
  const ProductsPricingScreen({super.key});

  @override
  State<ProductsPricingScreen> createState() => _ProductsPricingScreenState();
}

class _ProductsPricingScreenState extends State<ProductsPricingScreen> {
  int? _expandedProductIndex;
  bool _requestedPriceLoad = false;

  static const _cardTints = [
    Color(0xFFCDA36A),
    Color(0xFF8FBFA8),
    Color(0xFFB99B73),
    Color(0xFF8D8A78),
    Color(0xFFD6C15E),
    Color(0xFFE2B84E),
    Color(0xFFAEB295),
    Color(0xFFC9957D),
  ];

  void _toggleProduct(int index) {
    setState(() {
      _expandedProductIndex = _expandedProductIndex == index ? null : index;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_requestedPriceLoad) {
      return;
    }

    _requestedPriceLoad = true;
    context.read<ProductsPricingProvider>().loadCurrentPrices(
      ProductCatalog.products,
    );
  }

  Future<void> _openUpdatePriceDialog(
    CatalogProduct product,
    List<CurrentProductPrice> currentPrices,
  ) async {
    final provider = context.read<ProductsPricingProvider>();
    final result = await UpdatePriceDialog.show(
      context,
      productName: product.name,
      quantityVariants: product.quantityVariants,
      currentPrices: currentPrices,
    );

    if (!mounted || result == null) {
      return;
    }

    await provider.saveProductPrice(
      productId: product.id,
      quantityVariant: result.quantityVariant,
      sellingPrice: result.sellingPrice,
      costPrice: result.costPrice,
      note: result.note,
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = ProductCatalog.products;
    final pricingProvider = context.watch<ProductsPricingProvider>();

    return ColoredBox(
      color: AppColors.background,
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Products & Pricing', style: AppTextStyles.screenTitle),
            const SizedBox(height: AppDimens.spacingLarge),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const minimumCardWidth = 220.0;
                  const maximumColumns = 4;
                  const spacing = AppDimens.spacingLarge;

                  final columnCount = (constraints.maxWidth / minimumCardWidth)
                      .floor()
                      .clamp(2, maximumColumns);
                  final cardWidth =
                      (constraints.maxWidth - (spacing * (columnCount - 1))) /
                      columnCount;

                  return SingleChildScrollView(
                    child: Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        for (var index = 0; index < products.length; index++)
                          SizedBox(
                            width: cardWidth,
                            child: ProductPricingCard(
                              product: products[index],
                              tintColor: _cardTints[index % _cardTints.length],
                              expanded: _expandedProductIndex == index,
                              currentPrices: pricingProvider.currentPricesFor(
                                products[index].id,
                              ),
                              isLoadingPrices: pricingProvider.isLoading,
                              pricingErrorMessage: pricingProvider.errorMessage,
                              onTap: () => _toggleProduct(index),
                              onUpdatePrice: () => _openUpdatePriceDialog(
                                products[index],
                                pricingProvider.currentPricesFor(
                                  products[index].id,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
