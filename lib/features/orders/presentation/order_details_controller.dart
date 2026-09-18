import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../models/combo.dart';
import '../../../models/business_settings.dart';
import '../../../models/complement.dart';
import '../../../models/order.dart';
import '../../../models/order_item.dart';
import '../../../models/product.dart';
import '../../../models/payment_method.dart';
import '../../../core/services/tax_calculator.dart';
import '../../business/data/business_settings_repository.dart';
import '../../payments/data/payment_method_repository.dart';
import '../../combos/data/combo_repository.dart';
import '../../complements/services/complement_eligibility_service.dart';
import '../../products/data/product_repository.dart';
import '../../settings/data/complement_settings_repository.dart';
import '../data/order_repository.dart';

class OrderDetailsController extends ChangeNotifier {
  OrderDetailsController({
    required this.orderId,
    ProductRepository? productRepository,
    ComboRepository? comboRepository,
    ComplementEligibilityService? complementService,
    OrderRepository? orderRepository,
    PaymentMethodRepository? paymentMethodRepository,
    ComplementSettingsRepository? complementSettingsRepository,
  }) : _productRepository = productRepository ?? SqliteProductRepository(),
       _comboRepository = comboRepository ?? SqliteComboRepository(),
       _complementService = complementService ?? ComplementEligibilityService(),
       _orderRepository = orderRepository ?? SqliteOrderRepository(),
       _paymentMethodRepository =
           paymentMethodRepository ?? PaymentMethodRepository(),
       _complementSettingsRepository =
           complementSettingsRepository ?? ComplementSettingsRepository() {
    _complementSettingsChanges = ComplementSettingsRepository.changes.listen(
      _applyComplementSetting,
    );
  }

