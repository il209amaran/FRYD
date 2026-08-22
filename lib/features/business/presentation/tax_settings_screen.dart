import 'package:flutter/material.dart';

import '../../../models/business_settings.dart';
import '../data/business_settings_repository.dart';

class TaxSettingsScreen extends StatefulWidget {
  const TaxSettingsScreen({super.key});

  @override
  State<TaxSettingsScreen> createState() => _TaxSettingsScreenState();
}

class _TaxSettingsScreenState extends State<TaxSettingsScreen> {
  final _repository = BusinessSettingsRepository();
  final _name = TextEditingController();
  final _rate = TextEditingController();
  final _number = TextEditingController();
  BusinessSettings? _settings;
  bool _enabled = false;
  bool _inclusive = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await _repository.get();
    if (!mounted) return;
    _settings = value;
    _name.text = value.taxName;
    _rate.text = value.taxRate.toStringAsFixed(
      value.taxRate == value.taxRate.roundToDouble() ? 0 : 2,
    );
    _number.text = value.taxRegistrationNumber;
    setState(() {
      _enabled = value.taxEnabled;
      _inclusive = value.taxInclusive;
    });
  }

  Future<void> _save() async {
    final current = _settings;
    final rate = double.tryParse(_rate.text.trim());
    if (current == null || rate == null || rate < 0 || rate > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid tax percentage.')),
      );
      return;
    }
    await _repository.save(
      current.copyWith(
        taxEnabled: _enabled,
        taxName: _name.text.trim().isEmpty ? 'Tax' : _name.text,
        taxRate: rate,
        taxInclusive: _inclusive,
        taxRegistrationNumber: _number.text,
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tax Settings')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SwitchListTile(
          value: _enabled,
          onChanged: (value) => setState(() => _enabled = value),
          title: const Text('Enable Tax'),
        ),
        TextField(
          controller: _name,
          enabled: _enabled,
          decoration: const InputDecoration(labelText: 'Tax Name'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _rate,
          enabled: _enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Tax Percentage',
            suffixText: '%',
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _number,
          decoration: const InputDecoration(labelText: 'Tax Number (optional)'),
        ),
        const SizedBox(height: 14),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Tax Exclusive')),
            ButtonSegment(value: true, label: Text('Tax Inclusive')),
          ],
          selected: {_inclusive},
          onSelectionChanged: _enabled
              ? (selection) => setState(() => _inclusive = selection.single)
              : null,
        ),
        const SizedBox(height: 24),
        FilledButton(onPressed: _save, child: const Text('Save Tax Settings')),
      ],
    ),
  );
}
