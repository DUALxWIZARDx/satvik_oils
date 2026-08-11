import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_text_styles.dart';
import '../../repositories/product_repository.dart';
import '../cards/glass_card.dart';

class UpdatePriceDialogResult {
  UpdatePriceDialogResult({
    required this.quantityVariant,
    required this.sellingPrice,
    required this.costPrice,
    this.note,
  });

  final String quantityVariant;
  final double sellingPrice;
  final double costPrice;
  final String? note;
}

class UpdatePriceDialog extends StatefulWidget {
  const UpdatePriceDialog({
    super.key,
    required this.productName,
    required this.quantityVariants,
    required this.currentPrices,
  });

  final String productName;
  final List<String> quantityVariants;
  final List<CurrentProductPrice> currentPrices;

  static Future<UpdatePriceDialogResult?> show(
    BuildContext context, {
    required String productName,
    required List<String> quantityVariants,
    required List<CurrentProductPrice> currentPrices,
  }) {
    return showDialog<UpdatePriceDialogResult>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: UpdatePriceDialog(
            productName: productName,
            quantityVariants: quantityVariants,
            currentPrices: currentPrices,
          ),
        ),
      ),
    );
  }

  @override
  State<UpdatePriceDialog> createState() => _UpdatePriceDialogState();
}

class _UpdatePriceDialogState extends State<UpdatePriceDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedVariant;
  late TextEditingController _costController;
  late TextEditingController _sellingController;
  late TextEditingController _noteController;

  CurrentProductPrice _currentPriceForVariant(String variant) {
    return widget.currentPrices.firstWhere(
      (item) => item.quantityVariant == variant,
      orElse: () => (
        quantityVariant: variant,
        costPrice: 0.0,
        sellingPrice: 0.0,
        effectiveFrom: DateTime.utc(1970, 1, 1),
        isPlaceholder: true,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedVariant = widget.quantityVariants.first;
    final currentPrice = _currentPriceForVariant(_selectedVariant);

    _costController = TextEditingController(
      text: currentPrice.isPlaceholder ? '' : currentPrice.costPrice.toStringAsFixed(2),
    );
    _sellingController = TextEditingController(
      text: currentPrice.isPlaceholder ? '' : currentPrice.sellingPrice.toStringAsFixed(2),
    );
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _costController.dispose();
    _sellingController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onVariantChanged(String? value) {
    if (value == null) {
      return;
    }

    setState(() {
      _selectedVariant = value;
      final currentPrice = widget.currentPrices.firstWhere(
        (item) => item.quantityVariant == _selectedVariant,
        orElse: () => (quantityVariant: _selectedVariant,
          costPrice: 0.0,
          sellingPrice: 0.0,
          effectiveFrom: DateTime.utc(1970, 1, 1),
          isPlaceholder: true),
      );

      _costController.text = currentPrice.isPlaceholder
          ? ''
          : currentPrice.costPrice.toStringAsFixed(2);
      _sellingController.text = currentPrice.isPlaceholder
          ? ''
          : currentPrice.sellingPrice.toStringAsFixed(2);
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final costPrice = double.parse(_costController.text.trim());
    final sellingPrice = double.parse(_sellingController.text.trim());
    final note = _noteController.text.trim().isEmpty
        ? null
        : _noteController.text.trim();

    Navigator.of(context).pop(UpdatePriceDialogResult(
      quantityVariant: _selectedVariant,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      note: note,
    ));
  }

  String? _validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a price';
    }

    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid number';
    }

    if (parsed <= 0) {
      return 'Price must be greater than zero';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: BorderRadius.circular(22),
      padding: const EdgeInsets.all(AppDimens.spacingLarge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Update Price', style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppDimens.spacingSmall),
          Text(
            '${widget.productName} • $_selectedVariant',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppDimens.spacingLarge),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedVariant,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                  ),
                  items: widget.quantityVariants
                      .map((variant) => DropdownMenuItem(
                            value: variant,
                            child: Text(variant),
                          ))
                      .toList(),
                  onChanged: _onVariantChanged,
                ),
                const SizedBox(height: AppDimens.spacingLarge),
                TextFormField(
                  controller: _costController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  style: AppTextStyles.body,
                  decoration: InputDecoration(
                    labelText: _selectedVariant == '1L' ? '1L Cost Price (Base)' : 'Cost Price (calculated from 1L)',
                    labelStyle: AppTextStyles.label,
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                  ),
                  readOnly: _selectedVariant != '1L',
                  validator: _selectedVariant == '1L' ? _validatePrice : (_) => null,
                ),
                const SizedBox(height: AppDimens.spacingLarge),
                TextFormField(
                  controller: _sellingController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  style: AppTextStyles.body,
                  decoration: InputDecoration(
                    labelText: 'Selling Price',
                    labelStyle: AppTextStyles.label,
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                  ),
                  validator: _validatePrice,
                ),
                const SizedBox(height: AppDimens.spacingLarge),
                TextFormField(
                  controller: _noteController,
                  style: AppTextStyles.body,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Note (optional)',
                    labelStyle: AppTextStyles.label,
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.spacingLarge),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(color: Colors.white.withOpacity(0.06)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppDimens.spacingSmall),
              Expanded(
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
