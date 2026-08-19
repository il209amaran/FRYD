import 'package:sqflite/sqflite.dart';

class ComboSeedItem {
  const ComboSeedItem(this.name, this.price);

  final String name;
  final double price;
}

abstract final class ComboSeed {
  static const items = <ComboSeedItem>[
    ComboSeedItem('Regular of All 3: Poppers + Wings + Drummette', 278),
    ComboSeedItem('Large of All 3: Wings + Drummette + Tenders', 569),
    ComboSeedItem(
      'ACB + Choice of Reg Fried Chicken (Except Tenders) + Softdrink',
      199,
    ),
    ComboSeedItem('CPOP Burger 1+1', 169),
    ComboSeedItem('Stinger 1+1', 289),
    ComboSeedItem('FRYD Heaven + Stinger', 289),
  ];

  static Future<void> import(DatabaseExecutor database) async {
    final now = DateTime.now().toIso8601String();
    for (final item in items) {
      final existing = await database.query(
        'combos',
        columns: ['id'],
        where: 'name = ? COLLATE NOCASE',
        whereArgs: [item.name],
        limit: 1,
      );
      if (existing.isNotEmpty) continue;

      await database.insert('combos', {
        'name': item.name,
        'price': item.price,
        'created_at': now,
        'updated_at': now,
      });
    }
  }
}
