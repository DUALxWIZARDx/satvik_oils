import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/customer_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/products_pricing_provider.dart';
import 'providers/reports_provider.dart';
import 'providers/sale_history_provider.dart';
import 'providers/sales_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/shell/app_shell.dart';

class SatvikOilsApp extends StatelessWidget {
  const SatvikOilsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => SalesProvider()),
        ChangeNotifierProvider(create: (_) => SaleHistoryProvider()),
        ChangeNotifierProvider(create: (_) => ReportsProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ProductsPricingProvider()),
      ],
      child: MaterialApp(
        title: 'Satvik Oils',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AppShell(),
      ),
    );
  }
}
