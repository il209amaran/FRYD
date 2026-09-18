import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_time_formatter.dart';
import '../../../models/order.dart';
import '../../orders/data/order_repository.dart';
import '../../orders/presentation/order_details_screen.dart';
import '../../orders/presentation/orders_screen.dart';

class ClosedOrdersHistoryScreen extends StatefulWidget {
  const ClosedOrdersHistoryScreen({super.key});

  @override
  State<ClosedOrdersHistoryScreen> createState() =>
      _ClosedOrdersHistoryScreenState();
}

class _ClosedOrdersHistoryScreenState extends State<ClosedOrdersHistoryScreen> {
  final OrderRepository _repository = SqliteOrderRepository();
  late Future<List<RestaurantOrder>> _orders;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _orders = _repository.getOrders(status: OrderStatus.closed);
  }

  Future<void> _refresh() async {
    setState(_load);
    await _orders;
  }

  Future<void> _openOrder(RestaurantOrder order) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => OrderDetailsScreen(orderId: order.id)),
    );
    if (mounted) setState(_load);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('All Closed Orders')),
    body: FutureBuilder<List<RestaurantOrder>>(
      future: _orders,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: OutlinedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Reload closed orders'),
            ),
          );
        }
        final orders = snapshot.data ?? const [];
        if (orders.isEmpty) {
          return const Center(child: Text('No closed orders available.'));
        }
        final groups = _groupByDate(orders);
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            padding: EdgeInsets.all(
              MediaQuery.sizeOf(context).width < 700 ? 12 : 24,
            ),
            itemCount: groups.length,
            separatorBuilder: (_, _) => const SizedBox(height: 24),
            itemBuilder: (context, index) {
              final group = groups[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DateTotalHeader(group: group),
                  const SizedBox(height: 10),
                  for (
                    var orderIndex = 0;
                    orderIndex < group.orders.length;
                    orderIndex++
                  ) ...[
                    _ClosedOrderCard(
                      order: group.orders[orderIndex],
                      onTap: () => _openOrder(group.orders[orderIndex]),
                    ),
                    if (orderIndex < group.orders.length - 1)
                      const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
        );
      },
    ),
  );
}

List<_ClosedOrdersDay> _groupByDate(List<RestaurantOrder> orders) {
  final grouped = <DateTime, List<RestaurantOrder>>{};
  for (final order in orders) {
    final local = order.createdAt.toLocal();
    final date = DateTime(local.year, local.month, local.day);
    grouped.putIfAbsent(date, () => []).add(order);
  }
  return grouped.entries
      .map((entry) => _ClosedOrdersDay(date: entry.key, orders: entry.value))
      .toList(growable: false);
}

class _ClosedOrdersDay {
  const _ClosedOrdersDay({required this.date, required this.orders});

  final DateTime date;
  final List<RestaurantOrder> orders;

  double get total => orders.fold(0, (sum, order) => sum + order.total);
}

class _DateTotalHeader extends StatelessWidget {
  const _DateTotalHeader({required this.group});

  final _ClosedOrdersDay group;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatDate(group.date),
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  '${group.orders.length} closed ${group.orders.length == 1 ? 'order' : 'orders'}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Date total'),
              Text(
                formatCurrency(group.total),
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _ClosedOrderCard extends StatelessWidget {
  const _ClosedOrderCard({required this.order, required this.onTap});

  final RestaurantOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(child: Icon(Icons.task_alt_outlined)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.orderNumber,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatOrderDateTime(order.createdAt),
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatCurrency(order.total),
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                OrderStatusChip(status: order.status),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    ),
  );
}
