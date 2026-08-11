import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/product_catalog.dart';
import '../../repositories/product_repository.dart' show CurrentProductPrice;
import 'glass_card.dart';

class ProductPricingCard extends StatelessWidget {
  const ProductPricingCard({
    super.key,
    required this.product,
    required this.tintColor,
    required this.expanded,
    required this.currentPrices,
    required this.isLoadingPrices,
    required this.pricingErrorMessage,
    required this.onTap,
    required this.onUpdatePrice,
  });

  final CatalogProduct product;
  final Color tintColor;
  final bool expanded;
  final List<CurrentProductPrice> currentPrices;
  final bool isLoadingPrices;
  final String? pricingErrorMessage;
  final VoidCallback onTap;
  final VoidCallback onUpdatePrice;
  static const _animationDuration = Duration(milliseconds: 280);
  static const _animationCurve = Curves.easeInOutCubic;
  static final _priceFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );
  static final _dateFormat = DateFormat('d MMM yyyy');

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final collapsedHeight = (constraints.maxWidth / 1.18).clamp(
          168.0,
          220.0,
        );
        final expandedHeight = collapsedHeight + _detailHeight;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            splashColor: tintColor.withValues(alpha: 0.10),
            highlightColor: tintColor.withValues(alpha: 0.06),
            onTap: onTap,
            child: AnimatedContainer(
              duration: _animationDuration,
              curve: _animationCurve,
              height: expanded ? expandedHeight : collapsedHeight,
              child: GlassCard(
                tintColor: tintColor,
                borderRadius: BorderRadius.circular(22),
                child: Column(
                  children: [
                    SizedBox(
                      height: collapsedHeight,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            product.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: AnimatedOpacity(
                        duration: _animationDuration,
                        curve: _animationCurve,
                        opacity: expanded ? 1 : 0,
                        child: _ExpandedPriceDetails(
                          currentPrices: currentPrices,
                          isLoading: isLoadingPrices,
                          errorMessage: pricingErrorMessage,
                          formatPrice: _priceFormat.format,
                          formatDate: _dateFormat.format,
                          onUpdatePrice: onUpdatePrice,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double get _detailHeight {
    if (isLoadingPrices ||
        pricingErrorMessage != null ||
        currentPrices.isEmpty) {
      return 132;
    }

    return 112 + (currentPrices.length * 58);
  }
}

class _ExpandedPriceDetails extends StatelessWidget {
  const _ExpandedPriceDetails({
    required this.currentPrices,
    required this.isLoading,
    required this.errorMessage,
    required this.formatPrice,
    required this.formatDate,
    required this.onUpdatePrice,
  });

  final List<CurrentProductPrice> currentPrices;
  final bool isLoading;
  final String? errorMessage;
  final String Function(num value) formatPrice;
  final String Function(DateTime value) formatDate;
  final VoidCallback onUpdatePrice;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
      child: Column(
        children: [
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: AppDimens.spacingMedium),
          Expanded(child: _buildPricingContent()),
          const SizedBox(height: AppDimens.spacingMedium),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onUpdatePrice,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Update Price'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingContent() {
    if (isLoading && currentPrices.isEmpty) {
      return const Center(child: _StatusText('Loading pricing...'));
    }

    if (errorMessage != null) {
      return Center(child: _StatusText(errorMessage!));
    }

    if (currentPrices.isEmpty) {
      return const Center(child: _StatusText('No pricing data available.'));
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: currentPrices.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: AppDimens.spacingSmall),
      itemBuilder: (context, index) {
        final price = currentPrices[index];
        final sellingPrice = price.isPlaceholder
            ? 'Not set'
            : formatPrice(price.sellingPrice);
        final costPrice = price.isPlaceholder
            ? 'Not set'
            : formatPrice(price.costPrice);
        final lastChanged = price.isPlaceholder
            ? 'Not set'
            : formatDate(price.effectiveFrom.toLocal());

        return _CurrentPriceRow(
          quantityVariant: price.quantityVariant,
          sellingPrice: sellingPrice,
          costPrice: costPrice,
          lastChanged: lastChanged,
        );
      },
    );
  }
}

class _CurrentPriceRow extends StatelessWidget {
  const _CurrentPriceRow({
    required this.quantityVariant,
    required this.sellingPrice,
    required this.costPrice,
    required this.lastChanged,
  });

  final String quantityVariant;
  final String sellingPrice;
  final String costPrice;
  final String lastChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              quantityVariant,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              'Last Changed $lastChanged',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: _PriceValue(label: 'Selling Price', value: sellingPrice),
            ),
            const SizedBox(width: AppDimens.spacingSmall),
            Expanded(
              child: _PriceValue(label: 'Cost Price', value: costPrice),
            ),
          ],
        ),
      ],
    );
  }
}

class _PriceValue extends StatelessWidget {
  const _PriceValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatusText extends StatelessWidget {
  const _StatusText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
