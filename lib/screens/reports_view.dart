import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:school_app/controllers/reports_controller.dart';

const _kBg        = Color(0xFFF0F5FF);
const _kBlue      = Color(0xFF2563EB);
const _kBlueDark  = Color(0xFF1E40AF);
const _kBlueDarker= Color(0xFF1A2A3A);
const _kBlueMuted = Color(0xFF90A4BE);
const _kBlueBorder= Color(0xFFDDE6F5);

final _fmtK = NumberFormat('#,##0.##', 'en_IN');
final _fmt  = NumberFormat('#,##0',    'en_IN');

String _rupee(num? v) => '₹${_fmt.format(v ?? 0)}';
String _rupeeK(num? v) {
  final val = (v ?? 0).toDouble();
  if (val >= 100000) return '₹${_fmtK.format(val / 100000)}L';
  if (val >= 1000)   return '₹${_fmtK.format(val / 1000)}K';
  return '₹${_fmt.format(val)}';
}

const _kReportTypes = [
  ('overview',       'Overview',          Icons.dashboard_rounded),
  ('income_expense', 'Income vs Expense', Icons.analytics_rounded),
  ('fee_collection', 'Fee Collection',    Icons.account_balance_wallet_rounded),
  ('expenses',       'Expenses',          Icons.receipt_long_rounded),
  ('concessions',    'Concessions',       Icons.discount_rounded),
];

const _kRanges = [
  ('today',     'Today'),
  ('this_week', 'This Week'),
  ('this_month','This Month'),
  ('this_year', 'This Year'),
];

class ReportsView extends GetView<ReportsController> {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        top: true,
        child: Column(children: [
          _buildHeader(),
          Expanded(child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 18 : 12, vertical: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildTypeSelector(),
              const SizedBox(height: 10),
              _buildRangeSelector(),
              const SizedBox(height: 10),
              _buildGenerateBtn(),
              const SizedBox(height: 14),
              _buildBody(isTablet),
              const SizedBox(height: 24),
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBlueBorder),
        boxShadow: [BoxShadow(color: _kBlueBorder.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: _kBlue.withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.assessment_rounded, color: _kBlue, size: 20),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reports & Analytics',
                style: TextStyle(color: _kBlueDarker, fontSize: 14, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis),
            Text('Real-time financial insights',
                style: TextStyle(color: _kBlueMuted, fontSize: 10)),
          ],
        )),
      ]),
    );
  }

  Widget _buildTypeSelector() {
    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sTitle('Report Type', Icons.bar_chart_rounded),
      const SizedBox(height: 10),
      Obx(() => Wrap(
        spacing: 7, runSpacing: 7,
        children: _kReportTypes.map((t) {
          final sel = controller.selectedReportType.value == t.$1;
          return GestureDetector(
            onTap: () => controller.selectedReportType.value = t.$1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: sel ? _kBlue : _kBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? _kBlue : _kBlueBorder),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(t.$3, size: 13, color: sel ? Colors.white : _kBlueMuted),
                const SizedBox(width: 5),
                Text(t.$2, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sel ? Colors.white : _kBlueDarker)),
              ]),
            ),
          );
        }).toList(),
      )),
    ]));
  }

  Widget _buildRangeSelector() {
    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sTitle('Date Range', Icons.calendar_month_rounded),
      const SizedBox(height: 10),
      Obx(() => Wrap(
        spacing: 7, runSpacing: 7,
        children: _kRanges.map((r) {
          final sel = controller.selectedRange.value == r.$1;
          return GestureDetector(
            onTap: () => controller.selectedRange.value = r.$1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: sel ? _kBlue.withOpacity(0.12) : _kBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: sel ? _kBlue : _kBlueBorder),
              ),
              child: Text(r.$2,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sel ? _kBlue : _kBlueDarker)),
            ),
          );
        }).toList(),
      )),
    ]));
  }

  Widget _buildGenerateBtn() {
    return Obx(() {
      final loading = controller.isLoading.value;
      return SizedBox(
        width: double.infinity,
        height: 46,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: loading
                ? const LinearGradient(colors: [Color(0xFF93C5FD), Color(0xFF60A5FA)])
                : const LinearGradient(colors: [_kBlue, _kBlueDark]),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: _kBlue.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: loading ? null : controller.loadReportData,
            icon: loading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
            label: Text(
              loading ? 'Loading report…' : 'Generate Report',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildBody(bool isTablet) {
    return Obx(() {
      if (controller.isLoading.value)   return _loadingState();
      if (controller.errorMessage.value.isNotEmpty) return _errorState(controller.errorMessage.value);
      if (!controller.hasData.value)    return _emptyState();
      switch (controller.selectedReportType.value) {
        case 'overview':       return _OverviewSection(isTablet: isTablet);
        case 'income_expense': return _IncomeExpenseSection(isTablet: isTablet);
        case 'fee_collection': return _FeeCollectionSection(isTablet: isTablet);
        case 'expenses':       return _ExpensesSection(isTablet: isTablet);
        case 'concessions':    return _ConcessionsSection(isTablet: isTablet);
        default: return _emptyState();
      }
    });
  }

  Widget _emptyState() => _card(child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 28),
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: _kBlue.withOpacity(0.08), shape: BoxShape.circle),
          child: const Icon(Icons.analytics_rounded, size: 32, color: _kBlue)),
      const SizedBox(height: 12),
      const Text('Select a report type & date range', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kBlueDarker)),
      const SizedBox(height: 4),
      const Text('Tap Generate Report to load data', style: TextStyle(fontSize: 11, color: _kBlueMuted)),
    ])),
  ));

  Widget _loadingState() => _card(child: const Padding(
    padding: EdgeInsets.symmetric(vertical: 32),
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      CircularProgressIndicator(color: _kBlue, strokeWidth: 2.5),
      SizedBox(height: 12),
      Text('Loading report data…', style: TextStyle(fontSize: 12, color: _kBlueMuted)),
    ])),
  ));

  Widget _errorState(String msg) => _card(child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline_rounded, size: 28, color: Color(0xFFEF4444)),
      const SizedBox(height: 8),
      Text(msg, style: const TextStyle(fontSize: 11, color: _kBlueDarker), textAlign: TextAlign.center),
    ])),
  ));
}

