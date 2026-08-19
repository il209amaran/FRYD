import 'package:flutter/foundation.dart';

import '../../../models/combo.dart';
import '../../billing/presentation/current_order_controller.dart';
import '../data/combo_repository.dart';

class CombosController extends ChangeNotifier {
  CombosController({required this.currentOrder, ComboRepository? repository})
    : _repository = repository ?? SqliteComboRepository() {
    currentOrder.addListener(notifyListeners);
  }

  final CurrentOrderController currentOrder;
  final ComboRepository _repository;
  List<Combo> _combos = const [];
  bool _isLoading = true;
  String? _errorMessage;

  List<Combo> get combos => List.unmodifiable(_combos);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _combos = await _repository.getCombos();
    } catch (_) {
      _errorMessage = 'Combos could not be loaded.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addToOrder(Combo combo) => currentOrder.addCombo(combo);

  Future<void> save({
    Combo? existing,
    required String name,
    required double price,
  }) async {
    final now = DateTime.now();
    if (existing == null) {
      await _repository.createCombo(
        Combo(name: name.trim(), price: price, createdAt: now, updatedAt: now),
      );
    } else {
      await _repository.updateCombo(
        existing.copyWith(name: name.trim(), price: price, updatedAt: now),
      );
    }
    await load();
  }

  Future<void> delete(Combo combo) async {
    if (combo.id == null) return;
    await _repository.deleteCombo(combo.id!);
    await load();
  }

  @override
  void dispose() {
    currentOrder.removeListener(notifyListeners);
    super.dispose();
  }
}
