import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/menu_item_tile.dart';
import '../../../core/constants/responsive_breakpoints.dart';
import '../../../models/combo.dart';
import '../../../models/category.dart';
import '../../../models/complement.dart';
import '../../../models/order_item.dart';
import '../../../models/product.dart';
import '../../combos/presentation/combo_management_screen.dart';
import '../../combos/presentation/combos_controller.dart';
import '../../settings/data/combo_settings_repository.dart';
import 'billing_controller.dart';
import 'current_order_controller.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({
    required this.currentOrder,
    required this.onOrderCompleted,
    super.key,
  });

  final CurrentOrderController currentOrder;
  final VoidCallback onOrderCompleted;

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  late final BillingController _controller;
  late final CombosController _combosController;
  late final Listenable _pageListenable;
  bool _showCombos = false;
  bool _groupByCategory = false;
  _BillingPane _compactPane = _BillingPane.items;
  final _comboSettings = ComboSettingsRepository();
  late final StreamSubscription<bool> _comboSettingsChanges;
  bool _combosEnabled = false;

  @override
  void initState() {
    super.initState();
    _controller = BillingController(currentOrder: widget.currentOrder)
      ..loadProducts();
    _combosController = CombosController(currentOrder: widget.currentOrder)
      ..load();
    _pageListenable = Listenable.merge([_controller, _combosController]);
    _comboSettingsChanges = ComboSettingsRepository.changes.listen(
      _applyComboSetting,
    );
    _loadComboSetting();
  }

  Future<void> _loadComboSetting() async {
    try {
      final enabled = await _comboSettings.isEnabled();
      if (mounted) _applyComboSetting(enabled);
    } catch (_) {
      // Keep combos disabled while local settings initialize.
    }
  }

  void _applyComboSetting(bool enabled) {
    if (!mounted) return;
    setState(() {
      _combosEnabled = enabled;
      if (!enabled) _showCombos = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _combosController.dispose();
    _comboSettingsChanges.cancel();
    super.dispose();
  }

  Future<void> _manageCombos() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ComboManagementScreen(controller: _combosController),
      ),
    );
    await _combosController.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _pageListenable,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final sideBySide = ResponsiveBreakpoints.isWide(constraints.maxWidth);
          final usePaneSwitcher =
              ResponsiveBreakpoints.isMobile(constraints.maxWidth) ||
              constraints.maxHeight < 600;
          final orderWidth = (constraints.maxWidth * 0.34).clamp(300.0, 410.0);
          final menu = _MenuArea(
            controller: _controller,
            combosController: _combosController,
            showAddFeedback: usePaneSwitcher,
            showCombos: _showCombos,
            combosEnabled: _combosEnabled,
            groupByCategory: _groupByCategory,
            onShowCombos: () => setState(() => _showCombos = true),
            onShowProducts: () => setState(() => _showCombos = false),
            onGroupingChanged: (value) =>
                setState(() => _groupByCategory = value),
            onManageCombos: _manageCombos,
          );
          final order = CurrentOrderPanel(
            controller: widget.currentOrder,
            onOrderCompleted: widget.onOrderCompleted,
          );
          if (usePaneSwitcher) {
            return Column(
              children: [
                _BillingPaneSwitcher(
                  selected: _compactPane,
                  itemCount: widget.currentOrder.items.length,
                  onChanged: (pane) => setState(() => _compactPane = pane),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _compactPane == _BillingPane.items ? menu : order,
                ),
              ],
            );
          }
          if (!sideBySide) {
            return Column(
              children: [
                Expanded(flex: 3, child: menu),
                const Divider(height: 1),
                Expanded(flex: 2, child: order),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: menu),
              SizedBox(width: orderWidth, child: order),
            ],
          );
        },
      ),
    );
  }
}

enum _BillingPane { items, order }

class _BillingPaneSwitcher extends StatelessWidget {
  const _BillingPaneSwitcher({
    required this.selected,
    required this.itemCount,
    required this.onChanged,
  });