// ─────────────────────────────────────────────────────────────────────────────
// OVERVIEW
// ─────────────────────────────────────────────────────────────────────────────
class _OverviewSection extends GetView<ReportsController> {
  const _OverviewSection({required this.isTablet});
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final stats   = controller.financeStats.value ?? {};
    final income  = (stats['totalIncome']  as num?)?.toDouble() ?? 0;
    final expense = (stats['totalExpense'] as num?)?.toDouble() ?? 0;
    final balance = (stats['netBalance']   as num?)?.toDouble() ?? (income - expense);
    final txCount = (stats['transactionCount'] as num?)?.toInt() ?? 0;
    final feeIncome = (controller.feeStats.value?['totalIncome'] as num?)?.toDouble() ?? 0;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _rHeader('Financial Overview', Icons.dashboard_rounded, _kBlue),
      const SizedBox(height: 10),
      _kpiGrid(isTablet, [
        _KD('Total Income',  income,           Icons.trending_up_rounded,    const Color(0xFF2563EB)),
        _KD('Total Expense', expense,          Icons.trending_down_rounded,  const Color(0xFFEF4444)),
        _KD('Net Balance',   balance,          Icons.account_balance_rounded, balance >= 0 ? const Color(0xFF059669) : const Color(0xFFEF4444)),
        _KD('Transactions',  txCount.toDouble(), Icons.receipt_rounded,      const Color(0xFF0891B2), isCount: true),
      ]),
      const SizedBox(height: 10),
      _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sTitle('Income Breakdown', Icons.pie_chart_rounded),
        const SizedBox(height: 10),
        _subBar('Fee Collection', feeIncome, math.max(income, 1), _kBlue),
        const SizedBox(height: 6),
        _subBar('Other Income', math.max(0, income - feeIncome), math.max(income, 1), const Color(0xFF0891B2)),
      ])),
      _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sTitle('Period Summary', Icons.summarize_rounded),
        const SizedBox(height: 10),
        _sumRow('Period',         controller.rangeLabel),
        _sumRow('Total Income',   _rupee(income)),
        _sumRow('Total Expense',  _rupee(expense)),
        _sumRow('Net Balance',    _rupee(balance), vc: balance >= 0 ? const Color(0xFF059669) : const Color(0xFFEF4444)),
        _sumRow('Transactions',   '$txCount'),
        if (income > 0) _sumRow('Profit Margin', '${((balance / income) * 100).toStringAsFixed(1)}%', vc: _kBlue),
      ])),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INCOME vs EXPENSE
