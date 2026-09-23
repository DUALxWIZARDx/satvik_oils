import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnimatedCurrencyText extends StatelessWidget {
  const AnimatedCurrencyText({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 600),
    this.currencySymbol,
    this.prefix = '',
    this.decimalDigits = 2,
  });

  final double value;
  final TextStyle? style;
  final Duration duration;
  final String? currencySymbol;
  final String prefix;
  final int decimalDigits;

  String _format(double amount) {
    final formatted = NumberFormat.currency(
      locale: 'en_IN',
      symbol: currencySymbol ?? '',
      decimalDigits: decimalDigits,
    ).format(amount);
    return '$prefix$formatted';
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return Text(_format(animatedValue), style: style);
      },
    );
  }
}
