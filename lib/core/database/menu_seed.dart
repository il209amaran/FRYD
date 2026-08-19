import 'package:sqflite/sqflite.dart';

import 'category_cleanup.dart';

class MenuSeedItem {
  const MenuSeedItem(this.name, this.category, this.price);

  final String name;
  final String category;
  final double price;
}

abstract final class MenuSeed {
  static const items = <MenuSeedItem>[
    MenuSeedItem('Crispy Poppers - Regular (80 gm)', 'Fried Chicken', 99),
    MenuSeedItem('Crispy Poppers - Large (180 gm)', 'Fried Chicken', 180),
    MenuSeedItem('Crispy Drummette - Regular (3 pcs)', 'Fried Chicken', 99),
    MenuSeedItem('Crispy Drummette - Large (6 pcs)', 'Fried Chicken', 199),
    MenuSeedItem('Crispy Wings - Regular (3 pcs)', 'Fried Chicken', 99),
    MenuSeedItem('Crispy Wings - Large (6 pcs)', 'Fried Chicken', 199),
    MenuSeedItem('Crispy Tenders - Regular (3 pcs)', 'Fried Chicken', 119),
    MenuSeedItem('Crispy Tenders - Large (6 pcs)', 'Fried Chicken', 199),
    MenuSeedItem('Salted Fries - Regular (80 gm)', 'Fries', 60),
    MenuSeedItem('Salted Fries - Large (150 gm)', 'Fries', 100),
    MenuSeedItem('Masala Fries - Regular (80 gm)', 'Fries', 60),
    MenuSeedItem('Masala Fries - Large (150 gm)', 'Fries', 100),
    MenuSeedItem('FRYD Heaven (Loaded Fries)', 'Fries', 150),
    MenuSeedItem('CPOP Burger', 'Burgers & Others', 120),
    MenuSeedItem('Stinger', 'Burgers & Others', 160),
    MenuSeedItem('American Cheese Burger', 'Burgers & Others', 90),
    MenuSeedItem('Burrito', 'Burgers & Others', 150),
    MenuSeedItem('Smashed Paneer Burger', 'Burgers & Others', 120),
    MenuSeedItem('Soft Drink', 'Beverage', 25),
    MenuSeedItem('Kombucha', 'Beverage', 50),
    MenuSeedItem('Cold Coffee', 'Beverage', 90),
    MenuSeedItem('Homemade Chocolate Cake', 'Dessert', 60),
    MenuSeedItem('Schezwan Cheese Dressing', 'Extras', 25),
    MenuSeedItem('FRYD Sauce', 'Extras', 25),
    MenuSeedItem('Extra Cheese', 'Extras', 25),
  ];

  static Future<void> import(DatabaseExecutor database) async {
    final now = DateTime.now().toIso8601String();
    final categoryIds = <String, int>{};

    for (final item in items) {
      var categoryId = categoryIds[item.category];
      if (categoryId == null) {
        final existingCategories = await database.query(
          'categories',
          columns: ['id'],
          where: 'name = ? COLLATE NOCASE',
          whereArgs: [item.category],
          limit: 1,
        );
        categoryId = existingCategories.isEmpty
            ? await _insertCategory(database, item.category, now)
            : existingCategories.first['id'] as int;
        categoryIds[item.category] = categoryId;
      }

      final existingProducts = await database.query(
        'products',
        columns: ['id'],
        where: 'name = ? COLLATE NOCASE AND category_id = ?',
        whereArgs: [item.name, categoryId],
        limit: 1,
      );
      if (existingProducts.isNotEmpty) continue;

      await database.insert('products', {
        'name': item.name,
        'category_id': categoryId,
        'price': item.price,
        'created_at': now,
        'updated_at': now,
      });
    }

    await CategoryCleanup.deleteUnusedCategories(database);
  }

  static Future<int> _insertCategory(
    DatabaseExecutor database,
    String name,
    String now,
  ) async {
    final order =
        Sqflite.firstIntValue(
          await database.rawQuery(
            'SELECT COALESCE(MAX(sort_order), -1) + 1 FROM categories',
          ),
        ) ??
        0;
    return database.insert('categories', {
      'name': name,
      'sort_order': order,
      'created_at': now,
      'updated_at': now,
    });
  }
}
