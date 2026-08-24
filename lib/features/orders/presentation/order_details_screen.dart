import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/menu_item_tile.dart';
import '../../../core/utils/date_time_formatter.dart';
import '../../../models/combo.dart';
import '../../../models/complement.dart';
import '../../../models/order_item.dart';
import '../../../models/product.dart';
import '../../printer/presentation/printer_settings_screen.dart';
import '../../printer/services/printer_service.dart';
import '../../printer/services/receipt_service.dart';
import 'order_details_controller.dart';

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({required this.orderId, super.key});
  final int orderId;

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late final OrderDetailsController _controller;
  final ReceiptService _receiptService = ReceiptService();
  final TextEditingController _customerNameController = TextEditingController();
  _ItemTab _selectedTab = _ItemTab.products;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _controller = OrderDetailsController(orderId: widget.orderId)..load();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final saved = await _controller.saveChanges();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Order changes saved.'
              : (_controller.errorMessage ?? 'Add at least one product.'),
        ),
      ),
    );
  }

  Future<void> _close() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Order?'),
        content: const Text(
          'Confirm that payment has been received and close this order.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Close Order'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final closed = await _controller.closeOrder();
    if (!mounted) return;
    if (closed) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _controller.errorMessage ?? 'Order could not be closed.',
          ),
        ),
      );
    }
  }

  Future<void> _printBill() async {
    if (_isPrinting) return;
    if (_controller.isDirty) {
      final saveFirst = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Save changes before printing?'),
          content: const Text(
            'The current order has unsaved changes. Save the latest version before printing the bill.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save & Print'),
            ),
          ],
        ),
      );
      if (saveFirst != true) return;
      if (!await _controller.saveChanges()) {
        if (mounted) {
          _showMessage(
            _controller.errorMessage ?? 'Order changes could not be saved.',
          );
        }
        return;
      }
    }

    setState(() => _isPrinting = true);
    try {
      await _receiptService.printOrder(
        widget.orderId,
        customerName: _customerNameController.text,
      );
      _showMessage('Bill sent to the receipt printer.');
    } on PrinterException catch (error) {
      if (mounted) await _showPrinterError(error.message);
    } catch (_) {
      if (mounted) {
        await _showPrinterError(
          'Print failed. Please check the printer and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showPrinterError(String message) async {
    final openSettings = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Printer not connected'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Printer Settings'),
          ),
        ],
      ),
    );
    if (openSettings == true && mounted) {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Printer Settings')),
            body: const PrinterSettingsScreen(),
          ),
        ),
      );
    }
  }

  Future<void> _selectComplement() async {
    int? selectedId = _controller.complementaryItem?.complementId;
    final selected = await showDialog<Complement>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          scrollable: true,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          title: const Text('Select Complimentary Item'),
          content: SizedBox(
            width: MediaQuery.sizeOf(context).width < 600
                ? double.maxFinite
                : 430,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'This order is eligible for one complimentary item.',
                ),
                const SizedBox(height: 12),
                RadioGroup<int>(
                  groupValue: selectedId,
                  onChanged: (value) =>
                      setDialogState(() => selectedId = value),
                  child: Column(
                    children: [
                      for (final complement in _controller.eligibleComplements)
                        RadioListTile<int>(
                          value: complement.id!,
                          title: Text(complement.name),
                          subtitle: Text(
                            'Eligible from ${formatCurrency(complement.minimumOrderValue)}',
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selectedId == null
                  ? null
                  : () => Navigator.pop(
                      context,
                      _controller.eligibleComplements.firstWhere(
                        (item) => item.id == selectedId,
                      ),
                    ),
              child: const Text('Add Complement'),
            ),
          ],
        ),
      ),
    );
    if (selected != null) {
      _controller.selectComplement(selected);
    } else {
      _controller.endComplementSelection();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Order Details')),
    body: ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final order = _controller.order;
        if (order == null) {
          return Center(
            child: OutlinedButton.icon(
              onPressed: _controller.load,
              icon: const Icon(Icons.refresh),
              label: const Text('Reload order'),
            ),
          );
        }
        if (_controller.shouldPromptComplementSelection &&
            !_controller.selectionDialogOpen) {
          _controller.beginComplementSelection();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _selectComplement();
          });
        }
        final narrow = MediaQuery.sizeOf(context).width < 700;
        return Flex(
          direction: narrow ? Axis.vertical : Axis.horizontal,
          children: [
            if (order.isOpen)
              Expanded(
                flex: 3,
                child: Padding(
                  padding: narrow
                      ? const EdgeInsets.all(12)
                      : const EdgeInsets.fromLTRB(24, 20, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add items',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<_ItemTab>(
                        segments: const [
                          ButtonSegment(
                            value: _ItemTab.products,
                            icon: Icon(Icons.restaurant_menu),
                            label: Text('Products'),
                          ),
                          ButtonSegment(
                            value: _ItemTab.combos,
                            icon: Icon(Icons.fastfood),
                            label: Text('Combos'),
                          ),
                        ],
                        selected: {_selectedTab},
                        onSelectionChanged: (selection) =>
                            setState(() => _selectedTab = selection.single),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: _selectedTab == _ItemTab.products
                            ? _ProductGrid(
                                products: _controller.products,
                                onTap: _controller.addProduct,
                              )
                            : _ComboGrid(
                                combos: _controller.combos,
                                onTap: _controller.addCombo,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              flex: order.isOpen ? (narrow ? 4 : 2) : 1,
              child: ColoredBox(
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(narrow ? 14 : 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              order.orderNumber,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                          Chip(label: Text(order.status.databaseValue)),
                        ],
                      ),
                      Text(
                        formatOrderDateTime(order.createdAt),
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const Divider(height: 28),
                      Expanded(
                        child: ListView.separated(
                          itemCount: _controller.items.length,
                          separatorBuilder: (_, _) => const Divider(height: 22),
                          itemBuilder: (context, index) => _DetailItemRow(
                            item: _controller.items[index],
                            editable:
                                order.isOpen &&
                                !_controller.items[index].isComplementary,
                            onIncrease: _controller.increase,
                            onDecrease: _controller.decrease,
                          ),
                        ),
                      ),
                      const Divider(height: 24),
                      if (_controller.requiresComplementSelection) ...[
                        OutlinedButton.icon(
                          onPressed: () {
                            _controller.beginComplementSelection();
                            _selectComplement();
                          },
                          icon: const Icon(Icons.redeem),
                          label: const Text('Select Complement'),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (_controller.canChangeComplement) ...[
                        OutlinedButton.icon(
                          onPressed: () {
                            _controller.beginComplementSelection();
                            _selectComplement();
                          },
                          icon: const Icon(Icons.redeem),
                          label: const Text('Change Complement'),
                        ),
                        const SizedBox(height: 8),
                      ],
                      _AmountRow(label: 'Subtotal', value: _controller.total),
                      _AmountRow(
                        label: 'Grand Total',
                        value: _controller.total,
                        prominent: true,
                      ),
                      const SizedBox(height: 16),
                      if (order.isOpen) ...[
                        TextField(
                          controller: _customerNameController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Customer Name (Optional)',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _OrderActions(
                        isOpen: order.isOpen,
                        isDirty: _controller.isDirty,
                        isSaving: _controller.isSaving,
                        isPrinting: _isPrinting,
                        hasItems: _controller.items.isNotEmpty,
                        onSave: _save,
                        onPrint: _printBill,
                        onClose: _close,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _OrderActions extends StatelessWidget {
  const _OrderActions({
    required this.isOpen,
    required this.isDirty,
    required this.isSaving,
    required this.isPrinting,
    required this.hasItems,
    required this.onSave,
    required this.onPrint,
    required this.onClose,
  });

  final bool isOpen;
  final bool isDirty;
  final bool isSaving;
  final bool isPrinting;
  final bool hasItems;
  final VoidCallback onSave;
  final VoidCallback onPrint;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final count = isOpen ? 3 : 1;
      final stacked =
          constraints.maxWidth < 520 &&
          MediaQuery.sizeOf(context).height >= 600;
      final width = stacked
          ? constraints.maxWidth
          : (constraints.maxWidth - (count - 1) * 12) / count;
      final buttons = <Widget>[
        if (isOpen)
          OutlinedButton(
            onPressed: isDirty && !isSaving ? onSave : null,
            child: const Text('Save Changes'),
          ),
        OutlinedButton.icon(
          onPressed: isPrinting || isSaving ? null : onPrint,
          icon: isPrinting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.print_outlined),
          label: Text(isPrinting ? 'Printing...' : 'Print Bill'),
        ),
        if (isOpen)
          FilledButton(
            onPressed: !hasItems || isSaving ? null : onClose,
            child: const Text('Close Order'),
          ),
      ];
      return Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          for (final button in buttons)
            SizedBox(width: width, height: 54, child: button),
        ],
      );
    },
  );
}

enum _ItemTab { products, combos }

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.products, required this.onTap});
  final List<Product> products;
  final ValueChanged<Product> onTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => GridView.builder(
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 225,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 118,
      ),
      itemBuilder: (context, index) {
        final product = products[index];
        return MenuItemTile(
          name: product.name,
          price: product.price,
          onTap: () => onTap(product),
        );
      },
    ),
  );
}

class _ComboGrid extends StatelessWidget {
  const _ComboGrid({required this.combos, required this.onTap});
  final List<Combo> combos;
  final ValueChanged<Combo> onTap;

  @override
  Widget build(BuildContext context) {
    if (combos.isEmpty) {
      return const Center(child: Text('No combos available.'));
    }
    return LayoutBuilder(
      builder: (context, constraints) => GridView.builder(
        itemCount: combos.length,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 225,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          mainAxisExtent: 118,
        ),
        itemBuilder: (context, index) {
          final combo = combos[index];
          return MenuItemTile(
            name: combo.name,
            price: combo.price,
            onTap: () => onTap(combo),
          );
        },
      ),
    );
  }
}

