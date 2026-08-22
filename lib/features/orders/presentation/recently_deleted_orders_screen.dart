import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_time_formatter.dart';
import '../../../models/order.dart';
import '../data/order_repository.dart';

class RecentlyDeletedOrdersScreen extends StatefulWidget {
  const RecentlyDeletedOrdersScreen({super.key});

  @override
  State<RecentlyDeletedOrdersScreen> createState() =>
      _RecentlyDeletedOrdersScreenState();
}

class _RecentlyDeletedOrdersScreenState
    extends State<RecentlyDeletedOrdersScreen> {
  final OrderRepository _repository = SqliteOrderRepository();
  List<RestaurantOrder> _orders = const [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final orders = await _repository.getDeletedOrders();
      if (!mounted) return;
      setState(() => _orders = orders);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Deleted orders could not be loaded.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _permanentlyDelete(RestaurantOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanently Delete Order?'),
        content: Text(
          'Permanently delete ${order.orderNumber} and all of its items?\n\n'
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
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.permanentlyDeleteOrder(order.id);
      if (!mounted) return;
      setState(() {
        _orders = _orders.where((item) => item.id != order.id).toList();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order could not be permanently deleted.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Recently Deleted Orders')),
    body: Padding(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 700 ? 12 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Orders are permanently deleted 45 days after they are moved here.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 18),
          Expanded(child: _buildBody()),
        ],
      ),
    ),
  );

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) {
      return Center(
        child: OutlinedButton.icon(
          onPressed: _loadOrders,
          icon: const Icon(Icons.refresh),
          label: const Text('Reload deleted orders'),
        ),
      );
    }
    if (_orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_sweep_outlined, size: 58, color: Colors.black26),
            SizedBox(height: 14),
            Text('No recently deleted orders'),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: _orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _DeletedOrderCard(
        order: _orders[index],
        onDelete: () => _permanentlyDelete(_orders[index]),
      ),
    );
  }
}

class _DeletedOrderCard extends StatelessWidget {
  const _DeletedOrderCard({required this.order, required this.onDelete});

  final RestaurantOrder order;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final deletedAt = order.deletedAt!;
    final expiresAt = deletedAt.add(const Duration(days: 45));
    final remaining = expiresAt.difference(DateTime.now()).inDays + 1;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final details = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.orderNumber,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(formatOrderDateTime(order.createdAt)),
                const SizedBox(height: 4),
                Text(
                  'Total: ${formatCurrency(order.total)}  •  '
                  'Permanently deleted in $remaining day${remaining == 1 ? '' : 's'}',
                ),
              ],
            );
            final action = OutlinedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_forever_outlined),
              label: const Text('Delete Permanently'),
            );
            if (constraints.maxWidth < 650) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [details, const SizedBox(height: 12), action],
              );
            }
            return Row(
              children: [
                Expanded(child: details),
                const SizedBox(width: 16),
                action,
              ],
            );
          },
        ),
      ),
    );
  }
}
