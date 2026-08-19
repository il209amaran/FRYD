import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/utils/date_time_formatter.dart';
import '../../../models/report_models.dart';

class ReportExportService {
  Future<String> exportRange(RangeReport report) async {
    final excel = Excel.createExcel();
    _removeDefaultSheet(excel);
    final orders = excel['Orders'];
    orders.appendRow(
      _textRow(['Order Number', 'Date', 'Time', 'Status', 'Total']),
    );
    for (final order in report.orders) {
      orders.appendRow([
        TextCellValue(order.orderNumber),
        TextCellValue(formatDate(order.closedAt)),
        TextCellValue(formatTime(order.closedAt)),
        TextCellValue(order.status),
        DoubleCellValue(order.total),
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
    return _save(
      excel,
      'FRYD_Custom_${_fileDate(report.from)}_${_fileDate(report.to)}.xlsx',
    );
  }

  Future<String> exportWeekly(List<PeriodSales> periods) async {
    final excel = Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet() ?? 'Weekly Sales'];
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
    return _save(excel, 'FRYD_Weekly_Sales.xlsx');
  }

  Future<String> exportMonthly(List<PeriodSales> periods) async {
    final excel = Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet() ?? 'Monthly Sales'];
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
    return _save(excel, 'FRYD_Monthly_Sales.xlsx');
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

  void _removeDefaultSheet(Excel excel) {
    final name = excel.getDefaultSheet();
    if (name != null) excel.delete(name);
  }

  Future<String> _save(Excel excel, String fileName) async {
    final bytes = excel.encode();
    if (bytes == null) throw StateError('Excel file could not be generated.');
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, fileName));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  String _fileDate(DateTime date) =>
      '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
}
