import 'package:flutter/foundation.dart';

import '../../../models/order.dart';
import '../data/order_repository.dart';

enum OrderFilter { all, open, closed }

class OrdersController extends ChangeNotifier {
  OrdersController({OrderRepository? repository})
    : _repository = repository ?? SqliteOrderRepository();

  final OrderRepository _repository;
  List<RestaurantOrder> _orders = const [];
  OrderFilter _filter = OrderFilter.open;
  bool _isLoading = true;
  String? _errorMessage;

  List<RestaurantOrder> get orders => List.unmodifiable(_orders);
  OrderFilter get filter => _filter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> setFilter(OrderFilter filter) async {
    if (_filter == filter) return;
    _filter = filter;
    await loadOrders();
  }

  Future<void> loadOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final status = switch (_filter) {
        OrderFilter.all => null,
        OrderFilter.open => OrderStatus.open,
        OrderFilter.closed => OrderStatus.closed,
      };
      _orders = await _repository.getOrders(status: status);
    } catch (_) {
      _errorMessage = 'Orders could not be loaded.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteOrder(RestaurantOrder order) async {
    await _repository.deleteOrder(order.id);
    _orders = _orders.where((item) => item.id != order.id).toList();
    notifyListeners();
  }
}
