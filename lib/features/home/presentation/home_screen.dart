import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/responsive_breakpoints.dart';
import '../../billing/presentation/billing_screen.dart';
import '../../billing/presentation/current_order_controller.dart';
import '../../complements/presentation/complements_screen.dart';
import '../../orders/presentation/orders_screen.dart';
import '../../products/presentation/products_screen.dart';
import '../../printer/presentation/printer_settings_screen.dart';
import '../../reports/presentation/reports_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late final CurrentOrderController _currentOrder;
  late final List<Widget?> _pages;

  @override
  void initState() {
    super.initState();
    _currentOrder = CurrentOrderController();
    _pages = List<Widget?>.filled(_destinations.length, null);
    _pages[0] = _createPage(0);
  }

  @override
  void dispose() {
    _currentOrder.dispose();
    super.dispose();
  }

  static const _destinations = [
    NavigationRailDestination(
      icon: Icon(Icons.point_of_sale_outlined),
      selectedIcon: Icon(Icons.point_of_sale),
      label: Text('Billing'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.receipt_long_outlined),
      selectedIcon: Icon(Icons.receipt_long),
      label: Text('Orders'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.restaurant_menu_outlined),
      selectedIcon: Icon(Icons.restaurant_menu),
      label: Text('Products'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.redeem_outlined),
      selectedIcon: Icon(Icons.redeem),
      label: Text('Complements'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.bar_chart_outlined),
      selectedIcon: Icon(Icons.bar_chart),
      label: Text('Reports'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: Text('Settings'),
    ),
  ];
  Widget _createPage(int index) => switch (index) {
    0 => BillingScreen(
      currentOrder: _currentOrder,
      onOrderCompleted: () => _selectPage(1),
    ),
    1 => const OrdersScreen(),
    2 => const ProductsScreen(),
    3 => const ComplementsScreen(),
    4 => const ReportsScreen(),
    _ => const PrinterSettingsScreen(),
  };

  void _selectPage(int index) {
    setState(() {
      _pages[index] ??= _createPage(index);
      _selectedIndex = index;
    });
  }

  Widget get _selectedPage => Stack(
    children: [
      for (var index = 0; index < _pages.length; index++)
        if (_pages[index] case final page?)
          Positioned.fill(
            child: Offstage(
              offstage: index != _selectedIndex,
              child: TickerMode(enabled: index == _selectedIndex, child: page),
            ),
          ),
    ],
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = ResponsiveBreakpoints.isWide(constraints.maxWidth);
      if (!wide) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              AppConstants.appName,
              style: TextStyle(
                color: FrydTheme.brand,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
          drawer: NavigationDrawer(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              _selectPage(index);
              Navigator.pop(context);
            },
            children: [
              const SizedBox(height: 12),
              for (final destination in _destinations)
                NavigationDrawerDestination(
                  icon: destination.icon,
                  selectedIcon: destination.selectedIcon,
                  label: destination.label,
                ),
            ],
          ),
          body: SafeArea(child: _selectedPage),
        );
      }
      final extended = constraints.maxWidth >= 1280;
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              NavigationRail(
                extended: extended,
                minExtendedWidth: 190,
                selectedIndex: _selectedIndex,
                onDestinationSelected: _selectPage,
                labelType: extended
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.all,
                groupAlignment: -0.45,
                leading: Padding(
                  padding: EdgeInsets.fromLTRB(12, 22, extended ? 70 : 12, 26),
                  child: Text(
                    AppConstants.appName,
                    style: TextStyle(
                      color: FrydTheme.brand,
                      fontSize: extended ? 25 : 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: extended ? 2 : 0.5,
                    ),
                  ),
                ),
                destinations: _destinations,
              ),
              Expanded(child: _selectedPage),
            ],
          ),
        ),
      );
    },
  );
}