// ─────────────────────────────────────────────────────────────────────────────
class _IncomeExpenseSection extends GetView<ReportsController> {
  const _IncomeExpenseSection({required this.isTablet});
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final stats   = controller.financeStats.value ?? {};
    final income  = (stats['totalIncome']  as num?)?.toDouble() ?? 0;
    final expense = (stats['totalExpense'] as num?)?.toDouble() ?? 0;
    final balance = (stats['netBalance']   as num?)?.toDouble() ?? (income - expense);
    final timeline = controller.timelineData;

    final payModes = _buildPayModes();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _rHeader('Income vs Expense', Icons.analytics_rounded, _kBlue),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _statTile('Income',  _rupeeK(income),  Icons.trending_up_rounded,   const Color(0xFF2563EB))),
        const SizedBox(width: 8),
        Expanded(child: _statTile('Expense', _rupeeK(expense), Icons.trending_down_rounded, const Color(0xFFEF4444))),
        const SizedBox(width: 8),
        Expanded(child: _statTile('Balance', _rupeeK(balance), Icons.balance_rounded,        balance >= 0 ? const Color(0xFF059669) : const Color(0xFFEF4444))),
      ]),
      const SizedBox(height: 10),
      if (timeline.isNotEmpty)
        _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sTitle('Trend Chart', Icons.bar_chart_rounded),
          const SizedBox(height: 12),
          SizedBox(height: 140, child: _TimelineChart(data: timeline.toList())),
          const SizedBox(height: 8),
          Row(children: [
            _legendDot(const Color(0xFF2563EB), 'Income'),
            const SizedBox(width: 14),
            _legendDot(const Color(0xFFEF4444), 'Expense'),
          ]),
        ]))
      else
        _card(child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: Center(child: Text('No timeline data for this period', style: TextStyle(fontSize: 11, color: _kBlueMuted))),
        )),
      const SizedBox(height: 0),
      if (payModes.isNotEmpty)
        _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sTitle('Payment Mode Breakdown', Icons.credit_card_rounded),
          const SizedBox(height: 10),
          ...payModes.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _subBar(e.key.toUpperCase(), e.value, math.max(payModes.values.fold(0.0, (a, b) => a + b), 1), _kBlue),
          )),
        ])),
    ]);
  }

  Map<String, double> _buildPayModes() {
    final records = controller.studentRecords;
    final Map<String, double> modes = {};
    for (final r in records) {
      final receipts = r['receipts'] as List? ?? [];
      for (final rec in receipts) {
        final mode = (rec['paymentMode'] as String?) ?? 'Other';
        final amt  = (rec['amount'] as num?)?.toDouble() ?? 0;
        modes[mode] = (modes[mode] ?? 0) + amt;
      }
    }
    return modes;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FEE COLLECTION
// ─────────────────────────────────────────────────────────────────────────────
class _FeeCollectionSection extends GetView<ReportsController> {
  const _FeeCollectionSection({required this.isTablet});
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final feeStats  = controller.feeStats.value ?? {};
    final collected = (feeStats['totalIncome'] as num?)?.toDouble() ?? 0;
    final records   = controller.studentRecords;
    final fullyPaid = records.where((r) => r['isFullyPaid'] == true).length;
    final pending   = records.length - fullyPaid;

    double outstanding = 0;
    final Map<String, _CS> byClass = {};

    for (final r in records) {
      final dues = r['dues'] as Map<String, dynamic>? ?? {};
      for (final v in dues.values) {
        outstanding += (v as num?)?.toDouble() ?? 0;
      }
      final ci = r['classId'];
      final cn = ci is Map ? ((ci['className'] ?? ci['name'] ?? 'Unknown').toString()) : 'Unknown';
      final paid = (r['feePaid'] as Map? ?? {}).values.fold(0.0, (s, v) => s + ((v as num?)?.toDouble() ?? 0));
      final cs = byClass.putIfAbsent(cn, () => _CS());
      cs.collected += paid;
      cs.total++;
      if (r['isFullyPaid'] != true) cs.pending++;
    }

    final sorted = byClass.entries.toList()..sort((a, b) => b.value.collected.compareTo(a.value.collected));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _rHeader('Fee Collection', Icons.account_balance_wallet_rounded, const Color(0xFF059669)),
      const SizedBox(height: 10),
      _kpiGrid(isTablet, [
        _KD('Collected',   collected,           Icons.check_circle_rounded,   const Color(0xFF2563EB)),
        _KD('Outstanding', outstanding,          Icons.pending_actions_rounded, const Color(0xFFF59E0B)),
        _KD('Fully Paid',  fullyPaid.toDouble(), Icons.verified_rounded,       const Color(0xFF059669), isCount: true),
        _KD('Pending',     pending.toDouble(),   Icons.warning_amber_rounded,  const Color(0xFFEF4444), isCount: true),
      ]),
      const SizedBox(height: 10),
      if (sorted.isNotEmpty)
        _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sTitle('Class-wise Collection', Icons.class_rounded),
          const SizedBox(height: 10),
          ...sorted.take(8).map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _classRow(e.key, e.value.collected, e.value.total, e.value.pending),
          )),
        ]))
      else
        _noDataCard('No student records found'),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EXPENSES
