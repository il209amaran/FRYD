import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../models/combo.dart';
import 'combo_form_dialog.dart';
import 'combos_controller.dart';

class ComboManagementScreen extends StatelessWidget {
  const ComboManagementScreen({required this.controller, super.key});
  final CombosController controller;

  Future<void> _form(BuildContext context, [Combo? combo]) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ComboFormDialog(
      combo: combo,
      onSave: (name, price) =>
          controller.save(existing: combo, name: name, price: price),
    ),
  );

  Future<void> _delete(BuildContext context, Combo combo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Combo?'),
        content: Text('Are you sure you want to delete "${combo.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.delete(combo);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Combo Management')),
    body: ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Padding(
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < 700 ? 12 : 24,
        ),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => _form(context),
                icon: const Icon(Icons.add),
                label: const Text('Add New Combo'),
                style: FilledButton.styleFrom(minimumSize: const Size(180, 52)),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: controller.combos.isEmpty
                  ? const Center(child: Text('No combos yet.'))
                  : ListView.separated(
                      itemCount: controller.combos.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final combo = controller.combos[index];
                        return Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            title: Text(
                              combo.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: MediaQuery.sizeOf(context).width < 600
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Wrap(
                                      spacing: 8,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(formatCurrency(combo.price)),
                                        IconButton.outlined(
                                          onPressed: () =>
                                              _form(context, combo),
                                          icon: const Icon(Icons.edit_outlined),
                                          tooltip: 'Edit',
                                        ),
                                        IconButton.outlined(
                                          onPressed: () =>
                                              _delete(context, combo),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                          tooltip: 'Delete',
                                        ),
                                      ],
                                    ),
                                  )
                                : const Text('Category: Combo'),
                            trailing: MediaQuery.sizeOf(context).width < 600
                                ? null
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        formatCurrency(combo.price),
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 18),
                                      IconButton.outlined(
                                        onPressed: () => _form(context, combo),
                                        icon: const Icon(Icons.edit_outlined),
                                        tooltip: 'Edit',
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton.outlined(
                                        onPressed: () =>
                                            _delete(context, combo),
                                        icon: const Icon(Icons.delete_outline),
                                        tooltip: 'Delete',
                                      ),
                                    ],
                                  ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}