  final int orderId;
  final ProductRepository _productRepository;
  final ComboRepository _comboRepository;
  final ComplementEligibilityService _complementService;
  final OrderRepository _orderRepository;
  final PaymentMethodRepository _paymentMethodRepository;
  final ComplementSettingsRepository _complementSettingsRepository;
  final Map<String, OrderItem> _items = {};
  RestaurantOrder? _order;
  List<Product> _products = const [];
  List<Combo> _combos = const [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDirty = false;
  String? _errorMessage;
  List<Complement> _eligibleComplements = const [];
  bool _selectionDialogOpen = false;
  bool _selectionDismissed = false;
  int _evaluationVersion = 0;
  Future<void>? _evaluation;
  BusinessSettings? _businessSettings;
  List<PaymentMethod> _paymentMethods = const [];
  bool _complementsEnabled = false;
  late final StreamSubscription<bool> _complementSettingsChanges;

  RestaurantOrder? get order => _order;
  List<Product> get products => List.unmodifiable(_products);
  List<Combo> get combos => List.unmodifiable(_combos);
  List<OrderItem> get items {
    final visibleItems = _complementsEnabled
        ? _items.values
        : _items.values.where((item) => !item.isComplementary);
    return List.unmodifiable([
      ...visibleItems.where((item) => !item.isComplementary),
      ...visibleItems.where((item) => item.isComplementary),
    ]);
  }

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isDirty => _isDirty;
  String? get errorMessage => _errorMessage;
  List<Complement> get eligibleComplements =>
      List.unmodifiable(_eligibleComplements);
  OrderItem? get complementaryItem =>
      _items.values.where((item) => item.isComplementary).firstOrNull;
  bool get requiresComplementSelection =>
      _complementsEnabled &&
      canEdit &&
      complementaryItem == null &&
      _eligibleComplements.length > 1;
  bool get shouldPromptComplementSelection =>
      requiresComplementSelection && !_selectionDismissed;
  bool get canChangeComplement =>
      _complementsEnabled &&
      canEdit &&
      complementaryItem != null &&
      _eligibleComplements.length > 1;
  bool get selectionDialogOpen => _selectionDialogOpen;
  bool get canEdit => _order?.isOpen ?? false;
  List<PaymentMethod> get paymentMethods => List.unmodifiable(_paymentMethods);
  double get subtotal => _items.values
      .where((item) => !item.isComplementary)
      .fold(0, (sum, item) => sum + item.total);
  TaxCalculation get calculation {
    final order = _order;
    if (order != null && !order.isOpen) {
      return TaxCalculation(
        subtotal: order.subtotal,
        taxName: order.taxName,
        taxRate: order.taxRate,
        taxAmount: order.taxAmount,
        total: order.total,
      );
    }
    final settings = _businessSettings;
    return settings == null
        ? TaxCalculation(
            subtotal: subtotal,
            taxName: 'Tax',
            taxRate: 0,
            taxAmount: 0,
            total: subtotal,
          )
        : TaxCalculator.calculate(subtotal, settings);
  }

  double get taxAmount => calculation.taxAmount;
  double get total => calculation.total;
  String get taxLabel => calculation.taxRate == 0
      ? calculation.taxName
      : '${calculation.taxName} ${calculation.taxRate.toStringAsFixed(calculation.taxRate == calculation.taxRate.roundToDouble() ? 0 : 2)}%';

  String _key(OrderItem item) =>
      '${item.itemType.databaseValue}:${item.productId ?? item.comboId ?? item.complementId ?? item.id}';

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _orderRepository.getOrder(orderId),
        _orderRepository.getOrderItems(orderId),
        _productRepository.getProducts(),
        _comboRepository.getCombos(),
        BusinessSettingsRepository().get(),
        _paymentMethodRepository.getAll(enabledOnly: true),
        _complementSettingsRepository.isEnabled(),
      ]);
      _order = results[0] as RestaurantOrder;
      final loadedItems = results[1] as List<OrderItem>;
      _products = results[2] as List<Product>;
      _combos = results[3] as List<Combo>;
      _businessSettings = results[4] as BusinessSettings;
      _paymentMethods = results[5] as List<PaymentMethod>;
      _complementsEnabled = results[6] as bool;
      _items
        ..clear()
        ..addEntries(loadedItems.map((item) => MapEntry(_key(item), item)));
      if (!_complementsEnabled && _order!.isOpen) {
        final removed = _removeComplements();
        _isDirty = removed;
      }
      if (_complementsEnabled || !_order!.isOpen) _isDirty = false;
      _errorMessage = null;
      if (_order!.isOpen) _scheduleEvaluation();
    } catch (_) {
      _errorMessage = 'Order details could not be loaded.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addProduct(Product product) {
    if (!canEdit || product.id == null) return;
    final item = OrderItem.fromProduct(product);
    final key = _key(item);
    final current = _items[key];
    _items[key] = current == null
        ? OrderItem.fromProduct(product)
        : current.copyWith(quantity: current.quantity + 1);
    _changed();
  }

  void addCombo(Combo combo) {
    if (!canEdit || combo.id == null) return;
    final item = OrderItem.fromCombo(combo);
    final key = _key(item);
    final current = _items[key];
    _items[key] = current == null
        ? item
        : current.copyWith(quantity: current.quantity + 1);
    _changed();
  }

  void increase(OrderItem item) {
    if (!canEdit) return;
    _items[_key(item)] = item.copyWith(quantity: item.quantity + 1);
    _changed();
  }

  void decrease(OrderItem item) {
    if (!canEdit) return;
    final key = _key(item);
    if (item.quantity == 1) {
      _items.remove(key);
    } else {
      _items[key] = item.copyWith(quantity: item.quantity - 1);
    }
    _changed();
  }

  void _changed() {
    _isDirty = true;
    notifyListeners();
    _scheduleEvaluation();
  }

  void selectComplement(Complement complement) {
    if (!_complementsEnabled) return;
    _items.removeWhere((_, item) => item.isComplementary);
    final item = OrderItem.fromComplement(complement);
    _items[_key(item)] = item;
    _selectionDialogOpen = false;
    _selectionDismissed = false;
    _isDirty = true;
    notifyListeners();
  }

  void beginComplementSelection() => _selectionDialogOpen = true;

  void endComplementSelection() {
    _selectionDialogOpen = false;
    _selectionDismissed = true;
    notifyListeners();
  }

  void _scheduleEvaluation({bool markDirty = true}) {
    if (!_complementsEnabled) {
      final removed = _removeComplements();
      if (removed && markDirty) _isDirty = true;
      notifyListeners();
      return;
    }
    _selectionDismissed = false;
    final version = ++_evaluationVersion;
    _evaluation = _evaluateComplements(version, markDirty: markDirty);
  }

  void _applyComplementSetting(bool enabled) {
    _complementsEnabled = enabled;
    _evaluationVersion++;
    if (!enabled) {
      final removed = canEdit && _removeComplements();
      if (removed) _isDirty = true;
    }
    notifyListeners();
    if (enabled && canEdit) _scheduleEvaluation();
  }

  bool _removeComplements() {
    final hadComplement = _items.values.any((item) => item.isComplementary);
    _items.removeWhere((_, item) => item.isComplementary);
    _eligibleComplements = const [];
    _selectionDialogOpen = false;
    _selectionDismissed = false;
    return hadComplement;
  }

  Future<void> _evaluateComplements(
    int version, {
    required bool markDirty,
  }) async {
    try {
      final current = complementaryItem;
      final result = await _complementService.evaluate(
        paidTotal: subtotal,
        selectedComplementId: current?.complementId,
      );
      if (version != _evaluationVersion) return;
      _eligibleComplements = result.eligible;
      final currentIsValid =
          current != null &&
          result.eligible.any((item) => item.id == current.complementId);
      var changed = false;
      if (!currentIsValid) {
        changed = _items.values.any((item) => item.isComplementary);
        _items.removeWhere((_, item) => item.isComplementary);
        if (result.automatic case final complement?) {
          final item = OrderItem.fromComplement(complement);
          _items[_key(item)] = item;
          changed = true;
        }
      }
      if (changed && markDirty) _isDirty = true;
      notifyListeners();
    } catch (_) {
      if (version == _evaluationVersion) {
        _eligibleComplements = const [];
        notifyListeners();
      }
    }
  }

  Future<bool> saveChanges() async {
    if (!canEdit || items.isEmpty) return false;
    _isSaving = true;
    notifyListeners();
    try {
      await _evaluation;
      if (requiresComplementSelection) {
        _errorMessage = 'Select a complimentary item before saving.';
        _isSaving = false;
        notifyListeners();
        return false;
      }
      await _orderRepository.updateOpenOrder(orderId, items);
      await load();
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Order changes could not be saved.';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> closeOrder(PaymentMethod paymentMethod) async {
    if (!canEdit || items.isEmpty) return false;
    _isSaving = true;
    notifyListeners();
    try {
      await _evaluation;
      if (requiresComplementSelection) {
        _errorMessage = 'Select a complimentary item before closing.';
        _isSaving = false;
        notifyListeners();
        return false;
      }
      // Refresh financial snapshots at payment time so the displayed tax and
      // persisted total are identical even if tax settings changed meanwhile.
      await _orderRepository.updateOpenOrder(orderId, items);
      await _orderRepository.closeOrder(orderId, paymentMethod);
      return true;
    } catch (_) {
      _errorMessage = 'Order could not be closed.';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _complementSettingsChanges.cancel();
    super.dispose();
  }
}
