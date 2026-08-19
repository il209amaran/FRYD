import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'combo_seed.dart';
import 'complement_seed.dart';
import 'menu_seed.dart';

class DatabaseManager {
  DatabaseManager._();

  static final DatabaseManager instance = DatabaseManager._();
  static const _databaseName = 'fryd.db';
  static const _databaseVersion = 10;
  Database? _database;

  Future<Database> get database async => _database ??= await _open();

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), _databaseName);
    return openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: (database) => database.execute('PRAGMA foreign_keys = ON'),
      onCreate: _createSchema,
      onUpgrade: _upgradeSchema,
    );
  }

  Future<void> _createSchema(Database database, int version) async {
    await database.transaction((transaction) async {
      await transaction.execute(
        'CREATE TABLE categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL COLLATE NOCASE UNIQUE, sort_order INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)',
      );
      await transaction.execute(
        'CREATE TABLE products (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, category_id INTEGER NOT NULL, price REAL NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, FOREIGN KEY (category_id) REFERENCES categories (id))',
      );
      await _createOrderTables(transaction);
      await transaction.execute(
        'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
      );
      await _createComboTable(transaction);
      await _createComplementTable(transaction);
      await MenuSeed.import(transaction);
      await ComboSeed.import(transaction);
      await ComplementSeed.import(transaction);
    });
  }

  Future<void> _upgradeSchema(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 10) {
      final columns = await database.rawQuery('PRAGMA table_info(categories)');
      if (!columns.any((column) => column['name'] == 'sort_order')) {
        await database.transaction((transaction) async {
          await transaction.execute(
            'ALTER TABLE categories ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0',
          );
          final categories = await transaction.query(
            'categories',
            columns: ['id'],
            orderBy: 'name COLLATE NOCASE, id',
          );
          for (var index = 0; index < categories.length; index++) {
            await transaction.update(
              'categories',
              {'sort_order': index},
              where: 'id = ?',
              whereArgs: [categories[index]['id']],
            );
          }
        });
      }
    }
    if (oldVersion < 2) {
      await database.transaction((transaction) async {
        await transaction.execute(
          "ALTER TABLE products ADD COLUMN category TEXT NOT NULL DEFAULT ''",
        );
        await transaction.execute(
          "ALTER TABLE products ADD COLUMN created_at TEXT NOT NULL DEFAULT ''",
        );
        await transaction.execute(
          "ALTER TABLE products ADD COLUMN updated_at TEXT NOT NULL DEFAULT ''",
        );
      });
    }
    if (oldVersion < 3) {
      final productColumns = await database.rawQuery(
        'PRAGMA table_info(products)',
      );
      final hasLegacyCategoryId = productColumns.any(
        (column) => column['name'] == 'category_id',
      );
      final now = DateTime.now().toIso8601String();
      await database.transaction((transaction) async {
        await transaction.execute(
          "ALTER TABLE categories ADD COLUMN created_at TEXT NOT NULL DEFAULT ''",
        );
        await transaction.execute(
          "ALTER TABLE categories ADD COLUMN updated_at TEXT NOT NULL DEFAULT ''",
        );
        await transaction.rawUpdate(
          'UPDATE categories SET created_at = ?, updated_at = ? WHERE created_at = ? OR updated_at = ?',
          [now, now, '', ''],
        );
        await transaction.rawInsert(
          '''
          INSERT INTO categories (name, created_at, updated_at)
          SELECT DISTINCT TRIM(p.category), ?, ?
          FROM products p
          WHERE TRIM(p.category) != ''
            AND NOT EXISTS (
              SELECT 1 FROM categories c
              WHERE c.name = TRIM(p.category) COLLATE NOCASE
            )
          ''',
          [now, now],
        );
        await transaction.execute(
          'CREATE UNIQUE INDEX categories_name_nocase ON categories (name COLLATE NOCASE)',
        );
        await transaction.execute(
          'CREATE TABLE products_v3 (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, category_id INTEGER, price REAL NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, FOREIGN KEY (category_id) REFERENCES categories (id))',
        );
        final categoryIdExpression = hasLegacyCategoryId
            ? '''COALESCE(
                (SELECT c.id FROM categories c WHERE c.id = p.category_id),
                (SELECT c.id FROM categories c WHERE c.name = TRIM(p.category) COLLATE NOCASE LIMIT 1)
              )'''
            : '''(SELECT c.id FROM categories c
                  WHERE c.name = TRIM(p.category) COLLATE NOCASE LIMIT 1)''';
        await transaction.execute('''
          INSERT INTO products_v3
            (id, name, category_id, price, created_at, updated_at)
          SELECT id, name, $categoryIdExpression, price, created_at, updated_at
          FROM products p
        ''');
        await transaction.execute('DROP TABLE products');
        await transaction.execute('ALTER TABLE products_v3 RENAME TO products');
      });
    }
    if (oldVersion < 4) {
      await database.transaction(MenuSeed.import);
    }
    if (oldVersion < 5) {
      await database.transaction((transaction) async {
        await transaction.execute('DROP TABLE IF EXISTS bill_items');
        await transaction.execute('DROP TABLE IF EXISTS bills');
        await _createOrderTables(transaction);
      });
    }
    if (oldVersion < 6) {
      await database.transaction((transaction) async {
        await _createComboTable(transaction);
        final columns = await transaction.rawQuery(
          'PRAGMA table_info(order_items)',
        );
        if (!columns.any((column) => column['name'] == 'item_type')) {
          await transaction.execute(
            "ALTER TABLE order_items ADD COLUMN item_type TEXT NOT NULL DEFAULT 'PRODUCT'",
          );
        }
        if (!columns.any((column) => column['name'] == 'combo_id')) {
          await transaction.execute(
            'ALTER TABLE order_items ADD COLUMN combo_id INTEGER',
          );
        }
      });
    }
    if (oldVersion < 7) {
      await database.transaction(ComboSeed.import);
    }
    if (oldVersion < 8) {
      await database.transaction((transaction) async {
        await _createComplementTable(transaction);
        await transaction.execute(
          "CREATE TABLE order_items_v8 (id INTEGER PRIMARY KEY AUTOINCREMENT, order_id INTEGER NOT NULL, product_id INTEGER, combo_id INTEGER, complement_id INTEGER, item_type TEXT NOT NULL CHECK (item_type IN ('PRODUCT', 'COMBO', 'COMPLEMENT')), is_complementary INTEGER NOT NULL DEFAULT 0, product_name TEXT NOT NULL, unit_price REAL NOT NULL, quantity INTEGER NOT NULL, line_total REAL NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE)",
        );
        await transaction.execute('''
          INSERT INTO order_items_v8
            (id, order_id, product_id, combo_id, item_type, is_complementary,
             product_name, unit_price, quantity, line_total, created_at, updated_at)
          SELECT id, order_id, product_id, combo_id, item_type, 0,
             product_name, unit_price, quantity, line_total, created_at, updated_at
          FROM order_items
        ''');
        await transaction.execute('DROP TABLE order_items');
        await transaction.execute(
          'ALTER TABLE order_items_v8 RENAME TO order_items',
        );
        await transaction.execute(
          'CREATE INDEX order_items_order_id ON order_items (order_id)',
        );
      });
    }
    if (oldVersion < 9) {
      await database.transaction((transaction) async {
        await transaction.execute('ALTER TABLE orders RENAME TO orders_v8');
        await transaction.execute(
          'ALTER TABLE order_items RENAME TO order_items_v8_backup',
        );
        await _createOrdersTable(transaction);
        await transaction.execute('''
          INSERT INTO orders
            (id, order_number, status, subtotal, total, created_at, updated_at, closed_at)
          SELECT id, order_number, status, subtotal, total, created_at, updated_at, closed_at
          FROM orders_v8
        ''');
        await _createOrderItemsTable(transaction, createIndex: false);
        await transaction.execute('''
          INSERT INTO order_items
            (id, order_id, product_id, combo_id, complement_id, item_type,
             is_complementary, product_name, unit_price, quantity, line_total,
             created_at, updated_at)
          SELECT id, order_id, product_id, combo_id, complement_id, item_type,
             is_complementary, product_name, unit_price, quantity, line_total,
             created_at, updated_at
          FROM order_items_v8_backup
        ''');
        await transaction.execute('DROP TABLE order_items_v8_backup');
        await transaction.execute('DROP TABLE orders_v8');
        await transaction.execute(
          'CREATE INDEX order_items_order_id ON order_items (order_id)',
        );
        await _createDailySequenceTable(transaction);
        await transaction.execute('''
          INSERT INTO order_daily_sequences (order_date, last_sequence)
          SELECT SUBSTR(created_at, 1, 10),
                 MAX(CAST(SUBSTR(order_number, 5) AS INTEGER))
          FROM orders
          WHERE order_number GLOB 'ORD-[0-9]*'
          GROUP BY SUBSTR(created_at, 1, 10)
        ''');
      });
    }
  }

  Future<void> _createComplementTable(DatabaseExecutor database) async {
    await database.execute(
      'CREATE TABLE complements (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL COLLATE NOCASE UNIQUE, minimum_order_value REAL NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)',
    );
  }

  Future<void> _createComboTable(DatabaseExecutor database) async {
    await database.execute(
      'CREATE TABLE combos (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL COLLATE NOCASE UNIQUE, price REAL NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)',
    );
  }

  Future<void> _createOrderTables(DatabaseExecutor database) async {
    await _createOrdersTable(database);
    await _createOrderItemsTable(database);
    await _createDailySequenceTable(database);
  }

  Future<void> _createOrdersTable(DatabaseExecutor database) async {
    await database.execute(
      "CREATE TABLE orders (id INTEGER PRIMARY KEY AUTOINCREMENT, order_number TEXT NOT NULL, status TEXT NOT NULL CHECK (status IN ('OPEN', 'CLOSED')), subtotal REAL NOT NULL, total REAL NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, closed_at TEXT)",
    );
  }

  Future<void> _createOrderItemsTable(
    DatabaseExecutor database, {
    bool createIndex = true,
  }) async {
    await database.execute(
      "CREATE TABLE order_items (id INTEGER PRIMARY KEY AUTOINCREMENT, order_id INTEGER NOT NULL, product_id INTEGER, combo_id INTEGER, complement_id INTEGER, item_type TEXT NOT NULL CHECK (item_type IN ('PRODUCT', 'COMBO', 'COMPLEMENT')), is_complementary INTEGER NOT NULL DEFAULT 0, product_name TEXT NOT NULL, unit_price REAL NOT NULL, quantity INTEGER NOT NULL, line_total REAL NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE)",
    );
    if (createIndex) {
      await database.execute(
        'CREATE INDEX order_items_order_id ON order_items (order_id)',
      );
    }
  }

  Future<void> _createDailySequenceTable(DatabaseExecutor database) async {
    await database.execute(
      'CREATE TABLE IF NOT EXISTS order_daily_sequences (order_date TEXT PRIMARY KEY, last_sequence INTEGER NOT NULL)',
    );
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
