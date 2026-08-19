import 'package:sqflite/sqflite.dart';

class ComplementSeedItem {
  const ComplementSeedItem(this.name, this.minimumOrderValue);

  final String name;
  final double minimumOrderValue;
}

abstract final class ComplementSeed {
  static const items = <ComplementSeedItem>[ComplementSeedItem('Burger', 149)];

  static Future<void> import(DatabaseExecutor database) async {
    final now = DateTime.now().toIso8601String();
    for (final item in items) {
      await database.insert('complements', {
        'name': item.name,
        'minimum_order_value': item.minimumOrderValue,
        'created_at': now,
        'updated_at': now,
      });
    }
  }
}
