import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_manager.dart';
import '../../../models/complement.dart';

class DuplicateComplementException implements Exception {
  const DuplicateComplementException();
}

abstract interface class ComplementRepository {
  Future<List<Complement>> getComplements();
  Future<List<Complement>> getEligibleComplements(double paidTotal);
  Future<Complement> createComplement(Complement complement);
  Future<void> updateComplement(Complement complement);
  Future<void> deleteComplement(int id);
}

class SqliteComplementRepository implements ComplementRepository {
  SqliteComplementRepository({DatabaseManager? databaseManager})
    : _databaseManager = databaseManager ?? DatabaseManager.instance;

  final DatabaseManager _databaseManager;

  @override
  Future<List<Complement>> getComplements() async {
    final database = await _databaseManager.database;
    final rows = await database.query(
      'complements',
      orderBy: 'minimum_order_value, name COLLATE NOCASE',
    );
    return rows.map(Complement.fromMap).toList(growable: false);
  }

  @override
  Future<List<Complement>> getEligibleComplements(double paidTotal) async {
    final database = await _databaseManager.database;
    final rows = await database.query(
      'complements',
      where: 'minimum_order_value <= ?',
      whereArgs: [paidTotal],
      orderBy: 'minimum_order_value, name COLLATE NOCASE',
    );
    return rows.map(Complement.fromMap).toList(growable: false);
  }

  @override
  Future<Complement> createComplement(Complement complement) async {
    final database = await _databaseManager.database;
    try {
      final id = await database.insert(
        'complements',
        complement.toMap(includeId: false),
      );
      return complement.copyWith(id: id);
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) {
        throw const DuplicateComplementException();
      }
      rethrow;
    }
  }

  @override
  Future<void> updateComplement(Complement complement) async {
    final id = complement.id;
    if (id == null) throw ArgumentError('A complement ID is required.');
    final database = await _databaseManager.database;
    try {
      await database.update(
        'complements',
        complement.toMap(includeId: false),
        where: 'id = ?',
        whereArgs: [id],
      );
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) {
        throw const DuplicateComplementException();
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteComplement(int id) async {
    final database = await _databaseManager.database;
    await database.delete('complements', where: 'id = ?', whereArgs: [id]);
  }
}
