import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/complement.dart';
import '../data/complement_repository.dart';

class ComplementFormDialog extends StatefulWidget {
  const ComplementFormDialog({
    required this.onSave,
    this.complement,
    super.key,
  });
  final Complement? complement;
  final Future<void> Function(String name, double minimum) onSave;

  @override
  State<ComplementFormDialog> createState() => _ComplementFormDialogState();
}

class _ComplementFormDialogState extends State<ComplementFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _minimum;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.complement?.name);
    _minimum = TextEditingController(
      text: widget.complement == null
          ? ''
          : widget.complement!.minimumOrderValue.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _minimum.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(_name.text, double.parse(_minimum.text));
      if (mounted) Navigator.pop(context);
    } on DuplicateComplementException {
      setState(() {
        _saving = false;
        _error = 'A complement with this name already exists.';
      });
    } catch (_) {
      setState(() {
        _saving = false;
        _error = 'Complement could not be saved.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    title: Text(
      widget.complement == null ? 'Add Complement' : 'Edit Complement',
    ),
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
              decoration: const InputDecoration(
                labelText: 'Complement Name',
                prefixIcon: Icon(Icons.redeem),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a complement name.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _minimum,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Minimum Order Value',
                prefixText: '₹ ',
              ),
              validator: (value) {
                final amount = double.tryParse(value ?? '');
                return amount == null || amount <= 0
                    ? 'Enter a valid positive amount.'
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
        child: Text(
          widget.complement == null ? 'Save Complement' : 'Update Complement',
        ),
      ),
    ],
  );
}
