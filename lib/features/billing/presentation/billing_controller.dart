import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../models/category.dart' as model;
import '../../../models/order_item.dart';
import '../../../models/product.dart';
import '../../categories/data/category_repository.dart';
import '../../products/data/product_repository.dart';
import 'current_order_controller.dart';

class BillingController extends ChangeNotifier {
  BillingController({
    required this.currentOrder,
    ProductRepository? productRepository,
    CategoryRepository? categoryRepository,
  }) : _productRepository = productRepository ?? SqliteProductRepository(),
       _categoryRepository = categoryRepository ?? SqliteCategoryRepository() {
    currentOrder.addListener(notifyListeners);
    _categoryChanges = SqliteCategoryRepository.changes.listen(
      (_) => _reloadCategoryOrder(),
    );
  }

  final CurrentOrderController currentOrder;
  final ProductRepository _productRepository;
  final CategoryRepository _categoryRepository;
  late final StreamSubscription<void> _categoryChanges;
  List<Product> _products = const [];
  List<model.Category> _categories = const [];
  int? _selectedCategoryId;
  bool _isLoading = true;
  String? _errorMessage;

  List<model.Category> get categories => List.unmodifiable(_categories);
  int? get selectedCategoryId => _selectedCategoryId;
  List<Product> get visibleProducts => List.unmodifiable(
    _selectedCategoryId == null
        ? _products
        : _products.where(
            (product) => product.category.id == _selectedCategoryId,
          ),
  );
  List<OrderItem> get orderItems => currentOrder.items;
  bool get isLoading => _isLoading;
  bool get isCompleting => currentOrder.isCompleting;
  String? get errorMessage => _errorMessage ?? currentOrder.errorMessage;
  double get subtotal => currentOrder.subtotal;
  double get total => currentOrder.total;

  Future<void> loadProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _productRepository.getProducts(),
        _categoryRepository.getCategories(),
      ]);
      _products = results[0] as List<Product>;
      _categories = results[1] as List<model.Category>;
    } catch (_) {
      _errorMessage = 'Products could not be loaded.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _reloadCategoryOrder() => loadProducts();

  void selectCategory(int? categoryId) {
    if (_selectedCategoryId == categoryId) return;
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void addProduct(Product product) => currentOrder.addProduct(product);
  void increase(OrderItem item) => currentOrder.increase(item);
  void decrease(OrderItem item) => currentOrder.decrease(item);
  Future<bool> completeOrder() => currentOrder.completeOrder();

  @override
  void dispose() {
    currentOrder.removeListener(notifyListeners);
    _categoryChanges.cancel();
    super.dispose();
  }
}
