import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_time_formatter.dart';
import '../../../models/report_models.dart';
import 'reports_controller.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late final ReportsController _controller;
  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now();

  @override
  void initState() {
    super.initState();
    _controller = ReportsController()..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool from}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: from ? _from : _to,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (selected == null) return;
    setState(() {
      if (from) {
        _from = selected;
        if (_to.isBefore(_from)) _to = _from;
      } else {
        _to = selected;
        if (_from.isAfter(_to)) _from = _to;
      }
    });
  }

  Future<void> _export(Future<String> Function() export) async {
    try {
      final path = await export();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Excel saved to $path')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Excel file could not be saved.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    builder: (context, _) {
      if (_controller.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_controller.errorMessage != null && _controller.summary == null) {
        return Center(
          child: OutlinedButton.icon(
            onPressed: _controller.load,
            icon: const Icon(Icons.refresh),
            label: const Text('Reload reports'),
          ),
        );
      }
      final summary = _controller.summary!;
      return SingleChildScrollView(
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < 700 ? 12 : 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reports', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth < 600
                    ? 2
                    : constraints.maxWidth < 1000
                    ? 3
                    : 5;
                final width =
                    (constraints.maxWidth - (columns - 1) * 12) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _SummaryCard(
                      width: width,
                      label: "Today's Sales",
                      value: formatCurrency(summary.todaySales),
                      icon: Icons.today,
                    ),
                    _SummaryCard(
                      width: width,
                      label: 'This Week',
                      value: formatCurrency(summary.weekSales),
                      icon: Icons.date_range,
                    ),
                    _SummaryCard(
                      width: width,
                      label: 'This Month',
                      value: formatCurrency(summary.monthSales),
                      icon: Icons.calendar_month,
                    ),
                    _SummaryCard(
                      width: width,
                      label: 'Orders Today',
                      value: '${summary.ordersToday}',
                      icon: Icons.receipt_long,
                    ),
                    _SummaryCard(
                      width: width,
                      label: 'Avg Order Value',
                      value: formatCurrency(summary.averageOrderValue),
                      icon: Icons.analytics_outlined,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            _SectionCard(
              title: 'Payment Breakdown',
              child: summary.paymentBreakdown.isEmpty
                  ? const Text('No closed payments recorded today.')
                  : Column(
                      children: [
                        for (final payment in summary.paymentBreakdown)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(payment.name),
                            trailing: Text(
                              formatCurrency(payment.total),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 18),
            _SectionCard(
              title: '7-Day Sales Trend',
              child: _SalesTrend(values: _controller.trend),
            ),
            const SizedBox(height: 18),
            _SectionCard(
              title: 'Top 5 Selling Items',
              child: _TopItems(items: _controller.topItems),
            ),
            const SizedBox(height: 18),
            _SectionCard(
              title: 'Custom Date Report',
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked = constraints.maxWidth < 620;
                      final width = stacked
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 24) / 3;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          SizedBox(
                            width: width,
                            child: _DateButton(
                              label: 'From Date',
                              date: _from,
                              onPressed: () => _pickDate(from: true),
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: _DateButton(
                              label: 'To Date',
                              date: _to,
                              onPressed: () => _pickDate(from: false),
                            ),
                          ),
                          SizedBox(
                            width: width,
                            height: 56,
                            child: FilledButton.icon(
                              onPressed: _controller.isGenerating
                                  ? null
                                  : () => _controller.generateRange(_from, _to),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Generate Report'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  if (_controller.rangeReport case final report?) ...[
                    const SizedBox(height: 16),
                    _RangeSummary(report: report),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: () => _export(_controller.exportRange),
                        icon: const Icon(Icons.table_view),
                        label: const Text('Export Excel'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 620;
                final width = stacked
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 14) / 2;
                return Wrap(
                  spacing: 14,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: width,
                      child: _ReportButton(
                        title: 'Weekly Sales Report',
                        icon: Icons.view_week_outlined,
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) => _PeriodReportDialog(
                            title: 'Weekly Sales Report',
                            future: _controller.weekly(),
                            export: _controller.exportWeekly,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _ReportButton(
                        title: 'Monthly Sales Report',
                        icon: Icons.calendar_view_month,
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) => _PeriodReportDialog(
                            title: 'Monthly Sales Report',
                            future: _controller.monthly(),
                            export: _controller.exportMonthly,
                            monthly: true,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      );
    },
  );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
  });
  final double width;
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    ),
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ),
  );
}

class _SalesTrend extends StatelessWidget {
  const _SalesTrend({required this.values});
  final List<DailySales> values;
  @override
  Widget build(BuildContext context) {
    final maximum = values.fold<double>(
      0,
      (max, value) => value.total > max ? value.total : max,
    );
    return SizedBox(
      height: 190,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values.map((value) {
          final fraction = maximum == 0 ? 0.0 : value.total / maximum;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency(value.total),
                    style: const TextStyle(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Container(
                    height: 110 * fraction + 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${value.date.day}/${value.date.month}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TopItems extends StatelessWidget {
  const _TopItems({required this.items});
  final List<ItemSales> items;
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Text('No closed-order item sales available.');
    }
    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(child: Text('${index + 1}')),
          title: Text(item.name),
          subtitle: Text('${item.type} • ${item.quantity} sold'),
          trailing: Text(
            formatCurrency(item.sales),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        );
      }),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.date,
    required this.onPressed,
  });
  final String label;
  final DateTime date;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.calendar_today),
    label: Text('$label  ${formatDate(date)}'),
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, 56),
      alignment: Alignment.centerLeft,
    ),
  );
}

class _RangeSummary extends StatelessWidget {
  const _RangeSummary({required this.report});
  final RangeReport report;
  @override
  Widget build(BuildContext context) {
    if (report.orders.isEmpty) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text('No closed orders available for this report.'),
      );
    }
    return Wrap(
      spacing: 24,
      runSpacing: 10,
      children: [
        Text('Collection: ${formatCurrency(report.totalCollection)}'),
        Text('Closed Orders: ${report.totalOrders}'),
        Text('Average: ${formatCurrency(report.averageOrderValue)}'),
        Text('Items Sold: ${report.totalItems}'),
      ],
    );
  }
}

