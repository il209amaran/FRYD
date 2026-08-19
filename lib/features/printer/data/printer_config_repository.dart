import '../../../core/database/database_manager.dart';
import '../models/printer_config.dart';

class PrinterConfigRepository {
  PrinterConfigRepository({DatabaseManager? databaseManager})
    : _databaseManager = databaseManager ?? DatabaseManager.instance;

  static const _nameKey = 'printer_name';
  static const _addressKey = 'printer_address';
  static const _typeKey = 'printer_type';

  final DatabaseManager _databaseManager;

  Future<PrinterConfig?> getSelectedPrinter() async {
    final database = await _databaseManager.database;
    final rows = await database.query(
      'settings',
      where: 'key IN (?, ?)',
      whereArgs: [_nameKey, _addressKey],
    );
    final values = <String, String>{
      for (final row in rows) row['key'] as String: row['value'] as String,
    };
    final name = values[_nameKey];
    final address = values[_addressKey];
    if (name == null || address == null || address.isEmpty) return null;
    return PrinterConfig(name: name, address: address);
  }

  Future<void> saveSelectedPrinter(PrinterConfig config) async {
    final database = await _databaseManager.database;
    await database.transaction((transaction) async {
      for (final entry in {
        _nameKey: config.name,
        _addressKey: config.address,
        _typeKey: 'BLUETOOTH_ESC_POS',
      }.entries) {
        await transaction.insert('settings', {
          'key': entry.key,
          'value': entry.value,
        }, conflictAlgorithm: .replace);
      }
    });
  }
}
