import 'package:flutter/material.dart';

import '../../../models/receipt_settings.dart';
import '../data/receipt_settings_repository.dart';

class ReceiptSettingsScreen extends StatefulWidget {
  const ReceiptSettingsScreen({super.key});

  @override
  State<ReceiptSettingsScreen> createState() => _ReceiptSettingsScreenState();
}

class _ReceiptSettingsScreenState extends State<ReceiptSettingsScreen> {
  final _repository = ReceiptSettingsRepository();
  final _header = TextEditingController();
  final _footer = TextEditingController();
  ReceiptSettings? _settings;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _repository.get();
    if (!mounted) return;
    _header.text = settings.header;
    _footer.text = settings.footer;
    setState(() => _settings = settings);
  }

  Future<void> _save() async {
    final settings = _settings;
    if (settings == null) return;
    await _repository.save(
      settings.copyWith(header: _header.text, footer: _footer.text),
    );
    if (mounted) Navigator.pop(context);
  }

  void _toggle(ReceiptSettings Function(ReceiptSettings) update) {
    setState(() => _settings = update(_settings!));
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt Settings')),
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                SwitchListTile(
                  value: settings.showBusinessName,
                  title: const Text('Show Business Name'),
                  onChanged: (value) =>
                      _toggle((item) => item.copyWith(showBusinessName: value)),
                ),
                SwitchListTile(
                  value: settings.showAddress,
                  title: const Text('Show Address'),
                  onChanged: (value) =>
                      _toggle((item) => item.copyWith(showAddress: value)),
                ),
                SwitchListTile(
                  value: settings.showPhone,
                  title: const Text('Show Phone'),
                  onChanged: (value) =>
                      _toggle((item) => item.copyWith(showPhone: value)),
                ),
                SwitchListTile(
                  value: settings.showEmail,
                  title: const Text('Show Email'),
                  onChanged: (value) =>
                      _toggle((item) => item.copyWith(showEmail: value)),
                ),
                SwitchListTile(
                  value: settings.showTaxNumber,
                  title: const Text('Show Tax Number'),
                  onChanged: (value) =>
                      _toggle((item) => item.copyWith(showTaxNumber: value)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _header,
                  decoration: const InputDecoration(
                    labelText: 'Receipt Header',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _footer,
                  decoration: const InputDecoration(
                    labelText: 'Receipt Footer',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _save,
                  child: const Text('Save Receipt Settings'),
                ),
              ],
            ),
    );
  }
}
