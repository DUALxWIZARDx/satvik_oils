import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_satvik_oils/widgets/animations/animated_currency_text.dart';

void main() {
  testWidgets('interpolates and formats currency with Indian grouping', (
    WidgetTester tester,
  ) async {
    double value = 0;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return MaterialApp(
            home: AnimatedCurrencyText(value: value, currencySymbol: '₹'),
          );
        },
      ),
    );

    expect(find.text('₹0.00'), findsOneWidget);

    value = 1240.5;
    await tester.pumpWidget(
      MaterialApp(
        home: AnimatedCurrencyText(value: value, currencySymbol: '₹'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final rendered = tester.widget<Text>(find.byType(Text)).data!;
    expect(rendered, isNot('₹0.00'));
    expect(rendered, isNot('₹1,240.50'));
    expect(rendered, contains('₹'));
  });
}
