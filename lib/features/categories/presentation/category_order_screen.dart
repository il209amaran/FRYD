import 'package:flutter/material.dart';

import '../../../models/category.dart';
import '../data/category_repository.dart';

class CategoryOrderScreen extends StatefulWidget {
  const CategoryOrderScreen({super.key});

  @override
  State<CategoryOrderScreen> createState() => _CategoryOrderScreenState();
}

class _CategoryOrderScreenState extends State<CategoryOrderScreen> {
  final CategoryRepository _repository = SqliteCategoryRepository();
  List<Category> _categories = const [];
  bool _loading = true;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final categories = await _repository.getCategories();
      if (!mounted) return;
      setState(() {
        // Repository results are read-only; this screen needs a mutable working
        // copy for drag-and-drop and A-Z sorting.
        _categories = List<Category>.of(categories);
        _loading = false;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Categories could not be loaded.';
      });
    }
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      final category = _categories.removeAt(oldIndex);
      _categories.insert(newIndex, category);
    });
  }

  Future<void> _resetAlphabetically() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset category order?'),
        content: const Text(
          'This will arrange all current categories alphabetically.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset to A–Z'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      _categories.sort(
        (first, second) =>
            first.name.toLowerCase().compareTo(second.name.toLowerCase()),
      );
    });
    await _save(popAfterSave: false);
  }

  Future<void> _save({bool popAfterSave = true}) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _repository.saveCategoryOrder(_categories);
      if (!mounted) return;
      if (popAfterSave) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category order reset to A–Z.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category order could not be saved.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Category Order')),
    body: SafeArea(
      child: Padding(
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < 700 ? 12 : 24,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Drag categories into the order used in Billing. All always remains first.',
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildList()),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 12,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: _loading || _saving || _categories.isEmpty
                        ? null
                        : _resetAlphabetically,
                    icon: const Icon(Icons.sort_by_alpha),
                    label: const Text('Reset to A–Z'),
                  ),
                  FilledButton.icon(
                    onPressed: _loading || _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Save Order'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildList() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) {
      return Center(
        child: OutlinedButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          label: Text(_errorMessage!),
        ),
      );
    }
    if (_categories.isEmpty) {
      return const Center(child: Text('No categories available.'));
    }
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      itemCount: _categories.length,
      onReorderItem: _reorder,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return Card(
          key: ValueKey(category.id),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            minTileHeight: 60,
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text(category.name),
            trailing: ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.drag_handle),
              ),
            ),
          ),
        );
      },
    );
  }
}
