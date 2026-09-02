import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_manager.dart';

class ComplementSettingsRepository {
  ComplementSettingsRepository({DatabaseManager? databaseManager})
    : _databaseManager = databaseManager ?? DatabaseManager.instance;

  static const _key = 'complements_enabled';
  static final _changes = StreamController<bool>.broadcast();

  final DatabaseManager _databaseManager;

  static Stream<bool> get changes => _changes.stream;

  Future<bool> isEnabled() async {
    final database = await _databaseManager.database;
    final rows = await database.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [_key],
      limit: 1,
    );
    return rows.isEmpty || rows.single['value'] != '0';
  }

  Future<void> setEnabled(bool enabled) async {
    final database = await _databaseManager.database;
    await database.insert('settings', {
      'key': _key,
      'value': enabled ? '1' : '0',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    _changes.add(enabled);
  }
}
