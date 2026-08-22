import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_manager.dart';
import '../../../models/receipt_settings.dart';

class ReceiptSettingsRepository {
  ReceiptSettingsRepository({DatabaseManager? databaseManager})
    : _databaseManager = databaseManager ?? DatabaseManager.instance;

  final DatabaseManager _databaseManager;

  Future<ReceiptSettings> get() async {
    final database = await _databaseManager.database;
    final rows = await database.query(
      'receipt_settings',
      where: 'id = 1',
      limit: 1,
    );
    if (rows.isEmpty) throw StateError('Receipt settings are unavailable.');
    return ReceiptSettings.fromMap(rows.single);
  }

  Future<void> save(ReceiptSettings settings) async {
    final database = await _databaseManager.database;
    await database.insert(
      'receipt_settings',
      settings.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
