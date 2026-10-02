import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../repositories/product_repository.dart';

/// Result returned when the user saves a price update.
/// Unchanged from original — all fields and types are identical.
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

/// Price-update dialog matching the flat-surface visual language of
/// Dashboard and Sales.
///
/// Presentation changes vs. original:
///   • GlassCard → plain Container (AppColors.surface + border + radius 16)
///   • DropdownButtonFormField variant selector → chip-row selector
///   • Cancel / Save button height 52 px, radius 12, matches Sales CTAs
///   • withOpacity() calls replaced with withValues(alpha:) to fix analyzer warning
///
/// Zero logic changes: _onVariantChanged, _save, _validatePrice, and every
/// Navigator.pop call are identical to the original.
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
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
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

  // ── Unchanged helpers ────────────────────────────────────────────────────

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

  double _calculatedCostForVariant(String variant) {
    if (variant == '1L') {
      return _currentPriceForVariant(variant).costPrice;
    }

    final baseCost = _currentPriceForVariant('1L').costPrice;
    final normalized = variant.trim().toLowerCase();
    final multiplier = normalized.endsWith('ml')
        ? (double.tryParse(normalized.substring(0, normalized.length - 2)) ??
                  0) /
              1000
        : normalized.endsWith('l')
        ? double.tryParse(normalized.substring(0, normalized.length - 1)) ?? 0
        : 0;
    return baseCost * multiplier;
  }

  String _costTextForVariant(String variant) {
    final currentPrice = _currentPriceForVariant(variant);
    if (variant != '1L') {
      final calculatedCost = _calculatedCostForVariant(variant);
      return calculatedCost == 0 ? '' : calculatedCost.toStringAsFixed(2);
    }
    return currentPrice.isPlaceholder
        ? ''
        : currentPrice.costPrice.toStringAsFixed(2);
  }

  @override
  void initState() {
    super.initState();
    _selectedVariant = widget.quantityVariants.first;
    final currentPrice = _currentPriceForVariant(_selectedVariant);

    _costController = TextEditingController(
      text: _costTextForVariant(_selectedVariant),
    );
    _sellingController = TextEditingController(
      text: currentPrice.isPlaceholder
          ? ''
          : currentPrice.sellingPrice.toStringAsFixed(2),
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

  // Identical to original
  void _onVariantChanged(String variant) {
    setState(() {
      _selectedVariant = variant;
      final currentPrice = widget.currentPrices.firstWhere(
        (item) => item.quantityVariant == _selectedVariant,
        orElse: () => (
          quantityVariant: _selectedVariant,
          costPrice: 0.0,
          sellingPrice: 0.0,
          effectiveFrom: DateTime.utc(1970, 1, 1),
          isPlaceholder: true,
        ),
      );

      _costController.text = _costTextForVariant(_selectedVariant);
      _sellingController.text = currentPrice.isPlaceholder
          ? ''
          : currentPrice.sellingPrice.toStringAsFixed(2);
    });
  }

  // Identical to original
  void _save() {
    if (!_formKey.currentState!.validate()) return;

    // Non-base costs are read-only and derived by the repository. A product
    // with no configured 1L cost legitimately displays an empty field.
    final costPrice = double.tryParse(_costController.text.trim()) ?? 0.0;
    final sellingPrice = double.parse(_sellingController.text.trim());
    final note = _noteController.text.trim().isEmpty
        ? null
        : _noteController.text.trim();

    Navigator.of(context).pop(
      UpdatePriceDialogResult(
        quantityVariant: _selectedVariant,
        costPrice: costPrice,
        sellingPrice: sellingPrice,
        note: note,
      ),
    );
  }

  // Identical to original
  String? _validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter a price';
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Enter a valid number';
    if (parsed <= 0) return 'Price must be greater than zero';
    return null;
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isBase = _selectedVariant == '1L';

    return Container(
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.spacingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ───────────────────────────────────────────────────
            _DialogHeader(
              productName: widget.productName,
              selectedVariant: _selectedVariant,
            ),
            const SizedBox(height: AppDimens.spacingLarge),
            // ── Variant chip selector ────────────────────────────────────
            const _FieldLabel('SIZE / VARIANT'),
            const SizedBox(height: 8),
            _VariantChipRow(
              variants: widget.quantityVariants,
              selectedVariant: _selectedVariant,
              onChanged: _onVariantChanged,
            ),
            const SizedBox(height: AppDimens.spacingLarge),
            // ── Price fields ─────────────────────────────────────────────
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PriceField(
                    controller: _costController,
                    label: isBase
                        ? '1L Cost Price (Base)'
                        : 'Cost Price (calculated from 1L)',
                    readOnly: !isBase,
                    validator: isBase ? _validatePrice : (_) => null,
                  ),
                  const SizedBox(height: AppDimens.spacingMedium),
                  _PriceField(
                    controller: _sellingController,
                    label: 'Selling Price',
                    readOnly: false,
                    validator: _validatePrice,
                  ),
                  const SizedBox(height: AppDimens.spacingMedium),
                  _NoteField(controller: _noteController),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.spacingLarge),
            // ── Actions ──────────────────────────────────────────────────
            _DialogActions(
              onCancel: () => Navigator.of(context).pop(),
              onSave: _save,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Sub-widgets — presentation only
// ═══════════════════════════════════════════════════════════════════════════

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({
    required this.productName,
    required this.selectedVariant,
  });

  final String productName;
  final String selectedVariant;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                Icons.edit_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Update Price',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '$productName · $selectedVariant',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }
}

// ── Variant chip row ──────────────────────────────────────────────────────

class _VariantChipRow extends StatelessWidget {
  const _VariantChipRow({
    required this.variants,
    required this.selectedVariant,
    required this.onChanged,
  });

  final List<String> variants;
  final String selectedVariant;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: variants.map((v) {
        final isSelected = selectedVariant == v;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _VariantChip(
            label: v,
            isSelected: isSelected,
            onTap: () => onChanged(v),
          ),
        );
      }).toList(),
    );
  }
}

class _VariantChip extends StatelessWidget {
  const _VariantChip({
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

// ── Price text field ──────────────────────────────────────────────────────

class _PriceField extends StatelessWidget {
  const _PriceField({
    required this.controller,
    required this.label,
    required this.readOnly,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final bool readOnly;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      validator: validator,
      style: TextStyle(
        color: readOnly ? AppColors.textMuted : AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: readOnly ? AppColors.background : AppColors.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: readOnly
                ? AppColors.border.withValues(alpha: 0.5)
                : AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 12, right: 4),
          child: Text(
            '₹',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
    );
  }
}

// ── Note field ────────────────────────────────────────────────────────────

class _NoteField extends StatelessWidget {
  const _NoteField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 2,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        labelText: 'Note (optional)',
        labelStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: AppColors.surfaceElevated,
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

// ── Dialog action buttons ─────────────────────────────────────────────────

class _DialogActions extends StatelessWidget {
  const _DialogActions({required this.onCancel, required this.onSave});

  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppDimens.spacingSmall),
        Expanded(
          child: SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: onSave,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save Price',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
