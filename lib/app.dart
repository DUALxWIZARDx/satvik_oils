import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/utils/date_time_service.dart';
import 'providers/customer_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/dashboard_provider.dart';
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
        ChangeNotifierProvider(
          create: (_) {
            final service = DateTimeService();
            debugPrint(
              'DateTimeService.currentDateTime = '
              '${service.currentDateTime}',
            );
            return service;
          },
        ),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(
          create: (context) => DashboardProvider(
            dateTimeService: context.read<DateTimeService>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => SaleHistoryProvider()),
        ChangeNotifierProvider(create: (_) => ReportsProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProxyProvider<CustomerProvider, SalesProvider>(
          create: (context) =>
              SalesProvider(dateTimeService: context.read<DateTimeService>()),
          update: (_, customers, sales) {
            sales!.syncMembershipCustomers(customers.membershipCustomers);
            return sales;
          },
        ),
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
