import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_manager.dart';
import '../../../models/business_settings.dart';

class BusinessSettingsRepository {
  BusinessSettingsRepository({DatabaseManager? databaseManager})
    : _databaseManager = databaseManager ?? DatabaseManager.instance;

  final DatabaseManager _databaseManager;
  static final _changes = StreamController<BusinessSettings>.broadcast();
  static Stream<BusinessSettings> get changes => _changes.stream;

  Future<BusinessSettings> get() async {
    final database = await _databaseManager.database;
    final rows = await database.query(
      'business_settings',
      where: 'id = 1',
      limit: 1,
    );
    if (rows.isEmpty) throw StateError('Business settings are unavailable.');
    return BusinessSettings.fromMap(rows.single);
  }

  Future<void> save(BusinessSettings settings) async {
    final database = await _databaseManager.database;
    await database.insert(
      'business_settings',
      settings.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _changes.add(settings);
  }
}
