import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/responsive_breakpoints.dart';
import '../../billing/presentation/billing_screen.dart';
import '../../billing/presentation/current_order_controller.dart';
import '../../complements/presentation/complements_screen.dart';
import '../../orders/presentation/orders_screen.dart';
import '../../products/presentation/products_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../settings/data/complement_settings_repository.dart';
import '../../reports/presentation/reports_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  _HomeSection _selectedSection = _HomeSection.billing;
  late final CurrentOrderController _currentOrder;
  final ValueNotifier<int> _ordersRefresh = ValueNotifier(0);
  final Map<_HomeSection, Widget> _pages = {};
  final _complementSettings = ComplementSettingsRepository();
  late final StreamSubscription<bool> _complementSettingsChanges;
  bool _complementsEnabled = false;

  @override
  void initState() {
    super.initState();
    _currentOrder = CurrentOrderController()..initialize();
    _pages[_HomeSection.billing] = _createPage(_HomeSection.billing);
    _complementSettingsChanges = ComplementSettingsRepository.changes.listen(
      _applyComplementSetting,
    );
    _loadComplementSetting();
  }

  Future<void> _loadComplementSetting() async {
    try {
      final enabled = await _complementSettings.isEnabled();
      if (mounted) _applyComplementSetting(enabled);
    } catch (_) {
      // Keep complements enabled by default if settings are still unavailable
      // during application startup.
    }
  }

  void _applyComplementSetting(bool enabled) {
    if (!mounted) return;
    setState(() {
      _complementsEnabled = enabled;
      if (!enabled && _selectedSection == _HomeSection.complements) {
        _selectedSection = _HomeSection.billing;
      }
    });
  }

  @override
  void dispose() {
    _currentOrder.dispose();
    _ordersRefresh.dispose();
    _complementSettingsChanges.cancel();
    super.dispose();
  }

  List<_HomeDestination> get _destinations => [
    const _HomeDestination(
      section: _HomeSection.billing,
      icon: Icon(Icons.point_of_sale_outlined),
      selectedIcon: Icon(Icons.point_of_sale),
      label: Text('Billing'),
    ),
    const _HomeDestination(
      section: _HomeSection.orders,
      icon: Icon(Icons.receipt_long_outlined),
      selectedIcon: Icon(Icons.receipt_long),
      label: Text('Orders'),
    ),
    const _HomeDestination(
      section: _HomeSection.products,
      icon: Icon(Icons.restaurant_menu_outlined),
      selectedIcon: Icon(Icons.restaurant_menu),
      label: Text('Products'),
    ),
    if (_complementsEnabled)
      const _HomeDestination(
        section: _HomeSection.complements,
        icon: Icon(Icons.redeem_outlined),
        selectedIcon: Icon(Icons.redeem),
        label: Text('Complements'),
      ),
    const _HomeDestination(
      section: _HomeSection.reports,
      icon: Icon(Icons.bar_chart_outlined),
      selectedIcon: Icon(Icons.bar_chart),
      label: Text('Reports'),
    ),
    const _HomeDestination(
      section: _HomeSection.settings,
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: Text('Settings'),
    ),
  ];
  Widget _createPage(_HomeSection section) => switch (section) {
    _HomeSection.billing => BillingScreen(
      currentOrder: _currentOrder,
      onOrderCompleted: () => _selectPage(_HomeSection.orders),
    ),
    _HomeSection.orders => OrdersScreen(refreshListenable: _ordersRefresh),
    _HomeSection.products => const ProductsScreen(),
    _HomeSection.complements => const ComplementsScreen(),
    _HomeSection.reports => const ReportsScreen(),
    _HomeSection.settings => const SettingsScreen(),
  };

  void _selectPage(_HomeSection section) {
    setState(() {
      _pages[section] ??= _createPage(section);
      _selectedSection = section;
    });
    if (section == _HomeSection.orders) _ordersRefresh.value++;
  }

  int get _selectedIndex => _destinations.indexWhere(
    (destination) => destination.section == _selectedSection,
  );

  Widget get _selectedPage => Stack(
    children: [
      for (final entry in _pages.entries)
        Positioned.fill(
          child: Offstage(
            offstage: entry.key != _selectedSection,
            child: TickerMode(
              enabled: entry.key == _selectedSection,
              child: entry.value,
            ),
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
                color: KanakkiTheme.brand,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
          drawer: NavigationDrawer(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              _selectPage(_destinations[index].section);
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
                onDestinationSelected: (index) =>
                    _selectPage(_destinations[index].section),
                labelType: extended
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.all,
                groupAlignment: -0.45,
                leading: Padding(
                  padding: EdgeInsets.fromLTRB(12, 22, extended ? 70 : 12, 26),
                  child: Text(
                    AppConstants.appName,
                    style: TextStyle(
                      color: KanakkiTheme.brand,
                      fontSize: extended ? 25 : 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: extended ? 2 : 0.5,
                    ),
                  ),
                ),
                destinations: [
                  for (final destination in _destinations)
                    NavigationRailDestination(
                      icon: destination.icon,
                      selectedIcon: destination.selectedIcon,
                      label: destination.label,
                    ),
                ],
              ),
              Expanded(child: _selectedPage),
            ],
          ),
        ),
      );
    },
  );
}

enum _HomeSection { billing, orders, products, complements, reports, settings }

class _HomeDestination {
  const _HomeDestination({
    required this.section,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final _HomeSection section;
  final Widget icon;
  final Widget selectedIcon;
  final Widget label;
}