class _DetailItemRow extends StatelessWidget {
  const _DetailItemRow({
    required this.item,
    required this.editable,
    required this.onIncrease,
    required this.onDecrease,
  });
  final OrderItem item;
  final bool editable;
  final ValueChanged<OrderItem> onIncrease;
  final ValueChanged<OrderItem> onDecrease;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final information = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.productName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            item.isComplementary
                ? 'COMPLIMENTARY • ₹0'
                : '${formatCurrency(item.unitPrice)} each',
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      );
      final controls = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (editable)
            IconButton.filledTonal(
              onPressed: () => onDecrease(item),
              icon: const Icon(Icons.remove),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '${item.quantity}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (editable)
            IconButton.filledTonal(
              onPressed: () => onIncrease(item),
              icon: const Icon(Icons.add),
            ),
        ],
      );
      final price = Text(
        formatCurrency(item.total),
        textAlign: TextAlign.end,
        style: const TextStyle(fontWeight: FontWeight.w700),
      );
      if (constraints.maxWidth < 430) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            information,
            const SizedBox(height: 8),
            Row(children: [controls, const Spacer(), price]),
          ],
        );
      }
      return Row(
        children: [
          Expanded(child: information),
          controls,
          const SizedBox(width: 14),
          SizedBox(width: 76, child: price),
        ],
      );
    },
  );
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.prominent = false,
  });
  final String label;
  final double value;
  final bool prominent;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: prominent ? 18 : 14,
              fontWeight: prominent ? FontWeight.w700 : null,
            ),
          ),
        ),
        Text(
          formatCurrency(value),
          style: TextStyle(
            fontSize: prominent ? 21 : 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}
