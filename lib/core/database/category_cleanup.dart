import 'package:sqflite/sqflite.dart';

abstract final class CategoryCleanup {
  static Future<int> deleteUnusedCategories(DatabaseExecutor database) async {
    final deleted = await database.rawDelete('''
        DELETE FROM categories
        WHERE NOT EXISTS (
          SELECT 1
          FROM products
          WHERE products.category_id = categories.id
        )
      ''');
    if (deleted == 0) return 0;

    final remaining = await database.query(
      'categories',
      columns: ['id'],
      orderBy: 'sort_order, name COLLATE NOCASE, id',
    );
    for (var index = 0; index < remaining.length; index++) {
      await database.update(
        'categories',
        {'sort_order': index},
        where: 'id = ?',
        whereArgs: [remaining[index]['id']],
      );
    }
    return deleted;
  }
}