// ─────────────────────────────────────────────────────────────────────────────
class _ExpensesSection extends GetView<ReportsController> {
  const _ExpensesSection({required this.isTablet});
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final total     = controller.totalExpenses;
    final pending   = controller.pendingExpenses;
    final byCategory= controller.expenseByCategory;
    final verified  = controller.expenseList.where((e) => (e['verificationStatus'] ?? e['status']) == 'verified').length;
    final cats      = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    const cols = [_kBlue, Color(0xFF0891B2), Color(0xFF1E40AF), Color(0xFF60A5FA), Color(0xFF3B82F6)];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _rHeader('Expenses Report', Icons.receipt_long_rounded, const Color(0xFFEF4444)),
      const SizedBox(height: 10),
      _kpiGrid(isTablet, [
        _KD('Total',    total,             Icons.money_off_rounded,  const Color(0xFFEF4444)),
        _KD('Pending',  pending.toDouble(),Icons.pending_rounded,    const Color(0xFFF59E0B), isCount: true),
        _KD('Verified', verified.toDouble(),Icons.verified_rounded,  const Color(0xFF059669), isCount: true),
        _KD('Records',  controller.expenseList.length.toDouble(), Icons.list_alt_rounded, const Color(0xFF2563EB), isCount: true),
      ]),
      const SizedBox(height: 10),
      if (cats.isNotEmpty)
        _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sTitle('Category Breakdown', Icons.pie_chart_rounded),
          const SizedBox(height: 10),
          ...cats.map((e) {
            final idx = cats.indexOf(e) % cols.length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _subBar(e.key, e.value, math.max(total, 1), cols[idx]),
            );
          }),
        ]))
      else
        _noDataCard('No expense records found'),
      const SizedBox(height: 0),
      if (controller.expenseList.isNotEmpty)
        _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sTitle('Recent Expenses', Icons.history_rounded),
          const SizedBox(height: 10),
          ...controller.expenseList.take(5).map((e) => _expRow(e)),
        ])),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONCESSIONS
// ─────────────────────────────────────────────────────────────────────────────
class _ConcessionsSection extends GetView<ReportsController> {
  const _ConcessionsSection({required this.isTablet});
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final students = controller.concessionStudents;
    final total    = controller.totalConcessionAmount;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _rHeader('Concessions', Icons.discount_rounded, const Color(0xFF7C3AED)),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _statTile('Total Concession', _rupeeK(total), Icons.discount_rounded, _kBlue)),
        const SizedBox(width: 8),
        Expanded(child: _statTile('Students', '${students.length}', Icons.people_rounded, _kBlue)),
      ]),
      const SizedBox(height: 10),
      if (students.isNotEmpty)
        _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sTitle('Concession Records', Icons.list_alt_rounded),
          const SizedBox(height: 10),
          ...students.take(15).map((r) => _concRow(r)),
        ]))
      else
        _noDataCard('No concession records found'),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TIMELINE CHART (custom painter)
