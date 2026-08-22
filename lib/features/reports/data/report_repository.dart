import '../../../core/database/database_manager.dart';
import '../../../models/report_models.dart';

abstract interface class ReportRepository {
  Future<SalesSummary> getSummary(DateTime now);
  Future<List<DailySales>> getSevenDayTrend(DateTime now);
  Future<List<ItemSales>> getTopItems({int limit = 5});
  Future<RangeReport> getRangeReport(DateTime from, DateTime to);
  Future<List<PeriodSales>> getWeeklyReport(DateTime now);
  Future<List<PeriodSales>> getMonthlyReport(DateTime now);
}

class SqliteReportRepository implements ReportRepository {
  SqliteReportRepository({DatabaseManager? databaseManager})
    : _databaseManager = databaseManager ?? DatabaseManager.instance;

  final DatabaseManager _databaseManager;

  DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

  @override
  Future<SalesSummary> getSummary(DateTime now) async {
    final database = await _databaseManager.database;
    final today = _day(now);
    final tomorrow = today.add(const Duration(days: 1));
    final week = today.subtract(
      Duration(days: today.weekday - DateTime.monday),
    );
    final month = DateTime(today.year, today.month);
    final row = (await database.rawQuery(
      '''
      SELECT
        COALESCE(SUM(CASE WHEN closed_at >= ? AND closed_at < ? THEN total END), 0) AS today_sales,
        COALESCE(SUM(CASE WHEN closed_at >= ? AND closed_at < ? THEN total END), 0) AS week_sales,
        COALESCE(SUM(CASE WHEN closed_at >= ? AND closed_at < ? THEN total END), 0) AS month_sales,
        COALESCE(SUM(CASE WHEN closed_at >= ? AND closed_at < ? THEN 1 ELSE 0 END), 0) AS orders_today
      FROM orders WHERE status = 'CLOSED'
      ''',
      [
        today.toIso8601String(),
        tomorrow.toIso8601String(),
        week.toIso8601String(),
        tomorrow.toIso8601String(),
        month.toIso8601String(),
        tomorrow.toIso8601String(),
        today.toIso8601String(),
        tomorrow.toIso8601String(),
      ],
    )).single;
    final paymentRows = await database.rawQuery(
      '''SELECT COALESCE(payment_method_name, 'Unspecified') AS method,
        SUM(total) AS collection FROM orders
        WHERE status = 'CLOSED' AND closed_at >= ? AND closed_at < ?
        GROUP BY payment_method_name ORDER BY collection DESC''',
      [today.toIso8601String(), tomorrow.toIso8601String()],
    );
    return SalesSummary(
      todaySales: (row['today_sales'] as num).toDouble(),
      weekSales: (row['week_sales'] as num).toDouble(),
      monthSales: (row['month_sales'] as num).toDouble(),
      ordersToday: (row['orders_today'] as num).toInt(),
      paymentBreakdown: paymentRows
          .map(
            (value) => PaymentCollection(
              name: value['method'] as String,
              total: (value['collection'] as num).toDouble(),
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<List<DailySales>> getSevenDayTrend(DateTime now) async {
    final database = await _databaseManager.database;
    final today = _day(now);
    final start = today.subtract(const Duration(days: 6));
    final end = today.add(const Duration(days: 1));
    final rows = await database.rawQuery(
      "SELECT date(closed_at) AS day, COALESCE(SUM(total), 0) AS sales FROM orders WHERE status = 'CLOSED' AND closed_at >= ? AND closed_at < ? GROUP BY date(closed_at)",
      [start.toIso8601String(), end.toIso8601String()],
    );
    final values = {
      for (final row in rows)
        row['day'] as String: (row['sales'] as num).toDouble(),
    };
    return List.generate(7, (index) {
      final date = start.add(Duration(days: index));
      final key =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      return DailySales(date: date, total: values[key] ?? 0);
    });
  }

  @override
  Future<List<ItemSales>> getTopItems({int limit = 5}) async {
    final database = await _databaseManager.database;
    final rows = await database.rawQuery(
      '''
      SELECT oi.product_name, oi.item_type, SUM(oi.quantity) AS quantity,
        SUM(oi.line_total) AS sales
      FROM order_items oi
      INNER JOIN orders o ON o.id = oi.order_id
      WHERE o.status = 'CLOSED' AND oi.is_complementary = 0
      GROUP BY oi.product_name, oi.item_type
      ORDER BY quantity DESC, sales DESC
      LIMIT ?
      ''',
      [limit],
    );
    return rows.map(_itemFromRow).toList(growable: false);
  }

  @override
  Future<RangeReport> getRangeReport(DateTime from, DateTime to) async {
    final database = await _databaseManager.database;
    final start = _day(from);
    final endExclusive = _day(to).add(const Duration(days: 1));
    final args = [start.toIso8601String(), endExclusive.toIso8601String()];
    final orderRows = await database.rawQuery(
      "SELECT order_number, closed_at, status, subtotal, tax_amount, total, COALESCE(payment_method_name, 'Unspecified') AS payment_method FROM orders WHERE status = 'CLOSED' AND closed_at >= ? AND closed_at < ? ORDER BY closed_at",
      args,
    );
    final itemRows = await database.rawQuery('''
      SELECT oi.product_name, oi.item_type, SUM(oi.quantity) AS quantity,
        SUM(oi.line_total) AS sales
      FROM order_items oi INNER JOIN orders o ON o.id = oi.order_id
      WHERE o.status = 'CLOSED' AND oi.is_complementary = 0
        AND o.closed_at >= ? AND o.closed_at < ?
      GROUP BY oi.product_name, oi.item_type ORDER BY quantity DESC
      ''', args);
    return RangeReport(
      from: start,
      to: _day(to),
      orders: orderRows
          .map(
            (row) => ReportOrder(
              orderNumber: row['order_number'] as String,
              closedAt: DateTime.parse(row['closed_at'] as String),
              status: row['status'] as String,
              subtotal: (row['subtotal'] as num).toDouble(),
              taxAmount: (row['tax_amount'] as num).toDouble(),
              paymentMethod: row['payment_method'] as String,
              total: (row['total'] as num).toDouble(),
            ),
          )
          .toList(growable: false),
      items: itemRows.map(_itemFromRow).toList(growable: false),
    );
  }

  @override
  Future<List<PeriodSales>> getWeeklyReport(DateTime now) async {
    final database = await _databaseManager.database;
    final minimum = await _firstClosedDate();
    if (minimum == null) return const [];
    final start = _day(minimum);
    final today = _day(now);
    final rows = await database.rawQuery(
      '''
      SELECT CAST((julianday(date(closed_at)) - julianday(?)) / 7 AS INTEGER) AS period,
        COUNT(*) AS orders, SUM(total) AS sales
      FROM orders WHERE status = 'CLOSED' AND closed_at < ?
      GROUP BY period ORDER BY period
      ''',
      [
        start.toIso8601String(),
        today.add(const Duration(days: 1)).toIso8601String(),
      ],
    );
    return rows
        .map((row) {
          final index = (row['period'] as num).toInt();
          final periodStart = start.add(Duration(days: index * 7));
          final proposedEnd = periodStart.add(const Duration(days: 6));
          return PeriodSales(
            start: periodStart,
            end: proposedEnd.isAfter(today) ? today : proposedEnd,
            orders: (row['orders'] as num).toInt(),
            sales: (row['sales'] as num).toDouble(),
            label: 'Week ${index + 1}',
          );
        })
        .toList(growable: false);
  }

  @override
  Future<List<PeriodSales>> getMonthlyReport(DateTime now) async {
    final database = await _databaseManager.database;
    final rows = await database.rawQuery('''
      SELECT strftime('%Y-%m', closed_at) AS period, COUNT(*) AS orders,
        SUM(total) AS sales FROM orders WHERE status = 'CLOSED'
      GROUP BY period ORDER BY period
      ''');
    return rows
        .map((row) {
          final parts = (row['period'] as String).split('-');
          final start = DateTime(int.parse(parts[0]), int.parse(parts[1]));
          final next = DateTime(start.year, start.month + 1);
          final monthEnd = next.subtract(const Duration(days: 1));
          final today = _day(now);
          return PeriodSales(
            start: start,
            end: monthEnd.isAfter(today) ? today : monthEnd,
            orders: (row['orders'] as num).toInt(),
            sales: (row['sales'] as num).toDouble(),
          );
        })
        .toList(growable: false);
  }

  Future<DateTime?> _firstClosedDate() async {
    final database = await _databaseManager.database;
    final row = (await database.rawQuery(
      "SELECT MIN(closed_at) AS first_date FROM orders WHERE status = 'CLOSED'",
    )).single;
    final value = row['first_date'] as String?;
    return value == null ? null : DateTime.parse(value);
  }

  ItemSales _itemFromRow(Map<String, Object?> row) => ItemSales(
    name: row['product_name'] as String,
    type: row['item_type'] as String,
    quantity: (row['quantity'] as num).toInt(),
    sales: (row['sales'] as num).toDouble(),
  );
}
