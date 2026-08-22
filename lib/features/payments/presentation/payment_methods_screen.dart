import 'package:flutter/material.dart';

import '../../../models/payment_method.dart';
import '../data/payment_method_repository.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final _repository = PaymentMethodRepository();
  List<PaymentMethod> _methods = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final methods = await _repository.getAll();
    if (!mounted) return;
    setState(() {
      _methods = List.of(methods);
      _loading = false;
    });
  }

  Future<void> _edit([PaymentMethod? method]) async {
    final controller = TextEditingController(text: method?.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          method == null ? 'Add Payment Method' : 'Rename Payment Method',
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    try {
      await _repository.save(
        method == null
            ? PaymentMethod(
                name: name,
                enabled: true,
                isSystem: false,
                sortOrder: _methods.length,
              )
            : method.copyWith(name: name),
      );
      await _load();
    } on DuplicatePaymentMethodException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('That payment method already exists.')),
        );
      }
    }
  }

  Future<void> _toggle(PaymentMethod method, bool enabled) async {
    if (!enabled && _methods.where((item) => item.enabled).length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one payment method must remain enabled.'),
        ),
      );
      return;
    }
    await _repository.save(method.copyWith(enabled: enabled));
    await _load();
  }

  Future<void> _delete(PaymentMethod method) async {
    await _repository.delete(method);
    await _load();
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      final method = _methods.removeAt(oldIndex);
      _methods.insert(newIndex, method);
    });
    _repository.reorder(_methods);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Payment Methods'),
      actions: [
        IconButton(
          onPressed: _edit,
          icon: const Icon(Icons.add),
          tooltip: 'Add',
        ),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _methods.length,
            onReorderItem: _reorder,
            itemBuilder: (context, index) {
              final method = _methods[index];
              return Card(
                key: ValueKey(method.id),
                child: ListTile(
                  leading: ReorderableDragStartListener(
                    index: index,
                    child: const Icon(Icons.drag_handle),
                  ),
                  title: Text(method.name),
                  subtitle: Text(method.enabled ? 'Enabled' : 'Disabled'),
                  trailing: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Switch(
                        value: method.enabled,
                        onChanged: (value) => _toggle(method, value),
                      ),
                      IconButton(
                        onPressed: () => _edit(method),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      if (!method.isSystem)
                        IconButton(
                          onPressed: () => _delete(method),
                          icon: const Icon(Icons.delete_outline),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _edit,
      icon: const Icon(Icons.add),
      label: const Text('Add Method'),
    ),
  );
}
