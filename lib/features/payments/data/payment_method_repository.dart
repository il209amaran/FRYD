import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_manager.dart';
import '../../../models/payment_method.dart';

class DuplicatePaymentMethodException implements Exception {
  const DuplicatePaymentMethodException();
}

class PaymentMethodRepository {
  PaymentMethodRepository({DatabaseManager? databaseManager})
    : _databaseManager = databaseManager ?? DatabaseManager.instance;

  final DatabaseManager _databaseManager;

  Future<List<PaymentMethod>> getAll({bool enabledOnly = false}) async {
    final database = await _databaseManager.database;
    final rows = await database.query(
      'payment_methods',
      where: enabledOnly ? 'enabled = 1' : null,
      orderBy: 'sort_order, name COLLATE NOCASE',
    );
    return rows.map(PaymentMethod.fromMap).toList(growable: false);
  }

  Future<void> save(PaymentMethod method) async {
    final database = await _databaseManager.database;
    final now = DateTime.now().toIso8601String();
    try {
      if (method.id == null) {
        final next =
            Sqflite.firstIntValue(
              await database.rawQuery(
                'SELECT COALESCE(MAX(sort_order), -1) + 1 FROM payment_methods',
              ),
            ) ??
            0;
        await database.insert('payment_methods', {
          'name': method.name.trim(),
          'enabled': method.enabled ? 1 : 0,
          'is_system': 0,
          'sort_order': next,
          'created_at': now,
          'updated_at': now,
        });
      } else {
        await database.update(
          'payment_methods',
          {
            'name': method.name.trim(),
            'enabled': method.enabled ? 1 : 0,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [method.id],
        );
      }
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) {
        throw const DuplicatePaymentMethodException();
      }
      rethrow;
    }
  }

  Future<void> delete(PaymentMethod method) async {
    if (method.id == null || method.isSystem) return;
    final database = await _databaseManager.database;
    await database.delete(
      'payment_methods',
      where: 'id = ?',
      whereArgs: [method.id],
    );
  }

  Future<void> reorder(List<PaymentMethod> methods) async {
    final database = await _databaseManager.database;
    await database.transaction((transaction) async {
      for (var index = 0; index < methods.length; index++) {
        await transaction.update(
          'payment_methods',
          {'sort_order': index},
          where: 'id = ?',
          whereArgs: [methods[index].id],
        );
      }
    });
  }
}
