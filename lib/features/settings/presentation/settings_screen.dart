import 'package:flutter/material.dart';

import '../../business/presentation/business_profile_screen.dart';
import '../../business/presentation/receipt_settings_screen.dart';
import '../../business/presentation/tax_settings_screen.dart';
import '../../categories/presentation/category_order_screen.dart';
import '../../payments/presentation/payment_methods_screen.dart';
import '../../printer/presentation/printer_settings_screen.dart';
import '../data/combo_settings_repository.dart';
import '../data/complement_settings_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _complementSettings = ComplementSettingsRepository();
  final _comboSettings = ComboSettingsRepository();
  bool _complementsEnabled = false;
  bool _combosEnabled = false;
  bool _isSavingComplements = false;
  bool _isSavingCombos = false;

  @override
  void initState() {
    super.initState();
    _loadComplementSetting();
    _loadComboSetting();
  }

  Future<void> _loadComboSetting() async {
    try {
      final enabled = await _comboSettings.isEnabled();
      if (mounted) setState(() => _combosEnabled = enabled);
    } catch (_) {
      // The default remains disabled until local settings are available.
    }
  }

  Future<void> _loadComplementSetting() async {
    try {
      final enabled = await _complementSettings.isEnabled();
      if (mounted) setState(() => _complementsEnabled = enabled);
    } catch (_) {
      // The default remains disabled until local settings are available.
    }
  }

  Future<void> _setCombosEnabled(bool enabled) async {
    setState(() {
      _combosEnabled = enabled;
      _isSavingCombos = true;
    });
    try {
      await _comboSettings.setEnabled(enabled);
    } catch (_) {
      if (mounted) {
        setState(() => _combosEnabled = !enabled);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Combo setting could not be saved.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingCombos = false);
    }
  }

  Future<void> _setComplementsEnabled(bool enabled) async {
    setState(() {
      _complementsEnabled = enabled;
      _isSavingComplements = true;
    });
    try {
      await _complementSettings.setEnabled(enabled);
    } catch (_) {
      if (mounted) {
        setState(() => _complementsEnabled = !enabled);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complement setting could not be saved.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingComplements = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 700 ? 12 : 24),
    children: [
      Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 20),
      _section(context, 'BUSINESS', [
        _item(
          context,
          Icons.store_outlined,
          'Business Profile',
          const BusinessProfileScreen(),
        ),
      ]),
      _section(context, 'BILLING', [
        SwitchListTile(
          secondary: const Icon(Icons.fastfood_outlined),
          title: const Text('Combos'),
          subtitle: Text(
            _combosEnabled
                ? 'Available in Billing and Order Details'
                : 'Hidden from Billing and Order Details',
          ),
          value: _combosEnabled,
          onChanged: _isSavingCombos ? null : _setCombosEnabled,
        ),
        SwitchListTile(
          secondary: const Icon(Icons.redeem_outlined),
          title: const Text('Complimentary Items'),
          subtitle: Text(
            _complementsEnabled
                ? 'Enabled in navigation and billing'
                : 'Hidden from navigation and bills',
          ),
          value: _complementsEnabled,
          onChanged: _isSavingComplements ? null : _setComplementsEnabled,
        ),
        _item(
          context,
          Icons.percent,
          'Tax Settings',
          const TaxSettingsScreen(),
        ),
        _item(
          context,
          Icons.payments_outlined,
          'Payment Methods',
          const PaymentMethodsScreen(),
        ),
      ]),
      _section(context, 'RECEIPT & PRINTER', [
        _item(
          context,
          Icons.receipt_outlined,
          'Receipt Settings',
          const ReceiptSettingsScreen(),
        ),
        _item(
          context,
          Icons.print_outlined,
          'Receipt Printer',
          Scaffold(
            appBar: AppBar(title: const Text('Receipt Printer')),
            body: const PrinterSettingsScreen(),
          ),
        ),
      ]),
      _section(context, 'DISPLAY', [
        _item(
          context,
          Icons.format_list_numbered,
          'Change Category Order in Billing',
          const CategoryOrderScreen(),
        ),
      ]),
    ],
  );

  Widget _section(BuildContext context, String label, List<Widget> children) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            Card(child: Column(children: children)),
          ],
        ),
      );

  Widget _item(
    BuildContext context,
    IconData icon,
    String title,
    Widget page,
  ) => ListTile(
    minTileHeight: 68,
    leading: Icon(icon),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right),
    onTap: () =>
        Navigator.push<void>(context, MaterialPageRoute(builder: (_) => page)),
  );
}