// ─────────────────────────────────────────────────────────────────────────────
class _TimelineChart extends StatelessWidget {
  const _TimelineChart({required this.data});
  final List<Map<String, dynamic>> data;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(double.infinity, 140), painter: _ChartPainter(data: data));
}

class _ChartPainter extends CustomPainter {
  const _ChartPainter({required this.data});
  final List<Map<String, dynamic>> data;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final incomes  = data.map((d) => (d['totalIncome']  as num?)?.toDouble() ?? 0).toList();
    final expenses = data.map((d) => (d['totalExpense'] as num?)?.toDouble() ?? 0).toList();
    final maxVal   = [...incomes, ...expenses].fold(0.0, math.max);
    if (maxVal == 0) return;

    final n        = data.length;
    final barW     = math.min(size.width / (n * 2.5), 12.0);
    final gap      = size.width / n;
    final maxH     = size.height - 20;

    final incP  = Paint()..color = const Color(0xFF2563EB).withOpacity(0.85)..style = PaintingStyle.fill;
    final expP  = Paint()..color = const Color(0xFFEF4444).withOpacity(0.75)..style = PaintingStyle.fill;
    final lineP = Paint()..color = const Color(0xFFDDE6F5)..strokeWidth = 0.8;

    for (int i = 0; i <= 4; i++) {
      final y = size.height - 20 - (maxH * i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), lineP);
    }
    for (int i = 0; i < n; i++) {
      final cx   = gap * i + gap / 2;
      final incH = (incomes[i] / maxVal) * maxH;
      final expH = (expenses[i] / maxVal) * maxH;
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - barW - 1, size.height - 20 - incH, barW, incH), const Radius.circular(3)), incP);
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(cx + 1, size.height - 20 - expH, barW, expH), const Radius.circular(3)), expP);
    }

    final tp = TextPainter(textDirection: TextDirection.ltr);
    final step = math.max(1, n ~/ 6);
    for (int i = 0; i < n; i += step) {
      final label = (data[i]['label'] ?? data[i]['date'] ?? '').toString();
      if (label.isEmpty) continue;
      tp.text = TextSpan(text: label, style: const TextStyle(fontSize: 8, color: Color(0xFF90A4BE)));
      tp.layout();
      tp.paint(canvas, Offset(gap * i + gap / 2 - tp.width / 2, size.height - 14));
    }
  }

  @override
  bool shouldRepaint(_ChartPainter o) => o.data != data;
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper classes & functions
// ─────────────────────────────────────────────────────────────────────────────
class _CS { double collected = 0; int total = 0, pending = 0; }

class _KD {
  const _KD(this.label, this.value, this.icon, this.color, {this.isCount = false});
  final String label; final double value; final IconData icon; final Color color; final bool isCount;
}

// shared builders
Widget _card({required Widget child}) => Container(
  width: double.infinity, padding: const EdgeInsets.all(14),
  margin: const EdgeInsets.only(bottom: 10),
  decoration: BoxDecoration(
    color: Colors.white, borderRadius: BorderRadius.circular(14),
    border: Border.all(color: _kBlueBorder),
    boxShadow: [BoxShadow(color: _kBlueBorder.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2))],
  ),
  child: child,
);

Widget _sTitle(String t, IconData icon) => Row(children: [
  Container(padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: _kBlue.withOpacity(0.10), borderRadius: BorderRadius.circular(7)),
      child: Icon(icon, color: _kBlue, size: 14)),
  const SizedBox(width: 7),
  Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kBlueDarker)),
]);

Widget _rHeader(String title, IconData icon, Color color) => _card(child: Row(children: [
  Container(padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(9)),
      child: Icon(icon, color: color, size: 18)),
  const SizedBox(width: 9),
  Expanded(child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kBlueDarker))),
  Obx(() {
    final c = Get.find<ReportsController>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: _kBlue.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
      child: Text(c.rangeLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kBlue)),
    );
  }),
]));

Widget _kpiGrid(bool isTablet, List<_KD> items) => GridView.count(
  crossAxisCount: isTablet ? 4 : 2,
  shrinkWrap: true, primary: false,
  crossAxisSpacing: 8, mainAxisSpacing: 8,
  childAspectRatio: isTablet ? 2.2 : 1.9,
  children: items.map((d) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: d.color.withOpacity(0.2)),
      boxShadow: [BoxShadow(color: _kBlueBorder.withOpacity(0.4), blurRadius: 5, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
      Row(children: [
        Icon(d.icon, size: 13, color: d.color), const SizedBox(width: 4),
        Expanded(child: Text(d.label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: _kBlueMuted), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ]),
      const SizedBox(height: 5),
      Text(d.isCount ? d.value.toInt().toString() : _rupeeK(d.value),
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: d.color), maxLines: 1, overflow: TextOverflow.ellipsis),
    ]),
  )).toList(),
);

