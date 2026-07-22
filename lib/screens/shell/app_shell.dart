import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/navigation_provider.dart';
import '../reports/reports_screen.dart';
import '../sale_history/sale_history_screen.dart';
import '../sales/sales_screen.dart';
import '../settings/settings_screen.dart';
import 'side_menu.dart';
import 'top_bar.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static const _screens = <Widget>[
    SalesScreen(),
    SaleHistoryScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = context.select<NavigationProvider, int>(
      (provider) => provider.currentIndex,
    );

    return Scaffold(
      drawer: const SideMenu(),
      body: Column(
        children: [
          const TopBar(),
          Expanded(
            child: IndexedStack(index: currentIndex, children: _screens),
          ),
        ],
      ),
    );
  }
}