  final _BillingPane selected;
  final int itemCount;
  final ValueChanged<_BillingPane> onChanged;

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<_BillingPane>(
          expandedInsets: EdgeInsets.zero,
          segments: [
            const ButtonSegment(
              value: _BillingPane.items,
              icon: Icon(Icons.restaurant_menu),
              label: Text('Items'),
            ),
            ButtonSegment(
              value: _BillingPane.order,
              icon: const Icon(Icons.receipt_long_outlined),
              label: Text('Current Order ($itemCount)'),
            ),
          ],
          selected: {selected},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => onChanged(selection.single),
        ),
      ),
    ),
  );
}

class _MenuArea extends StatelessWidget {
  const _MenuArea({
    required this.controller,
    required this.combosController,
    required this.showAddFeedback,
    required this.showCombos,
    required this.combosEnabled,
    required this.groupByCategory,
    required this.onShowCombos,
    required this.onShowProducts,
    required this.onGroupingChanged,
    required this.onManageCombos,
  });
  final BillingController controller;
  final CombosController combosController;
  final bool showAddFeedback;
  final bool showCombos;
  final bool combosEnabled;
  final bool groupByCategory;
  final VoidCallback onShowCombos;
  final VoidCallback onShowProducts;
  final ValueChanged<bool> onGroupingChanged;
  final VoidCallback onManageCombos;