Widget _statTile(String label, String val, IconData icon, Color color) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
  decoration: BoxDecoration(
    color: Colors.white, borderRadius: BorderRadius.circular(12),
    border: Border.all(color: color.withOpacity(0.2)),
    boxShadow: [BoxShadow(color: _kBlueBorder.withOpacity(0.4), blurRadius: 5, offset: const Offset(0, 2))],
  ),
  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Icon(icon, size: 12, color: color), const SizedBox(width: 4),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 9, color: _kBlueMuted, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis))]),
    const SizedBox(height: 4),
    Text(val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
  ]),
);

Widget _subBar(String label, double value, double total, Color color) {
  final pct = total > 0 ? (value / total).clamp(0.0, 1.0) : 0.0;
  return Row(children: [
    SizedBox(width: 88, child: Text(label, style: const TextStyle(fontSize: 10, color: _kBlueDarker, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
    Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct, backgroundColor: _kBlueBorder, valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 6))),
    const SizedBox(width: 8),
    SizedBox(width: 58, child: Text(_rupeeK(value), textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color))),
  ]);
}

Widget _sumRow(String label, String val, {Color? vc}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 4),
  child: Row(children: [
    Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: _kBlueMuted))),
    Text(val, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: vc ?? _kBlueDarker)),
  ]),
);

Widget _classRow(String name, double collected, int total, int pending) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: _kBlueBorder)),
  child: Row(children: [
    Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: _kBlue.withOpacity(0.10), borderRadius: BorderRadius.circular(7)), child: const Icon(Icons.class_rounded, color: _kBlue, size: 13)),
    const SizedBox(width: 8),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kBlueDarker)),
      Text('$total students · $pending pending', style: const TextStyle(fontSize: 9, color: _kBlueMuted)),
    ])),
    Text(_rupeeK(collected), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kBlue)),
  ]),
);

Widget _expRow(Map<String, dynamic> e) {
  final status = (e['verificationStatus'] ?? e['status'] ?? 'pending') as String;
  final sc = status == 'verified' ? const Color(0xFF059669) : status == 'rejected' ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
  return Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: _kBlueBorder)),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: _kBlue.withOpacity(0.08), borderRadius: BorderRadius.circular(7)), child: const Icon(Icons.receipt_rounded, color: _kBlue, size: 12)),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(e['category'] ?? 'Expense', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kBlueDarker), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(e['date'] ?? e['createdAt'] ?? '', style: const TextStyle(fontSize: 9, color: _kBlueMuted)),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(_rupeeK(e['amount'] as num?), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kBlueDarker)),
        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: sc.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(status, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: sc))),
      ]),
    ]),
  );
}

Widget _concRow(Map<String, dynamic> r) {
  final sid  = r['studentId'];
  final name = sid is Map ? (sid['studentName'] ?? 'Student').toString() : 'Student';
  final amt  = r['concessionAmount'] ?? r['concession']?['amount'] ?? 0;
  return Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: _kBlueBorder)),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: _kBlue.withOpacity(0.08), borderRadius: BorderRadius.circular(7)), child: const Icon(Icons.discount_rounded, color: _kBlue, size: 12)),
      const SizedBox(width: 8),
      Expanded(child: Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kBlueDarker), maxLines: 1, overflow: TextOverflow.ellipsis)),
      Text(_rupeeK(amt as num?), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kBlue)),
    ]),
  );
}

Widget _legendDot(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
  Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
  const SizedBox(width: 4),
  Text(label, style: const TextStyle(fontSize: 10, color: _kBlueMuted, fontWeight: FontWeight.w600)),
]);

Widget _noDataCard(String msg) => _card(child: Padding(
  padding: const EdgeInsets.symmetric(vertical: 20),
  child: Center(child: Text(msg, style: const TextStyle(fontSize: 11, color: _kBlueMuted))),
));
