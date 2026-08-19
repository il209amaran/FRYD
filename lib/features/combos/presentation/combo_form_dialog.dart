import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/combo.dart';
import '../data/combo_repository.dart';

class ComboFormDialog extends StatefulWidget {
  const ComboFormDialog({required this.onSave, this.combo, super.key});
  final Combo? combo;
  final Future<void> Function(String name, double price) onSave;

  @override
  State<ComboFormDialog> createState() => _ComboFormDialogState();
}

class _ComboFormDialogState extends State<ComboFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.combo?.name);
    _price = TextEditingController(
      text: widget.combo == null ? '' : widget.combo!.price.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(_name.text, double.parse(_price.text));
      if (mounted) Navigator.pop(context);
    } on DuplicateComboException {
      setState(() {
        _saving = false;
        _error = 'A combo with this name already exists.';
      });
    } catch (_) {
      setState(() {
        _saving = false;
        _error = 'Combo could not be saved.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    title: Text(widget.combo == null ? 'Add Combo' : 'Edit Combo'),
    content: SizedBox(
      width: MediaQuery.sizeOf(context).width < 700 ? double.maxFinite : 460,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Combo Name'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a combo name.'
                  : null,
            ),
            const SizedBox(height: 14),
            const InputDecorator(
              decoration: InputDecoration(labelText: 'Category'),
              child: Text('Combo'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Price',
                prefixText: '₹ ',
              ),
              validator: (value) {
                final price = double.tryParse(value ?? '');
                return price == null || price <= 0
                    ? 'Enter a valid positive price.'
                    : null;
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _saving ? null : _submit,
        child: Text(widget.combo == null ? 'Save Combo' : 'Update Combo'),
      ),
    ],
  );
}
