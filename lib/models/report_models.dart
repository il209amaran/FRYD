class SalesSummary {
  const SalesSummary({
    required this.todaySales,
    required this.weekSales,
    required this.monthSales,
    required this.ordersToday,
    this.paymentBreakdown = const [],
  });

  final double todaySales;
  final double weekSales;
  final double monthSales;
  final int ordersToday;
  final List<PaymentCollection> paymentBreakdown;
  double get averageOrderValue =>
      ordersToday == 0 ? 0 : todaySales / ordersToday;
}

class PaymentCollection {
  const PaymentCollection({required this.name, required this.total});
  final String name;
  final double total;
}

class DailySales {
  const DailySales({required this.date, required this.total});
  final DateTime date;
  final double total;
}

class ItemSales {
  const ItemSales({
    required this.name,
    required this.type,
    required this.quantity,
    required this.sales,
  });
  final String name;
  final String type;
  final int quantity;
  final double sales;
}

class ReportOrder {
  const ReportOrder({
    required this.orderNumber,
    required this.closedAt,
    required this.status,
    required this.subtotal,
    required this.taxAmount,
    required this.paymentMethod,
    required this.total,
  });
  final String orderNumber;
  final DateTime closedAt;
  final String status;
  final double subtotal;
  final double taxAmount;
  final String paymentMethod;
  final double total;
}

class RangeReport {
  const RangeReport({
    required this.from,
    required this.to,
    required this.orders,
    required this.items,
  });
  final DateTime from;
  final DateTime to;
  final List<ReportOrder> orders;
  final List<ItemSales> items;
  double get totalCollection =>
      orders.fold(0, (sum, order) => sum + order.total);
  int get totalOrders => orders.length;
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  double get averageOrderValue =>
      totalOrders == 0 ? 0 : totalCollection / totalOrders;
}

class PeriodSales {
  const PeriodSales({
    required this.start,
    required this.end,
    required this.orders,
    required this.sales,
    this.label,
  });
  final DateTime start;
  final DateTime end;
  final int orders;
  final double sales;
  final String? label;
  double get averageOrderValue => orders == 0 ? 0 : sales / orders;
}
