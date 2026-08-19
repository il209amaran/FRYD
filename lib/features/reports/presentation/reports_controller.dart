import 'package:flutter/foundation.dart';

import '../../../models/report_models.dart';
import '../data/report_repository.dart';
import '../services/report_export_service.dart';

class ReportsController extends ChangeNotifier {
  ReportsController({
    ReportRepository? repository,
    ReportExportService? exportService,
  }) : _repository = repository ?? SqliteReportRepository(),
       _exportService = exportService ?? ReportExportService();

  final ReportRepository _repository;
  final ReportExportService _exportService;
  SalesSummary? _summary;
  List<DailySales> _trend = const [];
  List<ItemSales> _topItems = const [];
  RangeReport? _rangeReport;
  bool _isLoading = true;
  bool _isGenerating = false;
  String? _errorMessage;

  SalesSummary? get summary => _summary;
  List<DailySales> get trend => List.unmodifiable(_trend);
  List<ItemSales> get topItems => List.unmodifiable(_topItems);
  RangeReport? get rangeReport => _rangeReport;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final now = DateTime.now();
      final results = await Future.wait([
        _repository.getSummary(now),
        _repository.getSevenDayTrend(now),
        _repository.getTopItems(),
      ]);
      _summary = results[0] as SalesSummary;
      _trend = results[1] as List<DailySales>;
      _topItems = results[2] as List<ItemSales>;
    } catch (_) {
      _errorMessage = 'Reports could not be loaded.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> generateRange(DateTime from, DateTime to) async {
    _isGenerating = true;
    notifyListeners();
    try {
      _rangeReport = await _repository.getRangeReport(from, to);
      _errorMessage = null;
    } catch (_) {
      _errorMessage = 'The custom report could not be generated.';
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<List<PeriodSales>> weekly() =>
      _repository.getWeeklyReport(DateTime.now());
  Future<List<PeriodSales>> monthly() =>
      _repository.getMonthlyReport(DateTime.now());
  Future<String> exportRange() => _exportService.exportRange(_rangeReport!);
  Future<String> exportWeekly(List<PeriodSales> periods) =>
      _exportService.exportWeekly(periods);
  Future<String> exportMonthly(List<PeriodSales> periods) =>
      _exportService.exportMonthly(periods);
}
