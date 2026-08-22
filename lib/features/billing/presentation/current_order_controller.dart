import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/services/tax_calculator.dart';
import '../../../models/business_settings.dart';
import '../../../models/combo.dart';
import '../../../models/complement.dart';
import '../../../models/order_item.dart';
import '../../../models/product.dart';
import '../../orders/data/order_repository.dart';
import '../../complements/services/complement_eligibility_service.dart';
import '../../business/data/business_settings_repository.dart';

class CurrentOrderController extends ChangeNotifier {
  CurrentOrderController({
    OrderRepository? repository,
    ComplementEligibilityService? complementService,
  }) : _repository = repository ?? SqliteOrderRepository(),
       _complementService = complementService ?? ComplementEligibilityService();

  final OrderRepository _repository;
  final ComplementEligibilityService _complementService;
  final Map<String, OrderItem> _items = {};
  bool _isCompleting = false;
  String? _errorMessage;
  List<Complement> _eligibleComplements = const [];
  bool _selectionDialogOpen = false;
  bool _selectionDismissed = false;
  int _evaluationVersion = 0;
  Future<void>? _evaluation;
  BusinessSettings? _businessSettings;
  late final StreamSubscription<BusinessSettings> _settingsChanges =
      BusinessSettingsRepository.changes.listen((settings) {
        _businessSettings = settings;
        notifyListeners();
      });

  Future<void> initialize() async {
    try {
      _businessSettings = await BusinessSettingsRepository().get();
      notifyListeners();
    } catch (_) {
      // Startup/database errors are surfaced by the owning screen; the order
      // remains usable with its safe no-tax fallback while initialization runs.
    }
  }

  List<OrderItem> get items => List.unmodifiable([
    ..._items.values.where((item) => !item.isComplementary),
    ..._items.values.where((item) => item.isComplementary),
  ]);
  bool get isCompleting => _isCompleting;
  String? get errorMessage => _errorMessage;
  List<Complement> get eligibleComplements =>
      List.unmodifiable(_eligibleComplements);
  OrderItem? get complementaryItem =>
      _items.values.where((item) => item.isComplementary).firstOrNull;
  bool get requiresComplementSelection =>
      complementaryItem == null && _eligibleComplements.length > 1;
  bool get shouldPromptComplementSelection =>
      requiresComplementSelection && !_selectionDismissed;
  bool get canChangeComplement =>
      complementaryItem != null && _eligibleComplements.length > 1;
  bool get selectionDialogOpen => _selectionDialogOpen;
  double get subtotal => _items.values
      .where((item) => !item.isComplementary)
      .fold(0, (sum, item) => sum + item.total);
  TaxCalculation get calculation => _businessSettings == null
      ? TaxCalculation(
          subtotal: subtotal,
          taxName: 'Tax',
          taxRate: 0,
          taxAmount: 0,
          total: subtotal,
        )
      : TaxCalculator.calculate(subtotal, _businessSettings!);
  double get taxAmount => calculation.taxAmount;
  String get taxLabel => calculation.taxRate == 0
      ? calculation.taxName
      : '${calculation.taxName} ${calculation.taxRate.toStringAsFixed(calculation.taxRate == calculation.taxRate.roundToDouble() ? 0 : 2)}%';
  double get total => calculation.total;

  String _key(OrderItem item) =>
      '${item.itemType.databaseValue}:${item.productId ?? item.comboId ?? item.complementId}';

  void addProduct(Product product) => _add(OrderItem.fromProduct(product));
  void addCombo(Combo combo) => _add(OrderItem.fromCombo(combo));

  void _add(OrderItem item) {
    final key = _key(item);
    final current = _items[key];
    _items[key] = current == null
        ? item
        : current.copyWith(quantity: current.quantity + 1);
    notifyListeners();
    _scheduleEvaluation();
  }

  void increase(OrderItem item) {
    if (item.isComplementary) return;
    _items[_key(item)] = item.copyWith(quantity: item.quantity + 1);
    notifyListeners();
    _scheduleEvaluation();
  }

  void decrease(OrderItem item) {
    if (item.isComplementary) return;
    final key = _key(item);
    if (item.quantity == 1) {
      _items.remove(key);
    } else {
      _items[key] = item.copyWith(quantity: item.quantity - 1);
    }
    notifyListeners();
    _scheduleEvaluation();
  }

  void selectComplement(Complement complement) {
    _items.removeWhere((_, item) => item.isComplementary);
    final item = OrderItem.fromComplement(complement);
    _items[_key(item)] = item;
    _selectionDialogOpen = false;
    _selectionDismissed = false;
    notifyListeners();
  }

  void beginComplementSelection() {
    _selectionDialogOpen = true;
  }

  void endComplementSelection() {
    _selectionDialogOpen = false;
    _selectionDismissed = true;
    notifyListeners();
  }

  void _scheduleEvaluation() {
    _selectionDismissed = false;
    final version = ++_evaluationVersion;
    _evaluation = _evaluateComplements(version);
  }

  Future<void> _evaluateComplements(int version) async {
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
      if (!currentIsValid) {
        _items.removeWhere((_, item) => item.isComplementary);
        if (result.automatic case final complement?) {
          final item = OrderItem.fromComplement(complement);
          _items[_key(item)] = item;
        }
      }
      notifyListeners();
    } catch (_) {
      if (version == _evaluationVersion) {
        _eligibleComplements = const [];
        notifyListeners();
      }
    }
  }

  Future<bool> completeOrder() async {
    if (_items.isEmpty || _isCompleting) return false;
    _isCompleting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _evaluation;
      if (requiresComplementSelection) {
        _errorMessage =
            'Select a complimentary item before completing the order.';
        return false;
      }
      await _repository.createOrder(items);
      _items.clear();
      _eligibleComplements = const [];
      return true;
    } catch (_) {
      _errorMessage = requiresComplementSelection
          ? 'Select a complimentary item before completing the order.'
          : 'Order could not be completed. Please try again.';
      return false;
    } finally {
      _isCompleting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _settingsChanges.cancel();
    super.dispose();
  }
}
