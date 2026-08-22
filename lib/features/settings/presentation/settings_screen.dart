import 'package:flutter/material.dart';

import '../../business/presentation/business_profile_screen.dart';
import '../../business/presentation/receipt_settings_screen.dart';
import '../../business/presentation/tax_settings_screen.dart';
import '../../categories/presentation/category_order_screen.dart';
import '../../payments/presentation/payment_methods_screen.dart';
import '../../printer/presentation/printer_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
