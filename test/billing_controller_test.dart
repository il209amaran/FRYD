import 'package:flutter_test/flutter_test.dart';
import 'package:fryd/features/billing/presentation/billing_controller.dart';
import 'package:fryd/features/billing/presentation/current_order_controller.dart';
import 'package:fryd/features/categories/data/category_repository.dart';
import 'package:fryd/features/orders/data/order_repository.dart';
import 'package:fryd/features/products/data/product_repository.dart';
import 'package:fryd/models/category.dart';
import 'package:fryd/models/order.dart';
import 'package:fryd/models/order_item.dart';
import 'package:fryd/models/product.dart';
import 'package:fryd/models/payment_method.dart';

void main() {
  test('loads products, changes quantity, and completes an order', () async {
    final now = DateTime(2026, 8, 17);
    final category = Category(
      id: 1,
      name: 'Burgers',
      createdAt: now,
      updatedAt: now,
    );
    final product = Product(
      id: 7,
      name: 'Chicken Burger',
      category: category,
      price: 180,
      createdAt: now,
      updatedAt: now,
    );
    final orderRepository = _FakeOrderRepository();
    final controller = BillingController(
      currentOrder: CurrentOrderController(repository: orderRepository),
      productRepository: _FakeProductRepository([product]),
      categoryRepository: _FakeCategoryRepository([category]),
    );

    await controller.loadProducts();
    controller.addProduct(product);
    controller.addProduct(product);

    expect(controller.orderItems.single.quantity, 2);
    expect(controller.subtotal, 360);

    final completed = await controller.completeOrder();
    expect(completed, isTrue);
    expect(orderRepository.createdItems.single.quantity, 2);
    expect(controller.orderItems, isEmpty);
  });
}

class _FakeCategoryRepository implements CategoryRepository {
  _FakeCategoryRepository(this.categories);
  final List<Category> categories;
  @override
  Future<Category> createCategory(String name) => throw UnimplementedError();
  @override
  Future<List<Category>> getCategories() async => categories;
  @override
  Future<void> saveCategoryOrder(List<Category> categories) async {}
}

class _FakeProductRepository implements ProductRepository {
  _FakeProductRepository(this.products);
  final List<Product> products;
  @override
  Future<List<Product>> getProducts() async => products;
  @override
  Future<Product> createProduct(Product product) => throw UnimplementedError();
  @override
  Future<void> deleteProduct(int id) => throw UnimplementedError();
  @override
  Future<void> updateProduct(Product product) => throw UnimplementedError();
}

class _FakeOrderRepository implements OrderRepository {
  List<OrderItem> createdItems = const [];
  @override
  Future<RestaurantOrder> createOrder(List<OrderItem> items) async {
    createdItems = items;
    return RestaurantOrder(
      id: 1,
      orderNumber: 'ORD-0001',
      status: OrderStatus.open,
      subtotal: 360,
      total: 360,
      createdAt: DateTime(2026, 8, 17),
      updatedAt: DateTime(2026, 8, 17),
    );
  }

  @override
  Future<void> closeOrder(int orderId, PaymentMethod paymentMethod) =>
      throw UnimplementedError();
  @override
  Future<void> deleteOrder(int orderId) => throw UnimplementedError();

  @override
  Future<List<RestaurantOrder>> getDeletedOrders() =>
      throw UnimplementedError();

  @override
  Future<RestaurantOrder> getOrder(int id) => throw UnimplementedError();
  @override
  Future<List<OrderItem>> getOrderItems(int orderId) =>
      throw UnimplementedError();
  @override
  Future<List<RestaurantOrder>> getOrders({OrderStatus? status}) =>
      throw UnimplementedError();
  @override
  Future<void> updateOpenOrder(int orderId, List<OrderItem> items) =>
      throw UnimplementedError();
}
