enum PaymentMode {
  cash('cash', 'Cash'),
  upi('upi', 'UPI'),
  card('card', 'Card');

  const PaymentMode(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static PaymentMode fromDbValue(String value) {
    return PaymentMode.values.firstWhere(
      (mode) => mode.dbValue == value,
      orElse: () => throw ArgumentError.value(value, 'value'),
    );
  }
}
