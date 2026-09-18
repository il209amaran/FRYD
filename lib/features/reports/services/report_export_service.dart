import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/utils/date_time_formatter.dart';
import '../../../models/report_models.dart';

class ReportExportService {
  static const _downloadsChannel = MethodChannel('com.fryd.fryd/downloads');

  Future<String> exportRange(RangeReport report) async {
    final excel = Excel.createExcel();
    final orders = _createSheet(excel, 'Orders');
    orders.appendRow(
      _textRow([
        'Order Number',
        'Date',
        'Time',
        'Status',
        'Subtotal',
        'Tax',
        'Total',
        'Payment Method',
      ]),
    );
    for (final order in report.orders) {
      orders.appendRow([
        TextCellValue(order.orderNumber),
        TextCellValue(formatDate(order.closedAt)),
        TextCellValue(formatTime(order.closedAt)),
        TextCellValue(order.status),
        DoubleCellValue(order.subtotal),
        DoubleCellValue(order.taxAmount),
        DoubleCellValue(order.total),
        TextCellValue(order.paymentMethod),
      ]);
    }
    orders.appendRow([]);
    _appendSummary(orders, [
      ['From Date', formatDate(report.from)],
      ['To Date', formatDate(report.to)],
      ['Total Collection', report.totalCollection],
      ['Total Orders', report.totalOrders],
      ['Average Order Value', report.averageOrderValue],
      ['Total Items Sold', report.totalItems],
    ]);
    _formatSheet(
      orders,
      columnWidths: const [22, 16, 14, 12, 14, 12, 14, 22],
    );

    final items = excel['Item Sales'];
    items.appendRow(
      _textRow(['Item Name', 'Item Type', 'Quantity Sold', 'Sales Amount']),
    );
    for (final item in report.items) {
      items.appendRow([
        TextCellValue(item.name),
        TextCellValue(item.type),
        IntCellValue(item.quantity),
        DoubleCellValue(item.sales),
      ]);
    }
    _formatSheet(items, columnWidths: const [28, 16, 16, 18]);
    return _save(
      excel,
      'Kanakki_Custom_${_fileDate(report.from)}_${_fileDate(report.to)}.xlsx',
    );
  }

  Future<String> exportWeekly(List<PeriodSales> periods) async {
    final excel = Excel.createExcel();
    final sheet = _createSheet(excel, 'Weekly Sales');
    sheet.appendRow(
      _textRow([
        'Week Start',
        'Week End',
        'Closed Orders',
        'Total Sales',
        'Average Order Value',
      ]),
    );
    for (final period in periods) {
      sheet.appendRow([
        TextCellValue(formatDate(period.start)),
        TextCellValue(formatDate(period.end)),
        IntCellValue(period.orders),
        DoubleCellValue(period.sales),
        DoubleCellValue(period.averageOrderValue),
      ]);
    }
    if (periods.isNotEmpty) {
      sheet.appendRow([]);
      _appendSummary(sheet, [
        ['Report Start Date', formatDate(periods.first.start)],
        ['Report End Date', formatDate(periods.last.end)],
        [
          'Total Sales',
          periods.fold<double>(0, (sum, value) => sum + value.sales),
        ],
        [
          'Total Closed Orders',
          periods.fold<int>(0, (sum, value) => sum + value.orders),
        ],
      ]);
    }
    _formatSheet(sheet, columnWidths: const [24, 18, 18, 18, 22]);
    return _save(excel, 'Kanakki_Weekly_Sales.xlsx');
  }

  Future<String> exportMonthly(List<PeriodSales> periods) async {
    final excel = Excel.createExcel();
    final sheet = _createSheet(excel, 'Monthly Sales');
    sheet.appendRow(
      _textRow([
        'Month',
        'Year',
        'Closed Orders',
        'Total Sales',
        'Average Order Value',
      ]),
    );
    for (final period in periods) {
      sheet.appendRow([
        TextCellValue(formatMonthYear(period.start).split(' ').first),
        IntCellValue(period.start.year),
        IntCellValue(period.orders),
        DoubleCellValue(period.sales),
        DoubleCellValue(period.averageOrderValue),
      ]);
    }
    if (periods.isNotEmpty) {
      sheet.appendRow([]);
      _appendSummary(sheet, [
        ['Report Start Month', formatMonthYear(periods.first.start)],
        ['Report End Month', formatMonthYear(periods.last.start)],
        [
          'Total Sales',
          periods.fold<double>(0, (sum, value) => sum + value.sales),
        ],
        [
          'Total Closed Orders',
          periods.fold<int>(0, (sum, value) => sum + value.orders),
        ],
      ]);
    }
    _formatSheet(sheet, columnWidths: const [24, 12, 18, 18, 22]);
    return _save(excel, 'Kanakki_Monthly_Sales.xlsx');
  }

  List<CellValue?> _textRow(List<String> values) =>
      values.map(TextCellValue.new).toList();

  void _appendSummary(Sheet sheet, List<List<Object>> rows) {
    for (final row in rows) {
      final value = row[1];
      sheet.appendRow([
        TextCellValue(row[0] as String),
        switch (value) {
          int number => IntCellValue(number),
          double number => DoubleCellValue(number),
          _ => TextCellValue(value.toString()),
        },
      ]);
    }
  }

  Sheet _createSheet(Excel excel, String name) {
    final defaultName = excel.getDefaultSheet();
    final sheet = excel[name];
    if (defaultName != null && defaultName != name) {
      excel.delete(defaultName);
    }
    excel.setDefaultSheet(name);
    return sheet;
  }

  void _formatSheet(Sheet sheet, {required List<double> columnWidths}) {
    for (var index = 0; index < columnWidths.length; index++) {
      sheet.setColumnWidth(index, columnWidths[index]);
      final header = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: index, rowIndex: 0),
      );
      header.cellStyle = (header.cellStyle ?? CellStyle()).copyWith(boldVal: true);
    }
  }

  Future<String> _save(Excel excel, String fileName) async {
    final bytes = excel.encode();
    if (bytes == null) throw StateError('Excel file could not be generated.');
    if (defaultTargetPlatform == TargetPlatform.android) {
      final savedPath = await _downloadsChannel.invokeMethod<String>(
        'saveFile',
        {
          'fileName': fileName,
          'mimeType': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          'bytes': Uint8List.fromList(bytes),
        },
      );
      if (savedPath == null) {
        throw StateError('Excel file could not be saved to Downloads.');
      }
      return savedPath;
    }
    final directory = await getDownloadsDirectory();
    if (directory == null) {
      throw StateError('The Downloads directory is unavailable.');
    }
    await directory.create(recursive: true);
    final file = File(p.join(directory.path, fileName));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  String _fileDate(DateTime date) =>
      '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
}
