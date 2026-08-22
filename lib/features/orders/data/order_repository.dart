import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_manager.dart';
import '../../../models/order.dart';
import '../../../models/order_item.dart';

abstract interface class OrderRepository {
  Future<List<RestaurantOrder>> getOrders({OrderStatus? status});
  Future<List<RestaurantOrder>> getDeletedOrders();
  Future<RestaurantOrder> getOrder(int id);
  Future<List<OrderItem>> getOrderItems(int orderId);
  Future<RestaurantOrder> createOrder(List<OrderItem> items);
  Future<void> updateOpenOrder(int orderId, List<OrderItem> items);
  Future<void> closeOrder(int orderId);
  Future<void> deleteOrder(int orderId);
  Future<void> permanentlyDeleteOrder(int orderId);
}

class SqliteOrderRepository implements OrderRepository {
  SqliteOrderRepository({DatabaseManager? databaseManager})
    : _databaseManager = databaseManager ?? DatabaseManager.instance;

  final DatabaseManager _databaseManager;

  @override
  Future<List<RestaurantOrder>> getOrders({OrderStatus? status}) async {
    final database = await _databaseManager.database;
    await _purgeExpiredDeletedOrders(database);
    final rows = await database.query(
      'orders',
      where: status == null
          ? 'deleted_at IS NULL'
          : 'status = ? AND deleted_at IS NULL',
      whereArgs: status == null ? null : [status.databaseValue],
      orderBy: 'created_at DESC, id DESC',
    );
    return rows.map(RestaurantOrder.fromMap).toList(growable: false);
  }

  @override
  Future<List<RestaurantOrder>> getDeletedOrders() async {
    final database = await _databaseManager.database;
    await _purgeExpiredDeletedOrders(database);
    final rows = await database.query(
      'orders',
      where: 'deleted_at IS NOT NULL',
      orderBy: 'deleted_at DESC, id DESC',
    );
    return rows.map(RestaurantOrder.fromMap).toList(growable: false);
  }

  @override
  Future<RestaurantOrder> getOrder(int id) async {
    final database = await _databaseManager.database;
    final rows = await database.query(
      'orders',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) throw StateError('Order not found.');
    return RestaurantOrder.fromMap(rows.single);
  }

  @override
  Future<List<OrderItem>> getOrderItems(int orderId) async {
    final database = await _databaseManager.database;
    final rows = await database.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'id',
    );
    return rows.map(OrderItem.fromMap).toList(growable: false);
  }

  @override
  Future<RestaurantOrder> createOrder(List<OrderItem> items) async {
    if (items.isEmpty) throw ArgumentError('An order must contain items.');
    final database = await _databaseManager.database;
    final id = await database.transaction((transaction) async {
      final createdAt = DateTime.now();
      final now = createdAt.toIso8601String();
      final sequence = await _nextDailySequence(transaction, createdAt);
      final orderNumber = 'ORD-${sequence.toString().padLeft(4, '0')}';
      final total = _total(items);
      final orderId = await transaction.insert('orders', {
        'order_number': orderNumber,
        'status': OrderStatus.open.databaseValue,
        'subtotal': total,
        'total': total,
        'created_at': now,
        'updated_at': now,
      });
      await _replaceItems(transaction, orderId, items, now);
      return orderId;
    });
    return getOrder(id);
  }

  @override
  Future<void> updateOpenOrder(int orderId, List<OrderItem> items) async {
    if (items.isEmpty) throw ArgumentError('An order must contain items.');
    final database = await _databaseManager.database;
    await database.transaction((transaction) async {
      final now = DateTime.now().toIso8601String();
      final total = _total(items);
      final changed = await transaction.update(
        'orders',
        {'subtotal': total, 'total': total, 'updated_at': now},
        where: 'id = ? AND status = ?',
        whereArgs: [orderId, OrderStatus.open.databaseValue],
      );
      if (changed != 1) throw StateError('Only open orders can be edited.');
      await transaction.delete(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [orderId],
      );
      await _replaceItems(transaction, orderId, items, now);
    });
  }

  @override
  Future<void> closeOrder(int orderId) async {
    final database = await _databaseManager.database;
    final now = DateTime.now().toIso8601String();
    final changed = await database.update(
      'orders',
      {
        'status': OrderStatus.closed.databaseValue,
        'closed_at': now,
        'updated_at': now,
      },
      where: 'id = ? AND status = ?',
      whereArgs: [orderId, OrderStatus.open.databaseValue],
    );
    if (changed != 1) throw StateError('Only open orders can be closed.');
  }

  @override
  Future<void> deleteOrder(int orderId) async {
    final database = await _databaseManager.database;
    final now = DateTime.now().toIso8601String();
    final changed = await database.update(
      'orders',
      {'deleted_at': now, 'updated_at': now},
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [orderId],
    );
    if (changed != 1) throw StateError('Order not found.');
  }

  @override
  Future<void> permanentlyDeleteOrder(int orderId) async {
    final database = await _databaseManager.database;
    final deleted = await database.delete(
      'orders',
      where: 'id = ? AND deleted_at IS NOT NULL',
      whereArgs: [orderId],
    );
    if (deleted != 1) throw StateError('Deleted order not found.');
  }

  Future<void> _purgeExpiredDeletedOrders(Database database) async {
    final cutoff = DateTime.now()
        .subtract(const Duration(days: 45))
        .toIso8601String();
    await database.delete(
      'orders',
      where: 'deleted_at IS NOT NULL AND deleted_at <= ?',
      whereArgs: [cutoff],
    );
  }

  double _total(List<OrderItem> items) =>
      items.fold(0, (sum, item) => sum + item.total);

  Future<int> _nextDailySequence(
    Transaction transaction,
    DateTime createdAt,
  ) async {
    final dateKey =
        '${createdAt.year.toString().padLeft(4, '0')}-'
        '${createdAt.month.toString().padLeft(2, '0')}-'
        '${createdAt.day.toString().padLeft(2, '0')}';
    final rows = await transaction.query(
      'order_daily_sequences',
      columns: ['last_sequence'],
      where: 'order_date = ?',
      whereArgs: [dateKey],
      limit: 1,
    );
    if (rows.isEmpty) {
      await transaction.insert('order_daily_sequences', {
        'order_date': dateKey,
        'last_sequence': 1,
      });
      return 1;
    }
    final next = (rows.single['last_sequence'] as int) + 1;
    await transaction.update(
      'order_daily_sequences',
      {'last_sequence': next},
      where: 'order_date = ?',
      whereArgs: [dateKey],
    );
    return next;
  }

  Future<void> _replaceItems(
    Transaction transaction,
    int orderId,
    List<OrderItem> items,
    String now,
  ) async {
    for (final item in items) {
      await transaction.insert('order_items', {
        'order_id': orderId,
        'product_id': item.productId,
        'combo_id': item.comboId,
        'complement_id': item.complementId,
        'item_type': item.itemType.databaseValue,
        'is_complementary': item.isComplementary ? 1 : 0,
        'product_name': item.productName,
        'unit_price': item.unitPrice,
        'quantity': item.quantity,
        'line_total': item.total,
        'created_at': now,
        'updated_at': now,
      });
    }
  }
}
