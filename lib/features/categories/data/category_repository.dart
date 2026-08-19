import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_manager.dart';
import '../../../models/category.dart';

class DuplicateCategoryException implements Exception {
  const DuplicateCategoryException();
}

abstract interface class CategoryRepository {
  Future<List<Category>> getCategories();
  Future<Category> createCategory(String name);
  Future<void> saveCategoryOrder(List<Category> categories);
}

class SqliteCategoryRepository implements CategoryRepository {
  SqliteCategoryRepository({DatabaseManager? databaseManager})
    : _databaseManager = databaseManager ?? DatabaseManager.instance;

  final DatabaseManager _databaseManager;
  static const _customOrderKey = 'category_order_customized';
  static final _changes = StreamController<void>.broadcast();
  static Stream<void> get changes => _changes.stream;
  static void notifyCategoriesChanged() => _changes.add(null);

  @override
  Future<List<Category>> getCategories() async {
    final database = await _databaseManager.database;
    final customSetting = await database.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [_customOrderKey],
      limit: 1,
    );
    final hasCustomOrder =
        customSetting.isNotEmpty && customSetting.first['value'] == '1';
    final rows = await database.query(
      'categories',
      orderBy: hasCustomOrder
          ? 'sort_order, name COLLATE NOCASE, id'
          : 'name COLLATE NOCASE, id',
    );
    return rows.map(Category.fromMap).toList(growable: false);
  }

  @override
  Future<Category> createCategory(String name) async {
    final trimmedName = name.trim();
    final database = await _databaseManager.database;
    final duplicate = await database.query(
      'categories',
      columns: ['id'],
      where: 'name = ? COLLATE NOCASE',
      whereArgs: [trimmedName],
      limit: 1,
    );
    if (duplicate.isNotEmpty) throw const DuplicateCategoryException();

    final now = DateTime.now();
    final nextOrder =
        Sqflite.firstIntValue(
          await database.rawQuery(
            'SELECT COALESCE(MAX(sort_order), -1) + 1 FROM categories',
          ),
        ) ??
        0;
    final category = Category(
      name: trimmedName,
      sortOrder: nextOrder,
      createdAt: now,
      updatedAt: now,
    );
    try {
      final id = await database.insert(
        'categories',
        category.toMap(includeId: false),
      );
      return category.copyWith(id: id);
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) {
        throw const DuplicateCategoryException();
      }
      rethrow;
    }
  }

  @override
  Future<void> saveCategoryOrder(List<Category> categories) async {
    final database = await _databaseManager.database;
    await database.transaction((transaction) async {
      for (var index = 0; index < categories.length; index++) {
        final id = categories[index].id;
        if (id == null) continue;
        await transaction.update(
          'categories',
          {'sort_order': index, 'updated_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
      await transaction.insert('settings', {
        'key': _customOrderKey,
        'value': '1',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
    notifyCategoriesChanged();
  }
}