  void _addProduct(BuildContext context, Product product) {
    controller.addProduct(product);
    if (!showAddFeedback) return;

    final quantity = controller.orderItems
        .where(
          (item) =>
              item.itemType == OrderItemType.product &&
              (product.id != null
                  ? item.productId == product.id
                  : item.productName == product.name),
        )
        .first
        .quantity;
    final message = quantity == 1
        ? '${product.name} added to the order'
        : '$quantity ${product.name} added to the current order';
    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        duration: const Duration(milliseconds: 500),
        behavior: SnackBarBehavior.floating,
        width: (MediaQuery.sizeOf(context).width - 32).clamp(0, 360).toDouble(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mobile = ResponsiveBreakpoints.isMobile(
      MediaQuery.sizeOf(context).width,
    );
    return Padding(
      padding: mobile
          ? const EdgeInsets.fromLTRB(12, 12, 12, 10)
          : const EdgeInsets.fromLTRB(24, 22, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Create order',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const Icon(Icons.wifi_off_rounded, size: 18, color: Colors.green),
              const SizedBox(width: 6),
              const Text(
                'Offline',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (showCombos)
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onShowProducts,
                  icon: const Icon(Icons.restaurant_menu),
                  label: const Text('All Products'),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onManageCombos,
                  icon: const Icon(Icons.tune),
                  label: const Text('Add / Update Combos'),
                ),
              ],
            )
          else if (!controller.isLoading && controller.errorMessage == null)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: controller.selectedCategoryId == null,
                          onSelected: (_) => controller.selectCategory(null),
                          showCheckmark: false,
                        ),
                        for (final category in controller.categories) ...[
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Text(category.name),
                            selected:
                                controller.selectedCategoryId == category.id,
                            onSelected: (_) =>
                                controller.selectCategory(category.id),
                            showCheckmark: false,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (combosEnabled)
                  OutlinedButton.icon(
                    onPressed: onShowCombos,
                    icon: const Icon(Icons.fastfood),
                    label: const Text('Combos'),
                  ),
              ],
            ),
          if (!showCombos &&
              !controller.isLoading &&
              controller.errorMessage == null &&
              controller.selectedCategoryId == null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'View:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 10),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('A–Z')),
                    ButtonSegment(
                      value: true,
                      label: Text('By Category'),
                      icon: Icon(Icons.view_list_outlined),
                    ),
                  ],
                  selected: {groupByCategory},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) =>
                      onGroupingChanged(selection.single),
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Expanded(
            child: showCombos
                ? _ComboMenu(controller: combosController)
                : controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : controller.errorMessage != null &&
                      controller.visibleProducts.isEmpty
                ? Center(
                    child: OutlinedButton.icon(
                      onPressed: controller.loadProducts,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reload products'),
                    ),
                  )
                : controller.visibleProducts.isEmpty
                ? _EmptyMenu(
                    categorySelected: controller.selectedCategoryId != null,
                  )
                : groupByCategory && controller.selectedCategoryId == null
                ? _GroupedProductMenu(
                    categories: controller.categories,
                    products: controller.visibleProducts,
                    onTap: (product) => _addProduct(context, product),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return GridView.builder(
                        itemCount: controller.visibleProducts.length,
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 225,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              mainAxisExtent: 118,
                            ),
                        itemBuilder: (context, index) => _ProductCard(
                          product: controller.visibleProducts[index],
                          onTap: (product) => _addProduct(context, product),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _GroupedProductMenu extends StatelessWidget {
  const _GroupedProductMenu({
    required this.categories,
    required this.products,
    required this.onTap,
  });

  final List<Category> categories;
  final List<Product> products;
  final ValueChanged<Product> onTap;

  @override
  Widget build(BuildContext context) {
    final populatedCategories = categories
        .where(
          (category) =>
              products.any((product) => product.category.id == category.id),
        )
        .toList(growable: false);
    return ListView.builder(
      itemCount: populatedCategories.length,
      itemBuilder: (context, index) {
        final category = populatedCategories[index];
        final categoryProducts = products
            .where((product) => product.category.id == category.id)
            .toList(growable: false);
        return Padding(
          padding: const EdgeInsets.only(bottom: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.name.toString().toUpperCase(),
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.8),
              ),
              const Divider(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categoryProducts.length,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 225,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 118,
                ),
                itemBuilder: (context, productIndex) => _ProductCard(
                  product: categoryProducts[productIndex],
                  onTap: onTap,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ComboMenu extends StatelessWidget {
  const _ComboMenu({required this.controller});
  final CombosController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.errorMessage != null) {
      return Center(
        child: OutlinedButton.icon(
          onPressed: controller.load,
          icon: const Icon(Icons.refresh),
          label: const Text('Reload combos'),
        ),
      );
    }
    if (controller.combos.isEmpty) {
      return const Center(child: Text('No combos available.'));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          itemCount: controller.combos.length,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 225,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 118,
          ),
          itemBuilder: (context, index) => _ComboCard(
            combo: controller.combos[index],
            onTap: controller.addToOrder,
          ),
        );
      },
    );
  }
}

class _ComboCard extends StatelessWidget {
  const _ComboCard({required this.combo, required this.onTap});
  final Combo combo;
  final ValueChanged<Combo> onTap;

  @override
  Widget build(BuildContext context) => MenuItemTile(
    name: combo.name,
    price: combo.price,
    onTap: () => onTap(combo),
  );
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});
  final Product product;
  final ValueChanged<Product> onTap;

  @override
  Widget build(BuildContext context) {
    return MenuItemTile(
      name: product.name,
      price: product.price,
      onTap: () => onTap(product),
    );
  }
}

class _EmptyMenu extends StatelessWidget {
  const _EmptyMenu({required this.categorySelected});

  final bool categorySelected;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.restaurant_menu, size: 54, color: Colors.black26),
        const SizedBox(height: 12),
        Text(
          categorySelected
              ? 'No products available in this category.'
              : 'No menu items available',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        if (!categorySelected) ...[
          const SizedBox(height: 4),
          const Text(
            'Create products from the Products section.',
            style: TextStyle(color: Colors.black45),
          ),
        ],
      ],
    ),
  );
}

class CurrentOrderPanel extends StatelessWidget {
  const CurrentOrderPanel({
    required this.controller,
    required this.onOrderCompleted,
    super.key,
  });
  final CurrentOrderController controller;
  final VoidCallback onOrderCompleted;

