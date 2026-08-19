import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../models/printer_config.dart';

class PrinterException implements Exception {
  const PrinterException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PrinterService {
  Future<List<PrinterConfig>> getPairedPrinters() async {
    await _ensureReady();
    final devices = await PrintBluetoothThermal.pairedBluetooths;
    return devices
        .map(
          (device) => PrinterConfig(
            name: device.name.isEmpty ? 'Bluetooth printer' : device.name,
            address: device.macAdress,
          ),
        )
        .toList(growable: false);
  }

  Future<bool> get isConnected => PrintBluetoothThermal.connectionStatus;

  Future<void> disconnect() async {
    if (await PrintBluetoothThermal.connectionStatus) {
      await PrintBluetoothThermal.disconnect;
    }
  }

  Future<void> printBytes(PrinterConfig printer, List<int> bytes) async {
    await _ensureReady();
    var connected = await PrintBluetoothThermal.connectionStatus;
    if (!connected) {
      connected = await PrintBluetoothThermal.connect(
        macPrinterAddress: printer.address,
      );
    }
    if (!connected) {
      throw const PrinterException(
        'Unable to connect to the printer. Check that it is switched on and paired.',
      );
    }
    if (!await PrintBluetoothThermal.writeBytes(bytes)) {
      throw const PrinterException(
        'Print failed. Please check the printer and try again.',
      );
    }
  }

  Future<void> _ensureReady() async {
    if (!Platform.isAndroid) {
      throw const PrinterException(
        'Bluetooth receipt printing is available on Android tablets.',
      );
    }
    final statuses = await [
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ].request();
    if (statuses.values.any((status) => status.isPermanentlyDenied)) {
      throw const PrinterException(
        'Bluetooth permission is disabled. Enable Nearby devices permission in Android settings.',
      );
    }
    if (statuses.values.any((status) => !status.isGranted)) {
      throw const PrinterException(
        'Bluetooth permission is required to use the receipt printer.',
      );
    }
    if (!await PrintBluetoothThermal.bluetoothEnabled) {
      throw const PrinterException('Bluetooth is unavailable or turned off.');
    }
  }
}
