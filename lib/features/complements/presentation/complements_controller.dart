import 'package:flutter/foundation.dart';

import '../../../models/complement.dart';
import '../data/complement_repository.dart';

class ComplementsController extends ChangeNotifier {
  ComplementsController({ComplementRepository? repository})
    : _repository = repository ?? SqliteComplementRepository();

  final ComplementRepository _repository;
  List<Complement> _items = const [];
  bool _isLoading = true;
  String? _errorMessage;

  List<Complement> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _items = await _repository.getComplements();
      _errorMessage = null;
    } catch (_) {
      _errorMessage = 'Complements could not be loaded.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> save({
    Complement? existing,
    required String name,
    required double minimum,
  }) async {
    final now = DateTime.now();
    if (existing == null) {
      await _repository.createComplement(
        Complement(
          name: name.trim(),
          minimumOrderValue: minimum,
          createdAt: now,
          updatedAt: now,
        ),
      );
    } else {
      await _repository.updateComplement(
        existing.copyWith(
          name: name.trim(),
          minimumOrderValue: minimum,
          updatedAt: now,
        ),
      );
    }
    await load();
  }

  Future<void> delete(Complement complement) async {
    if (complement.id == null) return;
    await _repository.deleteComplement(complement.id!);
    await load();
  }
}
