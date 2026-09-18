import 'package:flutter_test/flutter_test.dart';
import 'package:fryd/features/orders/presentation/orders_controller.dart';

void main() {
  test('recent orders include today and the previous two calendar days', () {
    final cutoff = recentOrdersCutoff(DateTime(2026, 9, 4, 18, 45));

    expect(cutoff, DateTime(2026, 9, 2));
  });

  test('recent orders cutoff works across month boundaries', () {
    final cutoff = recentOrdersCutoff(DateTime(2026, 9, 1, 8));

    expect(cutoff, DateTime(2026, 8, 30));
  });
}
