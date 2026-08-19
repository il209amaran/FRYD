import '../../../core/database/database_manager.dart';
import '../../../core/database/category_cleanup.dart';
import '../../../models/product.dart';

abstract interface class ProductRepository {
  Future<List<Product>> getProducts();
  Future<Product> createProduct(Product product);
  Future<void> updateProduct(Product product);
  Future<void> deleteProduct(int id);
}

class SqliteProductRepository implements ProductRepository {
  SqliteProductRepository({DatabaseManager? databaseManager})
    : _databaseManager = databaseManager ?? DatabaseManager.instance;

  final DatabaseManager _databaseManager;

  @override
  Future<List<Product>> getProducts() async {
    final database = await _databaseManager.database;
    final rows = await database.rawQuery('''
      SELECT p.*, c.name AS category_name,
        c.sort_order AS category_sort_order,
        c.created_at AS category_created_at,
        c.updated_at AS category_updated_at
      FROM products p
      INNER JOIN categories c ON c.id = p.category_id
      ORDER BY p.name COLLATE NOCASE
      ''');
    return rows.map(Product.fromMap).toList(growable: false);
  }

  @override
  Future<Product> createProduct(Product product) async {
    final database = await _databaseManager.database;
    final id = await database.transaction((transaction) async {
      final productId = await transaction.insert(
        'products',
        product.toMap(includeId: false),
      );
      await CategoryCleanup.deleteUnusedCategories(transaction);
      return productId;
    });
    return product.copyWith(id: id);
  }

  @override
  Future<void> updateProduct(Product product) async {
    final id = product.id;
    if (id == null) throw ArgumentError('A product ID is required to update.');
    final database = await _databaseManager.database;
    await database.transaction((transaction) async {
      await transaction.update(
        'products',
        product.toMap(includeId: false),
        where: 'id = ?',
        whereArgs: [id],
      );
      await CategoryCleanup.deleteUnusedCategories(transaction);
    });
  }

  @override
  Future<void> deleteProduct(int id) async {
    final database = await _databaseManager.database;
    await database.transaction((transaction) async {
      await transaction.delete('products', where: 'id = ?', whereArgs: [id]);
      await CategoryCleanup.deleteUnusedCategories(transaction);
    });
  }
}