class _ReportButton extends StatelessWidget {
  const _ReportButton({
    required this.title,
    required this.icon,
    required this.onPressed,
  });
  final String title;
  final IconData icon;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    ),
  );
}

class _PeriodReportDialog extends StatelessWidget {
  const _PeriodReportDialog({
    required this.title,
    required this.future,
    required this.export,
    this.monthly = false,
  });
  final String title;
  final Future<List<PeriodSales>> future;
  final Future<String> Function(List<PeriodSales>) export;
  final bool monthly;

  @override
  Widget build(BuildContext context) => AlertDialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
    title: Text(title),
    content: SizedBox(
      width: MediaQuery.sizeOf(context).width < 700 ? double.maxFinite : 650,
      height: (MediaQuery.sizeOf(context).height * 0.72).clamp(320, 460),
      child: FutureBuilder<List<PeriodSales>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Report could not be generated.'));
          }
          final periods = snapshot.data ?? const [];
          if (periods.isEmpty) {
            return const Center(
              child: Text('No closed orders available for this report.'),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  itemCount: periods.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final period = periods[index];
                    final heading = monthly
                        ? formatMonthYear(period.start)
                        : (period.label ?? 'Week ${index + 1}');
                    return ListTile(
                      title: Text(
                        heading,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        monthly
                            ? '${period.orders} closed orders'
                            : '${formatDate(period.start)} – ${formatDate(period.end)}\n${period.orders} closed orders',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatCurrency(period.sales),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Avg ${formatCurrency(period.averageOrderValue)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final path = await export(periods);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Excel saved to $path')),
                        );
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Excel file could not be saved.'),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.table_view),
                  label: const Text('Export Excel'),
                ),
              ),
            ],
          );
        },
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Close'),
      ),
    ],
  );
}