  Future<void> _complete(BuildContext context) async {
    final completed = await controller.completeOrder();
    if (!context.mounted) return;
    if (completed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order created and saved as OPEN.')),
      );
      onOrderCompleted();
    } else if (controller.errorMessage != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(controller.errorMessage!)));
    }
  }

  Future<void> _selectComplement(BuildContext context) async {
    int? selectedId = controller.complementaryItem?.complementId;
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      for (final complement in controller.eligibleComplements)
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
                      controller.eligibleComplements.firstWhere(
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
      controller.selectComplement(selected);
    } else {
      controller.endComplementSelection();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 700;
    if (controller.shouldPromptComplementSelection &&
        !controller.selectionDialogOpen) {
      controller.beginComplementSelection();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) _selectComplement(context);
      });
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final shortWindow = constraints.maxHeight < 400;
        return ColoredBox(
          color: Colors.white,
          child: Padding(
            padding: shortWindow
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
                : mobile
                ? const EdgeInsets.fromLTRB(12, 10, 12, 10)
                : const EdgeInsets.fromLTRB(20, 22, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current order',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  '${controller.items.length} items',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: Colors.black54),
                ),
                Divider(height: shortWindow ? 12 : 28),
                Expanded(
                  child: controller.items.isEmpty
                      ? _EmptyOrder(compact: shortWindow)
                      : ListView.separated(
                          itemCount: controller.items.length,
                          separatorBuilder: (_, _) => const Divider(height: 22),
                          itemBuilder: (context, index) => _OrderRow(
                            item: controller.items[index],
                            controller: controller,
                          ),
                        ),
                ),
                Divider(height: shortWindow ? 12 : 24),
                if (controller.requiresComplementSelection) ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      controller.beginComplementSelection();
                      _selectComplement(context);
                    },
                    icon: const Icon(Icons.redeem),
                    label: const Text('Select Complement'),
                  ),
                  const SizedBox(height: 8),
                ],
                if (controller.canChangeComplement) ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      controller.beginComplementSelection();
                      _selectComplement(context);
                    },
                    icon: const Icon(Icons.redeem),
                    label: const Text('Change Complement'),
                  ),
                  const SizedBox(height: 8),
                ],
                _TotalRow(label: 'Subtotal', value: controller.subtotal),
                if (controller.taxAmount > 0)
                  _TotalRow(
                    label: controller.taxLabel,
                    value: controller.taxAmount,
                  ),
                SizedBox(height: shortWindow ? 2 : 8),
                _TotalRow(
                  label: 'Grand total',
                  value: controller.total,
                  prominent: true,
                ),
                SizedBox(height: shortWindow ? 6 : 16),
                SizedBox(
                  width: double.infinity,
                  height: shortWindow ? 46 : 58,
                  child: FilledButton.icon(
                    onPressed:
                        controller.items.isEmpty || controller.isCompleting
                        ? null
                        : () => _complete(context),
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(
                      controller.isCompleting
                          ? 'Completing…'
                          : 'Complete Order',
                      style: TextStyle(
                        fontSize: shortWindow ? 16 : 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyOrder extends StatelessWidget {
  const _EmptyOrder({this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!compact) ...[
          const Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: Colors.black26,
          ),
          const SizedBox(height: 12),
        ],
        const Text(
          'Your order is empty',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        if (!compact) ...[
          const SizedBox(height: 4),
          const Text(
            'Tap a menu item to add it',
            style: TextStyle(color: Colors.black45),
          ),
        ],
      ],
    ),
  );
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.item, required this.controller});
  final OrderItem item;
  final CurrentOrderController controller;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.productName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            if (item.isComplementary)
              Row(
                children: [
                  Chip(
                    label: const Text('COMPLIMENTARY'),
                    visualDensity: VisualDensity.compact,
                    labelStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formatCurrency(0),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            else
              Text(
                '${formatCurrency(item.unitPrice)} each  •  ${formatCurrency(item.total)}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
      if (!item.isComplementary) ...[
        _QuantityButton(
          icon: Icons.remove,
          onPressed: () => controller.decrease(item),
        ),
        SizedBox(
          width: 32,
          child: Center(
            child: Text(
              '${item.quantity}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        _QuantityButton(
          icon: Icons.add,
          onPressed: () => controller.increase(item),
        ),
      ],
    ],
  );
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 40,
    child: IconButton.filledTonal(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      padding: EdgeInsets.zero,
    ),
  );
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
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
              fontWeight: prominent ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
        Text(
          formatCurrency(value),
          style: TextStyle(
            fontSize: prominent ? 22 : 14,
            fontWeight: prominent ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
