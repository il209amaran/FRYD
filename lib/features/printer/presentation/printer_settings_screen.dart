import 'package:flutter/material.dart';

import '../data/printer_config_repository.dart';
import '../models/printer_config.dart';
import '../services/printer_service.dart';
import '../services/receipt_builder.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  final _repository = PrinterConfigRepository();
  final _printerService = PrinterService();
  final _receiptBuilder = ReceiptBuilder();
  PrinterConfig? _printer;
  bool _connected = false;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final printer = await _repository.getSelectedPrinter();
    final connected = await _printerService.isConnected;
    if (!mounted) return;
    setState(() {
      _printer = printer;
      _connected = connected;
      _busy = false;
    });
  }

  Future<void> _selectPrinter() async {
    setState(() => _busy = true);
    try {
      final printers = await _printerService.getPairedPrinters();
      if (!mounted) return;
      if (printers.isEmpty) {
        _showMessage(
          'No paired printers found. Pair the printer in Android Bluetooth settings first.',
        );
        return;
      }
      final selected = await showDialog<PrinterConfig>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Select Receipt Printer'),
          children: [
            for (final printer in printers)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, printer),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.print_outlined),
                  title: Text(printer.name),
                  subtitle: Text(printer.address),
                ),
              ),
          ],
        ),
      );
      if (selected == null) return;
      await _printerService.disconnect();
      await _repository.saveSelectedPrinter(selected);
      if (!mounted) return;
      setState(() {
        _printer = selected;
        _connected = false;
      });
      _showMessage('${selected.name} selected. Use Test Print to verify it.');
    } on PrinterException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Unable to load paired Bluetooth printers.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _testPrint() async {
    final printer = _printer;
    if (printer == null) {
      _showMessage('Select a receipt printer first.');
      return;
    }
    setState(() => _busy = true);
    try {
      final bytes = await _receiptBuilder.buildTestPrint();
      await _printerService.printBytes(printer, bytes);
      if (!mounted) return;
      setState(() => _connected = true);
      _showMessage('Test print sent successfully.');
    } on PrinterException catch (error) {
      if (mounted) setState(() => _connected = false);
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Test print failed. Check the printer and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 700 ? 12 : 24),
    child: ListView(
      children: [
        Text(
          'Receipt Printer',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Icon(Icons.print_outlined, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'Receipt Printer',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _connected ? 'Connected' : 'Not Connected',
                    style: TextStyle(
                      color: _connected ? Colors.green.shade700 : Colors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _printer == null
                        ? 'No printer selected'
                        : '${_printer!.name} • ${_printer!.address}',
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: _busy ? null : _selectPrinter,
                        icon: const Icon(Icons.bluetooth_searching),
                        label: const Text('Select Printer'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _testPrint,
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('Test Print'),
                      ),
                      if (_busy) ...[
                        const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pair the SHREYANS printer in Android Bluetooth settings before selecting it here.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
