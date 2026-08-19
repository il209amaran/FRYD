import 'package:flutter/foundation.dart';

import '../../../models/category.dart' as model;
import '../../../models/product.dart';
import '../../categories/data/category_repository.dart';
import '../data/product_repository.dart';

class ProductsController extends ChangeNotifier {
  ProductsController({ProductRepository? repository})
    : _repository = repository ?? SqliteProductRepository();

  final ProductRepository _repository;
  List<Product> _products = const [];
  bool _isLoading = true;
  String? _errorMessage;

  List<Product> get products => List.unmodifiable(_products);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _products = await _repository.getProducts();
    } catch (_) {
      _errorMessage = 'Products could not be loaded. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveProduct({
    Product? existing,
    required String name,
    required model.Category category,
    required double price,
  }) async {
    final now = DateTime.now();
    if (existing == null) {
      await _repository.createProduct(
        Product(
          name: name.trim(),
          category: category,
          price: price,
          createdAt: now,
          updatedAt: now,
        ),
      );
    } else {
      await _repository.updateProduct(
        existing.copyWith(
          name: name.trim(),
          category: category,
          price: price,
          updatedAt: now,
        ),
      );
    }
    SqliteCategoryRepository.notifyCategoriesChanged();
    await loadProducts();
  }

  Future<void> deleteProduct(Product product) async {
    final id = product.id;
    if (id == null) return;
    await _repository.deleteProduct(id);
    SqliteCategoryRepository.notifyCategoriesChanged();
    await loadProducts();
  }
}
