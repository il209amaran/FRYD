import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/category.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/product.dart';
import '../../categories/data/category_repository.dart';

class ProductFormDialog extends StatefulWidget {
  const ProductFormDialog({required this.onSave, this.product, super.key});

  final Product? product;
  final Future<void> Function(String name, Category category, double price)
  onSave;

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final CategoryRepository _categoryRepository = SqliteCategoryRepository();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  List<Category> _categories = const [];
  int? _selectedCategoryId;
  bool _isLoadingCategories = true;
  bool _isSaving = false;
  String? _categoryLoadError;
  String? _saveError;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name);
    _selectedCategoryId = product?.category.id;
    _priceController = TextEditingController(
      text: product == null
          ? ''
          : product.price.toStringAsFixed(
              product.price == product.price.roundToDouble() ? 0 : 2,
            ),
    );
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories({int? selectId}) async {
    try {
      final categories = await _categoryRepository.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _selectedCategoryId = selectId ?? _selectedCategoryId;
        _isLoadingCategories = false;
        _categoryLoadError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingCategories = false;
        _categoryLoadError = 'Categories could not be loaded.';
      });
    }
  }

  Future<void> _addCategory() async {
    final category = await showDialog<Category>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddCategoryDialog(repository: _categoryRepository),
    );
    if (category?.id case final id?) await _loadCategories(selectId: id);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final category = _categories
        .where((item) => item.id == _selectedCategoryId)
        .firstOrNull;
    if (category == null) return;
    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    try {
      await widget.onSave(
        _nameController.text,
        category,
        double.parse(_priceController.text),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _saveError = 'Product could not be saved. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    title: Text(_isEditing ? 'Update product' : 'Add product'),
    content: SizedBox(
      width: MediaQuery.sizeOf(context).width < 700 ? double.maxFinite : 560,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Product name',
                prefixIcon: Icon(Icons.fastfood_outlined),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a product name.'
                  : null,
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final dropdown = _buildCategoryDropdown();
                final addButton = SizedBox(
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : _addCategory,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Category'),
                  ),
                );
                if (constraints.maxWidth < 460) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [dropdown, const SizedBox(height: 10), addButton],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: dropdown),
                    const SizedBox(width: 12),
                    addButton,
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Price',
                prefixText: '${CurrencyFormatter.symbol} ',
              ),
              validator: (value) {
                final price = double.tryParse(value ?? '');
                return price == null || price <= 0
                    ? 'Enter a valid positive price.'
                    : null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            if (_saveError != null) ...[
              const SizedBox(height: 12),
              Text(
                _saveError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    ),
    actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
    actions: [
      TextButton(
        onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _isSaving || _isLoadingCategories ? null : _submit,
        child: _isSaving
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(_isEditing ? 'Update Product' : 'Save Product'),
      ),
    ],
  );

  Widget _buildCategoryDropdown() {
    if (_isLoadingCategories) {
      return const SizedBox(
        height: 56,
        child: Center(child: LinearProgressIndicator()),
      );
    }
    if (_categoryLoadError != null) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: 'Category',
          errorText: _categoryLoadError,
        ),
        child: InkWell(
          onTap: _loadCategories,
          child: const Text('Tap to retry'),
        ),
      );
    }
    return DropdownButtonFormField<int>(
      key: ValueKey(_selectedCategoryId),
      initialValue: _selectedCategoryId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Category',
        prefixIcon: Icon(Icons.category_outlined),
      ),
      hint: Text(
        _categories.isEmpty ? 'No categories available' : 'Select Category',
      ),
      items: _categories
          .map(
            (category) => DropdownMenuItem(
              value: category.id,
              child: Text(category.name),
            ),
          )
          .toList(growable: false),
      onChanged: _categories.isEmpty || _isSaving
          ? null
          : (value) => setState(() => _selectedCategoryId = value),
      validator: (value) => value == null ? 'Select a category.' : null,
    );
  }
}

class _AddCategoryDialog extends StatefulWidget {
  const _AddCategoryDialog({required this.repository});
  final CategoryRepository repository;

  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isSaving = false;
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorText = null;
    });
    try {
      final category = await widget.repository.createCategory(
        _nameController.text,
      );
      if (mounted) Navigator.pop(context, category);
    } on DuplicateCategoryException {
      setState(() {
        _isSaving = false;
        _errorText = 'A category with this name already exists.';
      });
    } catch (_) {
      setState(() {
        _isSaving = false;
        _errorText = 'Category could not be saved. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    title: const Text('Add Category'),
    content: SizedBox(
      width: MediaQuery.sizeOf(context).width < 600 ? double.maxFinite : 400,
      child: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Category Name',
            errorText: _errorText,
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Enter a category name.'
              : null,
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _isSaving ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _isSaving ? null : _submit,
        child: _isSaving
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Add Category'),
      ),
    ],
  );
}
