import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_satvik_oils/app.dart';

void main() {
  testWidgets('Satvik Oils shell starts on Sales screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SatvikOilsApp());

    expect(find.text('Satvik Oils'), findsOneWidget);
    expect(find.text('Sales'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pump();

    expect(find.text('Sale History'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
