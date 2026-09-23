import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/product_catalog.dart';
import '../../core/utils/date_time_service.dart';
import '../../repositories/product_repository.dart' show CurrentProductPrice;
import 'expandable_card_modal.dart';

class ProductPricingCard extends StatelessWidget {
  const ProductPricingCard({
    super.key,
    required this.product,
    required this.tintColor,
    required this.currentPrices,
    required this.isLoadingPrices,
    required this.pricingErrorMessage,
    required this.onUpdatePrice,
    required this.heroTag,
  });

  final CatalogProduct product;
  final Color tintColor;
  final List<CurrentProductPrice> currentPrices;
  final bool isLoadingPrices;
  final String? pricingErrorMessage;
  final VoidCallback onUpdatePrice;
  final String heroTag;

  // Taller collapsed face — more presence, easier to tap on a tablet.
  static const double _collapsedHeight = 140.0;

  static final _priceFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );
  @override
  Widget build(BuildContext context) {
    final dateTimeService = context.read<DateTimeService>();
    return ExpandableCardModal(
      heroTag: heroTag,
      tintColor: tintColor,
      collapsedChild: _CollapsedFace(
        product: product,
        tintColor: tintColor,
        currentPrices: currentPrices,
        isLoading: isLoadingPrices,
        priceFormat: _priceFormat,
      ),
      expandedChild: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(product.name, style: AppTextStyles.label),
            const SizedBox(height: 16),
            _ExpandedDetail(
              currentPrices: currentPrices,
              isLoading: isLoadingPrices,
              errorMessage: pricingErrorMessage,
              priceFormat: _priceFormat,
              dateTimeService: dateTimeService,
              tintColor: tintColor,
              onUpdatePrice: onUpdatePrice,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Collapsed face
// ═══════════════════════════════════════════════════════════════════════════

class _CollapsedFace extends StatelessWidget {
  const _CollapsedFace({
    required this.product,
    required this.tintColor,
    required this.currentPrices,
    required this.isLoading,
    required this.priceFormat,
  });

  final CatalogProduct product;
  final Color tintColor;
  final List<CurrentProductPrice> currentPrices;
  final bool isLoading;
  final NumberFormat priceFormat;

  String get _previewPrice {
    if (isLoading || currentPrices.isEmpty) return '';
    final oneLitre = currentPrices
        .where((p) => p.quantityVariant == '1L' && !p.isPlaceholder);
    if (oneLitre.isNotEmpty) {
      return priceFormat.format(oneLitre.first.sellingPrice);
    }
    final first = currentPrices.where((p) => !p.isPlaceholder);
    if (first.isNotEmpty) return priceFormat.format(first.first.sellingPrice);
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final preview = _previewPrice;

    return SizedBox(
      height: ProductPricingCard._collapsedHeight,
      child: Stack(
        children: [
          // ── Tinted top-strip background ──────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 56,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    tintColor.withValues(alpha: 0.18),
                    tintColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // ── Card content ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: icon + chevron
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Oil-drop icon with tinted circle
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: tintColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: tintColor.withValues(alpha: 0.30),
                        ),
                      ),
                      child: Icon(
                        Icons.water_drop_rounded,
                        size: 18,
                        color: tintColor,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textMuted.withValues(alpha: 0.7),
                      size: 22,
                    ),
                  ],
                ),
                const Spacer(),
                // Bottom row: product name + price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Product name
                    Expanded(
                      child: Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    if (preview.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            preview,
                            style: TextStyle(
                              color: tintColor,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'per 1L',
                            style: TextStyle(
                              color: AppColors.textMuted.withValues(alpha: 0.8),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Expanded detail panel
// ═══════════════════════════════════════════════════════════════════════════

class _ExpandedDetail extends StatelessWidget {
  const _ExpandedDetail({
    required this.currentPrices,
    required this.isLoading,
    required this.errorMessage,
    required this.priceFormat,
    required this.dateTimeService,
    required this.tintColor,
    required this.onUpdatePrice,
  });

  final List<CurrentProductPrice> currentPrices;
  final bool isLoading;
  final String? errorMessage;
  final NumberFormat priceFormat;
  final DateTimeService dateTimeService;
  final Color tintColor;
  final VoidCallback onUpdatePrice;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(
          color: tintColor.withValues(alpha: 0.18),
          height: 1,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildContent(),
              const SizedBox(height: 16),
              _UpdatePriceButton(onTap: onUpdatePrice, tintColor: tintColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (isLoading && currentPrices.isEmpty) {
      return const _StatusMessage('Loading pricing…');
    }
    if (errorMessage != null) {
      return _StatusMessage(errorMessage!);
    }
    if (currentPrices.isEmpty) {
      return const _StatusMessage('No pricing data available.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _PriceTableHeader(),
        const SizedBox(height: 4),
        ...List.generate(currentPrices.length, (i) {
          final price = currentPrices[i];
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (i > 0)
                Divider(
                  height: 1,
                  color: AppColors.border.withValues(alpha: 0.5),
                ),
              _PriceVariantRow(
                price: price,
                priceFormat: priceFormat,
                dateTimeService: dateTimeService,
              ),
            ],
          );
        }),
      ],
    );
  }
}

// ── Column header row ─────────────────────────────────────────────────────

class _PriceTableHeader extends StatelessWidget {
  const _PriceTableHeader();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: AppColors.textMuted,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.9,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Expanded(flex: 2, child: Text('SIZE', style: style)),
          const Expanded(
              flex: 3,
              child: Text('SELLING', style: style, textAlign: TextAlign.right)),
          const SizedBox(width: 10),
          const Expanded(
              flex: 3,
              child: Text('COST', style: style, textAlign: TextAlign.right)),
          const SizedBox(width: 10),
          const Expanded(
              flex: 4,
              child:
                  Text('UPDATED', style: style, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

// ── Per-variant price row ─────────────────────────────────────────────────

class _PriceVariantRow extends StatelessWidget {
  const _PriceVariantRow({
    required this.price,
    required this.priceFormat,
    required this.dateTimeService,
  });

  final CurrentProductPrice price;
  final NumberFormat priceFormat;
  final DateTimeService dateTimeService;

  @override
  Widget build(BuildContext context) {
    final selling = price.isPlaceholder
        ? '—'
        : priceFormat.format(price.sellingPrice);
    final cost =
        price.isPlaceholder ? '—' : priceFormat.format(price.costPrice);
    final updated = price.isPlaceholder
        ? '—'
      : dateTimeService.formatDate(price.effectiveFrom);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Variant badge
          Expanded(
            flex: 2,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                price.quantityVariant,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          // Selling price
          Expanded(
            flex: 3,
            child: Text(
              selling,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Cost price
          Expanded(
            flex: 3,
            child: Text(
              cost,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Updated date
          Expanded(
            flex: 4,
            child: Text(
              updated,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Update Price button ───────────────────────────────────────────────────

class _UpdatePriceButton extends StatelessWidget {
  const _UpdatePriceButton({
    required this.onTap,
    required this.tintColor,
  });

  final VoidCallback onTap;
  final Color tintColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.edit_rounded, size: 15),
        label: const Text(
          'UPDATE PRICE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

// ── Status / empty message ────────────────────────────────────────────────

class _StatusMessage extends StatelessWidget {
  const _StatusMessage(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
