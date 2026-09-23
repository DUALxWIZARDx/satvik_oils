import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/navigation_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../analytics/analytics_screen.dart';
import '../products_pricing/products_pricing_screen.dart';
import '../sale_history/sale_history_screen.dart';
import '../sales/sales_screen.dart';
import '../settings/settings_screen.dart';
import 'floating_bottom_nav.dart';
import 'smooth_page_switcher.dart';
import 'top_bar.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static const _screens = <Widget>[
    SalesScreen(),
    DashboardScreen(),
    ProductsPricingScreen(),
    SaleHistoryScreen(),
    AnalyticsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = context.select<NavigationProvider, int>(
      (provider) => provider.currentIndex,
    );

    return Scaffold(
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Column(
            children: [
              const TopBar(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    bottom: FloatingBottomNav.reservedHeight,
                  ),
                  child: SmoothPageSwitcher(
                    animatedIndices: const {0, 1, 2, 4},
                    currentIndex: currentIndex,
                    children: _screens,
                  ),
                ),
              ),
            ],
          ),
          const Positioned(bottom: 0, child: FloatingBottomNav()),
        ],
      ),
    );
  }
}
