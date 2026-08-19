import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../models/complement.dart';
import 'complement_form_dialog.dart';
import 'complements_controller.dart';

class ComplementsScreen extends StatefulWidget {
  const ComplementsScreen({super.key});

  @override
  State<ComplementsScreen> createState() => _ComplementsScreenState();
}

class _ComplementsScreenState extends State<ComplementsScreen> {
  late final ComplementsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ComplementsController()..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _form([Complement? complement]) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ComplementFormDialog(
      complement: complement,
      onSave: (name, minimum) =>
          _controller.save(existing: complement, name: name, minimum: minimum),
    ),
  );

  Future<void> _delete(Complement complement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Complement?'),
        content: Text('Are you sure you want to delete "${complement.name}"?'),
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
    if (confirmed == true) await _controller.delete(complement);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    builder: (context, _) => Padding(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 700 ? 12 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Complements',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              FilledButton.icon(
                onPressed: _form,
                icon: const Icon(Icons.add),
                label: const Text('Add Complement'),
                style: FilledButton.styleFrom(minimumSize: const Size(170, 52)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _controller.items.isEmpty
                ? const Center(child: Text('No complements configured.'))
                : ListView.separated(
                    itemCount: _controller.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final complement = _controller.items[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          leading: const CircleAvatar(
                            child: Icon(Icons.redeem),
                          ),
                          title: Text(
                            complement.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: MediaQuery.sizeOf(context).width < 600
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Eligible from ${formatCurrency(complement.minimumOrderValue)}',
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        IconButton.outlined(
                                          onPressed: () => _form(complement),
                                          icon: const Icon(Icons.edit_outlined),
                                          tooltip: 'Edit',
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton.outlined(
                                          onPressed: () => _delete(complement),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                          tooltip: 'Delete',
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : Text(
                                  'Eligible from ${formatCurrency(complement.minimumOrderValue)}',
                                ),
                          trailing: MediaQuery.sizeOf(context).width < 600
                              ? null
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton.outlined(
                                      onPressed: () => _form(complement),
                                      icon: const Icon(Icons.edit_outlined),
                                      tooltip: 'Edit',
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton.outlined(
                                      onPressed: () => _delete(complement),
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
  );
}
