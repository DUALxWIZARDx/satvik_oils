enum DiscountType {
  none('none', 'None', 0),
  fivePercent('percent_5', '5%', 5),
  tenPercent('percent_10', '10%', 10),
  custom('custom', 'Custom', null);

  const DiscountType(this.dbValue, this.label, this.percent);

  final String dbValue;
  final String label;
  final int? percent;

  static DiscountType fromDbValue(String value) {
    return DiscountType.values.firstWhere(
      (type) => type.dbValue == value,
      orElse: () => throw ArgumentError.value(value, 'value'),
    );
  }
}
