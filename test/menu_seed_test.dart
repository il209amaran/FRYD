import 'package:flutter_test/flutter_test.dart';
import 'package:fryd/core/database/menu_seed.dart';

void main() {
  test('menu import contains every extracted item without duplicates', () {
    expect(MenuSeed.items, hasLength(25));

    final productKeys = MenuSeed.items
        .map(
          (item) => '${item.category.toLowerCase()}|${item.name.toLowerCase()}',
        )
        .toSet();
    expect(productKeys, hasLength(MenuSeed.items.length));

    expect(MenuSeed.items.map((item) => item.category).toSet(), {
      'Fried Chicken',
      'Fries',
      'Burgers & Others',
      'Beverage',
      'Dessert',
      'Extras',
    });
    expect(
      MenuSeed.items
          .where((item) => item.name == 'Homemade Chocolate Cake')
          .single
          .price,
      60,
    );
    expect(
      MenuSeed.items
          .where((item) => item.name == 'Smashed Paneer Burger')
          .single
          .price,
      120,
    );
  });
}
