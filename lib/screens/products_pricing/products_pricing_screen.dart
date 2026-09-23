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
  bool _requestedPriceLoad = false;

  // Per-product tint colours — unchanged from original
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requestedPriceLoad) return;
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

    if (!mounted || result == null) return;

    await provider.saveProductPrice(
      productId: product.id,
      quantityVariant: result.quantityVariant,
      sellingPrice: result.sellingPrice,
      costPrice: result.costPrice,
      note: result.note,
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductsPricingProvider>();
    final products = ProductCatalog.products;

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
              // ── Screen header ──────────────────────────────────────────
              _ScreenHeader(
                isLoading: provider.isLoading,
                onRefresh: () => provider.loadCurrentPrices(
                  ProductCatalog.products,
                  forceReload: true,
                ),
              ),
              const SizedBox(height: AppDimens.spacingMedium),
              // ── Body ───────────────────────────────────────────────────
              Expanded(child: _buildBody(context, provider, products)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ProductsPricingProvider provider,
    List<CatalogProduct> products,
  ) {
    // Initial load spinner — matches Dashboard's loading state pattern
    if (provider.isLoading && !_requestedPriceLoad) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // Error state — matches Dashboard's _DashboardErrorState pattern
    if (provider.errorMessage != null && provider.errorMessage!.isNotEmpty) {
      return _ErrorState(
        message: provider.errorMessage!,
        onRetry: () => provider.loadCurrentPrices(
          ProductCatalog.products,
          forceReload: true,
        ),
      );
    }

    // Independent columns keep cards in neighboring columns stable while an
    // expanded card changes the height of its own column.
    return LayoutBuilder(
      builder: (context, constraints) {
        const minCardWidth = 220.0;
        const maxColumns = 4;
        const spacing = AppDimens.spacingMedium;

        final columnCount =
            ((constraints.maxWidth + spacing) / (minCardWidth + spacing))
                .floor()
                .clamp(2, maxColumns);

        // Derive exact card width from column count so cards fill the row.
        final cardWidth =
            (constraints.maxWidth - spacing * (columnCount - 1)) / columnCount;

        final columns = List.generate(columnCount, (columnIndex) {
          return <Widget>[
            for (var i = columnIndex; i < products.length; i += columnCount)
              Padding(
                padding: EdgeInsets.only(
                  bottom: i + columnCount < products.length ? spacing : 0,
                ),
                child: SizedBox(
                  width: cardWidth,
                  child: ProductPricingCard(
                    product: products[i],
                    tintColor: _cardTints[i % _cardTints.length],
                    currentPrices: provider.currentPricesFor(products[i].id),
                    isLoadingPrices: provider.isLoading,
                    pricingErrorMessage: provider.errorMessage,
                    onUpdatePrice: () => _openUpdatePriceDialog(
                      products[i],
                      provider.currentPricesFor(products[i].id),
                    ),
                      heroTag: 'products-pricing-${products[i].id}',
                  ),
                ),
              ),
          ];
        });

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (
                var columnIndex = 0;
                columnIndex < columns.length;
                columnIndex++
              )
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: columnIndex < columns.length - 1 ? spacing : 0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: columns[columnIndex],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Screen header — mirrors Dashboard's header row
// ═══════════════════════════════════════════════════════════════════════════

class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader({required this.isLoading, required this.onRefresh});

  final bool isLoading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Products & Pricing', style: AppTextStyles.screenTitle),
            const SizedBox(height: 2),
            const Text(
              'Manage selling and cost prices for all oils',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: isLoading ? null : onRefresh,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            backgroundColor: AppColors.surface,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : const Icon(Icons.refresh_rounded, size: 18),
          label: Text(
            isLoading ? 'Loading…' : 'Refresh',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Error state — mirrors Dashboard's _DashboardErrorState
// ═══════════════════════════════════════════════════════════════════════════

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

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
