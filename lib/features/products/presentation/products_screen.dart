import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../models/product.dart';
import 'product_form_dialog.dart';
import 'products_controller.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late final ProductsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ProductsController()..loadProducts();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openForm([Product? product]) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ProductFormDialog(
      product: product,
      onSave: (name, category, price) => _controller.saveProduct(
        existing: product,
        name: name,
        category: category,
        price: price,
      ),
    ),
  );

  Future<void> _confirmDelete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _controller.deleteProduct(product);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product could not be deleted. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    builder: (context, _) => Padding(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 700 ? 12 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Text(
                'Products',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              if (_controller.products.isNotEmpty)
                FilledButton.icon(
                  onPressed: _openForm,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Product'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(160, 52),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(child: _buildBody()),
        ],
      ),
    ),
  );

  Widget _buildBody() {
    if (_controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_controller.errorMessage case final message?) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _controller.loadProducts,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      );
    }
    if (_controller.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 18),
            Text(
              'No products yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your first product to start building your restaurant menu.',
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _openForm,
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
              style: FilledButton.styleFrom(minimumSize: const Size(180, 56)),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: _controller.products.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final product = _controller.products[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 560;
                final details = Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      child: Text(
                        product.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Category: ${product.category.name}',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
                final actions = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatCurrency(product.price),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 20),
                    IconButton.outlined(
                      onPressed: () => _openForm(product),
                      tooltip: 'Edit ${product.name}',
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      onPressed: () => _confirmDelete(product),
                      tooltip: 'Delete ${product.name}',
                      color: Theme.of(context).colorScheme.error,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                );
                return narrow
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          details,
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: actions,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: details),
                          actions,
                        ],
                      );
              },
            ),
          ),
        );
      },
    );
  }
}
