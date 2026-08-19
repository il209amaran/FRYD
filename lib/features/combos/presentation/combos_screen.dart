import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../billing/presentation/billing_screen.dart';
import '../../billing/presentation/current_order_controller.dart';
import 'combo_management_screen.dart';
import 'combos_controller.dart';

class CombosScreen extends StatefulWidget {
  const CombosScreen({
    required this.currentOrder,
    required this.onOrderCompleted,
    super.key,
  });
  final CurrentOrderController currentOrder;
  final VoidCallback onOrderCompleted;

  @override
  State<CombosScreen> createState() => _CombosScreenState();
}

class _CombosScreenState extends State<CombosScreen> {
  late final CombosController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CombosController(currentOrder: widget.currentOrder)..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _manage() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ComboManagementScreen(controller: _controller),
      ),
    );
    await _controller.load();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    builder: (context, _) => LayoutBuilder(
      builder: (context, constraints) {
        final orderWidth = (constraints.maxWidth * 0.34).clamp(300.0, 410.0);
        return Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Combos',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: _manage,
                          icon: const Icon(Icons.tune),
                          label: const Text('Add / Update Combos'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: _controller.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _controller.combos.isEmpty
                          ? const Center(
                              child: Text(
                                'No combos available. Add your first combo to begin.',
                              ),
                            )
                          : LayoutBuilder(
                              builder: (context, grid) => GridView.builder(
                                itemCount: _controller.combos.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: grid.maxWidth >= 750
                                          ? 4
                                          : 3,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 1.65,
                                    ),
                                itemBuilder: (context, index) {
                                  final combo = _controller.combos[index];
                                  return Card(
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      onTap: () =>
                                          _controller.addToOrder(combo),
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              combo.name,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              formatCurrency(combo.price),
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                fontSize: 17,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: orderWidth,
              child: CurrentOrderPanel(
                controller: widget.currentOrder,
                onOrderCompleted: widget.onOrderCompleted,
              ),
            ),
          ],
        );
      },
    ),
  );
}
