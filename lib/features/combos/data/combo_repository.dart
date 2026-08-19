import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_manager.dart';
import '../../../models/combo.dart';

class DuplicateComboException implements Exception {
  const DuplicateComboException();
}

abstract interface class ComboRepository {
  Future<List<Combo>> getCombos();
  Future<Combo> createCombo(Combo combo);
  Future<void> updateCombo(Combo combo);
  Future<void> deleteCombo(int id);
}

class SqliteComboRepository implements ComboRepository {
  SqliteComboRepository({DatabaseManager? databaseManager})
    : _databaseManager = databaseManager ?? DatabaseManager.instance;

  final DatabaseManager _databaseManager;

  @override
  Future<List<Combo>> getCombos() async {
    final database = await _databaseManager.database;
    final rows = await database.query('combos', orderBy: 'name COLLATE NOCASE');
    return rows.map(Combo.fromMap).toList(growable: false);
  }

  @override
  Future<Combo> createCombo(Combo combo) async {
    final database = await _databaseManager.database;
    try {
      final id = await database.insert('combos', combo.toMap(includeId: false));
      return combo.copyWith(id: id);
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) {
        throw const DuplicateComboException();
      }
      rethrow;
    }
  }

  @override
  Future<void> updateCombo(Combo combo) async {
    final id = combo.id;
    if (id == null) throw ArgumentError('A combo ID is required.');
    final database = await _databaseManager.database;
    try {
      await database.update(
        'combos',
        combo.toMap(includeId: false),
        where: 'id = ?',
        whereArgs: [id],
      );
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) {
        throw const DuplicateComboException();
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteCombo(int id) async {
    final database = await _databaseManager.database;
    await database.delete('combos', where: 'id = ?', whereArgs: [id]);
  }
}
