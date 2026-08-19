import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_time_formatter.dart';
import '../../../models/order.dart';
import 'order_details_screen.dart';
import 'orders_controller.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late final OrdersController _controller;

  @override
  void initState() {
    super.initState();
    _controller = OrdersController()..loadOrders();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openOrder(RestaurantOrder order) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => OrderDetailsScreen(orderId: order.id)),
    );
    await _controller.loadOrders();
  }

  Future<void> _deleteOrder(RestaurantOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Order?'),
        content: Text(
          'Are you sure you want to permanently delete ${order.orderNumber}?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _controller.deleteOrder(order);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order could not be deleted. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    builder: (context, _) => Padding(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 700 ? 12 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Orders', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 18),
          SegmentedButton<OrderFilter>(
            segments: const [
              ButtonSegment(value: OrderFilter.all, label: Text('All')),
              ButtonSegment(value: OrderFilter.open, label: Text('Open')),
              ButtonSegment(value: OrderFilter.closed, label: Text('Closed')),
            ],
            selected: {_controller.filter},
            onSelectionChanged: (selection) =>
                _controller.setFilter(selection.single),
          ),
          const SizedBox(height: 18),
          Expanded(child: _buildBody()),
        ],
      ),
    ),
  );

  Widget _buildBody() {
    if (_controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_controller.errorMessage != null) {
      return Center(
        child: OutlinedButton.icon(
          onPressed: _controller.loadOrders,
          icon: const Icon(Icons.refresh),
          label: const Text('Reload orders'),
        ),
      );
    }
    if (_controller.orders.isEmpty) {
      final label = switch (_controller.filter) {
        OrderFilter.open => 'No open orders',
        OrderFilter.closed => 'No closed orders',
        OrderFilter.all => 'No orders yet',
      };
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 58,
              color: Colors.black26,
            ),
            const SizedBox(height: 14),
            Text(label, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            const Text(
              'New orders will appear here after you complete them from Create Order.',
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: _controller.orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = _controller.orders[index];
        if (MediaQuery.sizeOf(context).width < 600) {
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _openOrder(order),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            order.orderNumber,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        _StatusChip(status: order.status),
                      ],
                    ),
                    Text(
                      formatOrderDateTime(order.createdAt),
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Total: ${formatCurrency(order.total)}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _deleteOrder(order),
                          tooltip: 'Delete ${order.orderNumber}',
                          color: Theme.of(context).colorScheme.error,
                          icon: const Icon(Icons.delete_outline),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openOrder(order),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    child: Icon(
                      order.isOpen ? Icons.pending_actions : Icons.task_alt,
                    ),
                  ),
                  const SizedBox(width: 16),
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
                  Text(
                    'Total: ${formatCurrency(order.total)}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 20),
                  _StatusChip(status: order.status),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _deleteOrder(order),
                    tooltip: 'Delete ${order.orderNumber}',
                    color: Theme.of(context).colorScheme.error,
                    icon: const Icon(Icons.delete_outline),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({required this.status, super.key});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) => _StatusChip(status: status);
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final open = status == OrderStatus.open;
    return Chip(
      avatar: Icon(
        open ? Icons.circle : Icons.check_circle,
        size: 14,
        color: open ? Colors.orange.shade800 : Colors.green.shade800,
      ),
      label: Text(status.databaseValue),
      backgroundColor: open ? Colors.orange.shade50 : Colors.green.shade50,
      side: BorderSide(
        color: open ? Colors.orange.shade200 : Colors.green.shade200,
      ),
    );
  }
}
