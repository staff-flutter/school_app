import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/accounting_controller.dart';
import 'package:school_app/controllers/finance_ledger_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'dart:math' as math;

import '../controllers/school_controller.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
class _C {
  static const primary    = Color(0xFF2563EB);
  static const primaryDk  = Color(0xFF1D4ED8);
  static const primaryDkk = Color(0xFF1E3A8A);
  static const primaryLt  = Color(0xFF60A5FA);
  static const primaryLtt = Color(0xFF93C5FD);
  static const primaryBg  = Color(0xFFEFF6FF);
  static const surface    = Color(0xFFFFFFFF);
  static const bg         = Color(0xFFF0F5FF);
  static const border     = Color(0xFFE2E8F0);
  static const text       = Color(0xFF0F172A);
  static const textSub    = Color(0xFF475569);
  static const textMuted  = Color(0xFF94A3B8);
  static const success    = Color(0xFF10B981);
  static const successBg  = Color(0xFFD1FAE5);
  static const danger     = Color(0xFFEF4444);
  static const dangerBg   = Color(0xFFFEE2E2);
  static const warning    = Color(0xFFF59E0B);
  static const warningBg  = Color(0xFFFEF3C7);
  // Fee category colours (matches web donut)
  static const admission  = Color(0xFF2563EB);
  static const term1      = Color(0xFF10B981);
  static const term2      = Color(0xFFF59E0B);
  static const transport  = Color(0xFFEF4444);
  static const List<Color> donutPalette = [admission, term1, term2, transport, Color(0xFF8B5CF6), Color(0xFFEC4899)];
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
String _fmt(dynamic v, {bool currency = true}) {
  if (v == null) return currency ? '₹0' : '0';
  final n = (v is num) ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0;
  if (currency) {
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000)   return '₹${(n / 1000).toStringAsFixed(1)}K';
    return '₹${n.toStringAsFixed(0)}';
  }
  return n.toStringAsFixed(0);
}

// ─── Main View ────────────────────────────────────────────────────────────────
class AccountingDashboardView1 extends StatefulWidget {
  const AccountingDashboardView1({super.key});

  @override
  State<AccountingDashboardView1> createState() => _AccountingDashboardViewState();
}

class _AccountingDashboardViewState extends State<AccountingDashboardView1>
    with SingleTickerProviderStateMixin {
  SchoolController? get _school {
    if (Get.isRegistered<SchoolController>()) return Get.find<SchoolController>();
    return null;
  }
  //final schoolController = Get.find<SchoolController>();
  final _auth        = Get.find<AuthController>();
  final _finance     = Get.find<FinanceLedgerController>();
  final _accounting  = Get.find<AccountingController>();
  late final Worker _schoolWorker;
  // Expense report filter state
  String _expenseRange      = 'month'; // week | month | year
  String _academicYear      = '';
  String _expenseStatus     = '';
  String _expensePayMode    = '';
  String? _defaulterClassFilter;

  // Cash-flow timeline range
  String _cashflowRange     = 'month'; // all | 100 | month | year | current

  bool get _canViewTransactions {
    final role = _auth.user.value?.role?.toLowerCase() ?? '';
    return role == 'correspondent' || role == 'accountant';
  }

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<SchoolController>()) {
      Get.lazyPut(() => SchoolController());
    }
    // Register listener ONCE here, not inside _init
    _schoolWorker = ever(
      Get.find<SchoolController>().selectedSchool,
          (school) {
        if (school != null && mounted) _refresh();
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _schoolWorker.dispose(); // prevent memory leak
    super.dispose();
  }

// Helper to get the correct schoolId for any role
  String? get _resolvedSchoolId {
    final selected = Get.find<SchoolController>().selectedSchool.value;
    return selected?.id ?? _auth.user.value?.schoolId;
  }

  Future<void> _init() async {
    // Resolve/select the school FIRST, before any data fetch
    if (_school != null && _school!.selectedSchool.value == null) {
      await _school!.getAllSchools();
      final fallbackId = _auth.user.value?.schoolId;
      _school!.selectedSchool.value =
          _school!.schools.firstWhereOrNull((s) => s.id == fallbackId);
    }

    final schoolId = _resolvedSchoolId;
    if (schoolId == null) return;

    final now = DateTime.now();
    _academicYear = now.month >= 6
        ? '${now.year}-${now.year + 1}'
        : '${now.year - 1}-${now.year}';
    if (mounted) setState(() {});

    _finance.getFinanceStats(schoolId: schoolId, range: _cashflowRange);
    if (_canViewTransactions) {
      _finance.getAllTransactions(schoolId: schoolId);
    }    _accounting.loadOutstandingDuesSummary(schoolId: schoolId, academicYear: _academicYear);


    await _accounting.loadDashboardData();
    _accounting.loadStudentDefaulters(schoolId: schoolId, academicYear: _academicYear);

    if (_accounting.canViewExpenses) {
      _accounting.loadExpenses(schoolId: schoolId);
    }

    if (_school != null && _school!.selectedSchool.value == null) {
      await _school!.getAllSchools();
      _school!.selectedSchool.value =
          _school!.schools.firstWhereOrNull((s) => s.id == schoolId);
    }
  }

  Future<void> _refresh() async {
    final schoolId = _resolvedSchoolId; // fixed: was using _auth.user.value?.schoolId
    if (schoolId == null) return;

    _finance.getFinanceStats(schoolId: schoolId, range: _cashflowRange);
    if (_canViewTransactions) {
      _finance.getAllTransactions(schoolId: schoolId);
    }
    _accounting.loadOutstandingDuesSummary(schoolId: schoolId, academicYear: _academicYear);

    await _accounting.loadDashboardData();
    _accounting.loadStudentDefaulters(schoolId: schoolId, academicYear: _academicYear);

    if (_accounting.canViewExpenses) {
      _accounting.loadExpenses(schoolId: schoolId);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: _C.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: const SizedBox(height: 8)),
              SliverToBoxAdapter(child: _buildKpiRow()),
              SliverToBoxAdapter(child: const SizedBox(height: 8)),
              SliverToBoxAdapter(child: _buildCashFlowSection()),
              SliverToBoxAdapter(child: const SizedBox(height: 8)),
              SliverToBoxAdapter(child: _buildFeeChartsRow()),
              SliverToBoxAdapter(child: const SizedBox(height: 8)),
              SliverToBoxAdapter(child: _buildDefaulterAnalyticsSection()),
              SliverToBoxAdapter(child: const SizedBox(height: 8)),
              SliverToBoxAdapter(child: _buildExpenseReportSection()),
              SliverToBoxAdapter(child: const SizedBox(height: 16)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: _C.primary.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_C.primaryDkk, _C.primary]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Institutional Finance Matrix',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _C.text)),
                  const Text('Real-time macro financial telemetry',
                      style: TextStyle(fontSize: 10, color: _C.textMuted)),
                ],
              ),
            ),
            // Academic year chip
            Obx(() {
              final role = _auth.user.value?.role?.toLowerCase() ?? '';
              if (role != 'correspondent' && role != 'accountant') return const SizedBox.shrink();
              return GestureDetector(
                onTap: _showAcademicYearPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _C.primaryBg,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: _C.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_academicYear,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _C.primary)),
                      const SizedBox(width: 4),
                      const Icon(Icons.expand_more_rounded, size: 12, color: _C.primary),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showAcademicYearPicker() {
    final now    = DateTime.now();
    final years  = List.generate(5, (i) {
      final y = now.year - 2 + i;
      return '$y-${y + 1}';
    });
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Academic Year',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _C.text)),
            const SizedBox(height: 12),
            ...years.map((y) => ListTile(
              title: Text(y),
              trailing: y == _academicYear
                  ? const Icon(Icons.check_circle_rounded, color: _C.primary)
                  : null,
              onTap: () {
                setState(() => _academicYear = y);
                Navigator.pop(context);
                _refresh();
              },
            )),
          ],
        ),
      ),
    );
  }

  // ── KPI Row (4 cards) ──────────────────────────────────────────────────────
  Widget _buildKpiRow() {
    return Obx(() {
      final stats   = _finance.stats.value;
      final loading = _finance.isLoading.value || _accounting.isLoading.value;

      // Read everything from the raw stats map — avoids typed DashboardKPI model field access
      final totalRevenue = stats?['totalIncome']      ?? stats?['totalRevenue']       ?? 0;
      final totalExpense = stats?['totalExpense']     ?? 0;
      final netBalance   = stats?['netBalance']       ?? stats?['balance']            ?? 0;
      final txnCount     = stats?['transactionCount'] ?? stats?['totalTransactions']  ?? 0;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            _kpiCard('Total Revenue\nCollections', totalRevenue, Icons.trending_up_rounded,
                const Color(0xFF1D4ED8), isLoading: loading, subtitle: 'Aggregate inflows'),
            const SizedBox(width: 6),
            _kpiCard('Operational\nExpenditures', totalExpense, Icons.trending_down_rounded,
                const Color(0xFF60A5FA), isLoading: loading, subtitle: 'Disbursed costs'),
            const SizedBox(width: 6),
            _kpiCard('Net Operational\nBalance', netBalance, Icons.account_balance_rounded,
                const Color(0xFF1E3A8A), isLoading: loading, subtitle: 'Liquid balance'),
            const SizedBox(width: 6),
            _kpiCard('Processed\nTransactions', txnCount, Icons.receipt_long_rounded,
                const Color(0xFF2563EB), isLoading: loading, subtitle: 'Audited ledger items',
                currency: false),
          ],
        ),
      );
    });
  }

  Widget _kpiCard(String title, dynamic value, IconData icon, Color color,
      {bool isLoading = false, String subtitle = '', bool currency = true}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 14),
                const Spacer(),
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(color: color.withOpacity(0.3), shape: BoxShape.circle),
                ),
              ],
            ),
            const SizedBox(height: 6),
            isLoading
                ? Container(height: 14, width: 40, decoration: BoxDecoration(
                color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(4)))
                : FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(currency ? _fmt(value) : _fmt(value, currency: false),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 24, // Keeps text constraints locked vertically for a uniform 4-card structure
              child: Text(
                title,
                style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600, color: _C.textSub),
                maxLines: 2,
                overflow: TextOverflow.ellipsis, // truncates beautifully if words cannot wrap nicely
              ),
            ),
            if (subtitle.isNotEmpty)
              Text(subtitle,
                  style: const TextStyle(fontSize: 7.5, color: _C.textMuted),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  // ── Cash Flow Timeline ─────────────────────────────────────────────────────
  Widget _buildCashFlowSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart_rounded, color: _C.primary, size: 16),
                const SizedBox(width: 6),
                const Text('Cash Flow (Timeline)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _C.text)),

              ],
            ),
               SizedBox(height: 10,),
               // const Spacer(),
                // Range toggles — compact horizontal scroll so they never overflow
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _segmentedBar(
                    ['All', '100', 'Month', 'Year', 'Current'],
                    ['all', '100', 'month', 'year', 'current'],
                    _cashflowRange,
                        (v) {
                      setState(() => _cashflowRange = v);
                      final schoolId = _resolvedSchoolId;
                      if (schoolId != null) _finance.getFinanceStats(schoolId: schoolId, range: v);

                    },
                  ),
                ),

            const SizedBox(height: 10),
            Obx(() {
              final stats   = _finance.stats.value;
              final loading = _finance.isLoading.value;

              if (loading) {
                return const SizedBox(height: 90, child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: _C.primary)));
              }

              // Build monthly trend from stats or cashflow data
              final cashflow = stats?['cashflow'] as List?;
              if (cashflow == null || cashflow.isEmpty) {
                // Fallback: show income vs expense single bar
                final income  = (stats?['totalIncome']  ?? 0).toDouble();
                final expense = (stats?['totalExpense'] ?? 0).toDouble();
                if (income == 0 && expense == 0) {
                  return const SizedBox(
                    height: 80,
                    child: Center(child: Text('No data available for this range',
                        style: TextStyle(color: _C.textMuted, fontSize: 11))),
                  );
                }
                return SizedBox(
                  height: 110,
                  child: _IncomeExpenseBar(income: income, expense: expense),
                );
              }

              // Parse cashflow list into month -> value map
              final Map<String, double> incomeMap  = {};
              final Map<String, double> expenseMap = {};
              for (final item in cashflow) {
                final label   = item['label']?.toString()   ?? '';
                final inc     = (item['income']  ?? 0).toDouble();
                final exp     = (item['expense'] ?? 0).toDouble();
                incomeMap[label]  = inc;
                expenseMap[label] = exp;
              }

              return SizedBox(
                height: 100,
                child: _CashflowBarChart(incomeMap: incomeMap, expenseMap: expenseMap),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Fee Charts Row (Collected + Outstanding + Recent Payments) ─────────────
  Widget _buildFeeChartsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Obx(() {
        final loading = _accounting.isLoading.value || _finance.isLoading.value;

        return Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _buildCollectedFees(loading)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildOutstandingFees(loading)),
                ],
              ),
            ),
            if (_canViewTransactions) ...[
              const SizedBox(height: 8),
              _buildRecentPayments(loading),
            ],
          ],
        );
      }),
    );
  }

  Widget _buildCollectedFees(bool loading) {
    final stats = _finance.stats.value;

    Map<String, double> breakdown = {};
    double total = 0;

    if (stats != null) {
      final admission = (stats['admissionFeeCollected'] ?? stats['admissionCollected'] ?? 0).toDouble();
      final term1     = (stats['term1Collected']  ?? stats['firstTermCollected']  ?? 0).toDouble();
      final term2     = (stats['term2Collected']  ?? stats['secondTermCollected'] ?? 0).toDouble();
      final transport = (stats['transportCollected'] ?? stats['busCollected']     ?? 0).toDouble();
      total           = (stats['totalIncome']     ?? stats['totalCollected']      ?? 0).toDouble();
      if (admission > 0) breakdown['Admission'] = admission;
      if (term1     > 0) breakdown['Term 1']    = term1;
      if (term2     > 0) breakdown['Term 2']    = term2;
      if (transport > 0) breakdown['Transport'] = transport;
      if (breakdown.isEmpty && total > 0) breakdown['Collected'] = total;
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Collected Fees', Icons.paid_rounded, _C.primary),
          const SizedBox(height: 2),
          const Text('See exactly how much money has been paid across each fee category',
              style: TextStyle(fontSize: 9, color: _C.textMuted),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          loading
              ? const _LoadingPulse(height: 90)
              : _DonutChart(
            data: breakdown,
            centerLabel: 'Total\nReceived',
            centerValue: _fmt(total),
            palette: const [_C.admission, _C.term1, _C.term2, _C.transport,
              Color(0xFF8B5CF6), Color(0xFFEC4899)],
          ),
          if (breakdown.isNotEmpty) ...[
            const SizedBox(height: 8),
            _DonutLegend(
              data: breakdown,
              palette: const [_C.admission, _C.term1, _C.term2, _C.transport,
                Color(0xFF8B5CF6), Color(0xFFEC4899)],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOutstandingFees(bool loading) {
    return Obx(() {
      final breakdown = _accounting.outstandingDuesBreakdown;
      final total = _accounting.totalOutstandingDues.value;
      final isLoadingDues = _accounting.isLoadingDuesSummary.value;

      return _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Outstanding Fees', Icons.pending_actions_rounded, _C.warning),
            Text('Track pending term fees, and transport dues across the school',
                style: const TextStyle(fontSize: 9, color: _C.textMuted)),
            const SizedBox(height: 8),
            (loading || isLoadingDues)
                ? const _LoadingPulse(height: 90)
                : _DonutChart(
              data: breakdown,
              centerLabel: 'Total\nPending',
              centerValue: _fmt(total),
              centerColor: _C.danger,
              palette: const [_C.admission, _C.term1, _C.term2, _C.transport,
                Color(0xFF8B5CF6), Color(0xFFEC4899)],
            ),
            if (breakdown.isNotEmpty) ...[
              const SizedBox(height: 8),
              _DonutLegend(
                data: breakdown,
                palette: const [_C.admission, _C.term1, _C.term2, _C.transport,
                  Color(0xFF8B5CF6), Color(0xFFEC4899)],
              ),
            ],
          ],
        ),
      );
    });
  }
  Widget _buildRecentPayments(bool loading) {
    final txns = _finance.transactions; // now has both income + expense, real data

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Recent Payments', Icons.bolt_rounded, _C.warning),
          const SizedBox(height: 2),
          const Text('Real-time feed of recent fee collections',
              style: TextStyle(fontSize: 9, color: _C.textMuted),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          loading
              ? const _LoadingPulse(height: 80)
              : txns.isEmpty
              ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined, color: _C.textMuted, size: 32),
                  const SizedBox(height: 6),
                  const Text('No recent transactions',
                      style: TextStyle(color: _C.textMuted, fontSize: 11)),
                ],
              ),
            ),
          )
              : Column(
            children: txns.take(6).map((txn) => _paymentRow(txn)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _paymentRow(dynamic txn) {
    final isIncome  = (txn['transactionType'] ?? txn['type'] ?? '').toString().toUpperCase() == 'CREDIT'
        || (txn['type'] ?? '').toString().toLowerCase() == 'income';
  //  final isIncome  = (txn['type'] ?? '').toString().toLowerCase() == 'income';
    final color     = isIncome ? _C.primary : _C.danger;
    final icon      = isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    final amount    = txn['amount'] ?? txn['paidAmount'] ?? 0;
    final desc      = txn['description'] ?? txn['studentName'] ?? txn['category'] ?? 'Transaction';
    final dateRaw   = txn['date'] ?? txn['createdAt'] ?? txn['paymentDate'] ?? '';
    final dateStr   = _formatDate(dateRaw.toString());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _C.text),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(dateStr,
                    style: const TextStyle(fontSize: 10, color: _C.textMuted)),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${_fmt(amount)}',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  // ── Expense Report Section ─────────────────────────────────────────────────
  Widget _buildExpenseReportSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: _card(
        child: Obx(() {
          final expenses = _accounting.expenses;
          final loading  = _accounting.isLoading.value;

          // Filter expenses by selected range / status / payMode
          final filtered = _filterExpenses(expenses);

          // Compute stats
          double totalExpense        = 0;
          double pendingVerification = 0;
          double verifiedExpense     = 0;
          int    totalTxns           = filtered.length;

          for (final e in filtered) {
            totalExpense += e.amount;
            final status = (e.verificationStatus ?? '').toLowerCase();
            if (status == 'pending') pendingVerification += e.amount;
            if (status == 'verified' || status == 'approved') verifiedExpense += e.amount;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + range toggle

              // ✅ Clean Vertical Stack Layout
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sectionTitle('Expense Report', Icons.summarize_rounded, _C.primaryDk),
                      _segmentedBar(
                        ['WEEK', 'MONTH', 'YEAR'],
                        ['week', 'month', 'year'],
                        _expenseRange,
                            (v) => setState(() => _expenseRange = v),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Filter row: academic year | status | payment mode
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip(_academicYear.isEmpty ? 'Acad. Year' : _academicYear,
                        Icons.calendar_today_rounded, _academicYear.isNotEmpty,
                            () => _showAcademicYearPicker()),
                    const SizedBox(width: 8),
                    _filterChip(_expenseStatus.isEmpty ? 'Status' : _expenseStatus,
                        Icons.verified_rounded, _expenseStatus.isNotEmpty,
                            () => _showStatusPicker()),
                    const SizedBox(width: 8),
                    _filterChip(_expensePayMode.isEmpty ? 'Payment Mode' : _expensePayMode,
                        Icons.payment_rounded, _expensePayMode.isNotEmpty,
                            () => _showPayModePicker()),
                    if (_expenseStatus.isNotEmpty || _expensePayMode.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _expenseStatus  = '';
                            _expensePayMode = '';
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _C.dangerBg,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: const Text('Clear',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                    color: _C.danger)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 4 stat mini-cards
              loading
                  ? const _LoadingPulse(height: 60)
                  : Row(
                children: [
                  _expenseStat('Total Expense', totalExpense, _C.primaryDk,
                      Icons.money_off_rounded),
                  const SizedBox(width: 8),
                  _expenseStat('Total Txns', totalTxns.toDouble(), _C.primaryLt,
                      Icons.receipt_rounded, currency: false),
                  const SizedBox(width: 8),
                  _expenseStat('Pending', pendingVerification, _C.warning,
                      Icons.hourglass_top_rounded),
                  const SizedBox(width: 8),
                  _expenseStat('Verified', verifiedExpense, _C.success,
                      Icons.verified_rounded),
                ],
              ),

              const SizedBox(height: 12),
              Builder(builder: (_) {
                if (loading) return const _LoadingPulse(height: 160);

                final byDate = _buildCategoryTimeline(filtered);
                final dateLabels = byDate.keys.toList()..sort();
                final categories = filtered
                    .map((e) => (e.category ?? 'Other').toString())
                    .toSet()
                    .toList()
                  ..sort();
                final composition = _buildCategoryComposition(filtered);
                final colors = [
                  for (int i = 0; i < categories.length; i++) _categoryColor(categories[i], i)
                ];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Category Spending Timeline',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700, color: _C.text)),
                    const Text('Tracking outflow distribution across categories',
                        style: TextStyle(fontSize: 9, color: _C.textMuted)),
                    const SizedBox(height: 8),
                    dateLabels.isEmpty
                        ? const SizedBox(
                      height: 80,
                      child: Center(
                          child: Text('No data available for this range',
                              style: TextStyle(color: _C.textMuted, fontSize: 11))),
                    )
                        : SizedBox(
                      height: 110,
                      child: CustomPaint(
                        painter: _MultiLineChartPainter(
                          dateLabels: dateLabels,
                          byDate: byDate,
                          categories: categories,
                          colors: colors,
                        ),
                        child: Container(),
                      ),
                    ),
                    if (dateLabels.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(dateLabels.first,
                              style: const TextStyle(fontSize: 8, color: _C.textMuted)),
                          Text(dateLabels.last,
                              style: const TextStyle(fontSize: 8, color: _C.textMuted)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        for (int i = 0; i < categories.length; i++)
                          _legendDotStatic(colors[i], categories[i]),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Expense Composition',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700, color: _C.text)),
                    const SizedBox(height: 8),
                    _DonutChart(
                      data: composition,
                      centerLabel: 'Total\nExpense',
                      centerValue:
                      _fmt(composition.values.fold<double>(0, (s, v) => s + v)),
                      centerColor: _C.danger,
                      palette: const [_C.primary, Color(0xFF8B5CF6), _C.warning,
                        _C.success, _C.danger, _C.primaryLt],
                    ),
                    if (composition.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _DonutLegend(
                        data: composition,
                        palette: const [_C.primary, Color(0xFF8B5CF6), _C.warning,
                          _C.success, _C.danger, _C.primaryLt],
                      ),
                    ],
                    const SizedBox(height: 12),
                  ],
                );
              }),
              // Expense list
              loading
                  ? const _LoadingPulse(height: 120)
                  : filtered.isEmpty
                  ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_outlined, color: _C.textMuted, size: 32),
                      const SizedBox(height: 6),
                      const Text('No expenses found for selected filters',
                          style: TextStyle(color: _C.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
              )
                  : Column(
                children: filtered.take(8).map((e) => _expenseRow(e)).toList(),
              ),
            ],
          );
        }),
      ),
    );
  }

  List<dynamic> _filterExpenses(List expenses) {

    final now     = DateTime.now();
    DateTime start;
    switch (_expenseRange) {
      case 'week':
        start = now.subtract(const Duration(days: 7));
        break;
      case 'year':
        start = DateTime(now.year, 1, 1);
        break;
      default: // month
        start = DateTime(now.year, now.month, 1);
    }

    return expenses.where((e) {
      // Date filter
      if (e.date != null) {
        try {
          final d = DateTime.parse(e.date.toString());
          if (d.isBefore(start)) return false;
        } catch (_) {}
      }
      // Status filter
      if (_expenseStatus.isNotEmpty) {
        final s = (e.verificationStatus ?? '').toString().toLowerCase();
        if (s != _expenseStatus.toLowerCase()) return false;
      }
      // Payment mode filter
      if (_expensePayMode.isNotEmpty) {
        final m = (e.paymentMode ?? '').toString().toLowerCase();
        if (m != _expensePayMode.toLowerCase()) return false;
      }
      return true;
    }).toList();
  }

  Widget _expenseStat(String label, double value, Color color, IconData icon,
      {bool currency = true}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(currency ? _fmt(value) : value.toInt().toString(),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
            ),
            Text(label,
                style: const TextStyle(fontSize: 9, color: _C.textSub, fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _expenseRow(dynamic e) {
    final statusColor = _statusColor((e.verificationStatus ?? '').toString());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: _C.primaryBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.receipt_long_rounded, color: _C.primary, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((e.category ?? 'Expense').toString(),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _C.text),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(_formatDate((e.date ?? '').toString()),
                    style: const TextStyle(fontSize: 10, color: _C.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text((e.verificationStatus ?? 'Pending').toString(),
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: statusColor)),
          ),
          const SizedBox(width: 8),
          Text(_fmt(e.amount),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _C.danger)),
        ],
      ),
    );
  }

  void _showStatusPicker() {
    final options = ['', 'pending', 'verified', 'rejected'];
    final labels  = ['All', 'Pending', 'Verified', 'Rejected'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter by Status',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _C.text)),
            const SizedBox(height: 12),
            ...List.generate(options.length, (i) => ListTile(
              title: Text(labels[i]),
              trailing: _expenseStatus == options[i]
                  ? const Icon(Icons.check_circle_rounded, color: _C.primary)
                  : null,
              onTap: () {
                setState(() => _expenseStatus = options[i]);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showPayModePicker() {
    final options = ['', 'cash', 'cheque', 'upi', 'bank'];
    final labels  = ['All', 'Cash', 'Cheque', 'UPI', 'Bank'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter by Payment Mode',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _C.text)),
            const SizedBox(height: 12),
            ...List.generate(options.length, (i) => ListTile(
              title: Text(labels[i]),
              trailing: _expensePayMode == options[i]
                  ? const Icon(Icons.check_circle_rounded, color: _C.primary)
                  : null,
              onTap: () {
                setState(() => _expensePayMode = options[i]);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────
  Widget _card({required Widget child}) => Container(
    margin: EdgeInsets.zero,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _C.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _C.border),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: child,
  );

  Widget _sectionTitle(String title, IconData icon, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
            borderRadius: BorderRadius.circular(7)),
        child: Icon(icon, color: Colors.white, size: 13),
      ),
      const SizedBox(width: 6),
      Flexible(
        child: Text(title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _C.text),
            overflow: TextOverflow.ellipsis,
            maxLines: 1),
      ),
    ],
  );

  Widget _segmentedBar(List<String> labels, List<String> values, String selected,
      void Function(String) onChanged) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: _C.bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(labels.length, (i) {
          final active = values[i] == selected;
          return GestureDetector(
            onTap: () => onChanged(values[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: active ? _C.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(labels[i],
                  style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : _C.textMuted)),
            ),
          );
        }),
      ),
    );
  }

  Widget _filterChip(String label, IconData icon, bool active, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: active ? _C.primaryBg : _C.bg,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: active ? _C.primary.withOpacity(0.4) : _C.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 11, color: active ? _C.primary : _C.textMuted),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600,
                      color: active ? _C.primary : _C.textSub)),
              const SizedBox(width: 3),
              Icon(Icons.expand_more_rounded, size: 11,
                  color: active ? _C.primary : _C.textMuted),
            ],
          ),
        ),
      );

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'verified':
      case 'approved':
        return _C.success;
      case 'rejected':
        return _C.danger;
      default:
        return _C.warning;
    }
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) return '';
    try {
      final d = DateTime.parse(raw);
      // Detect if this is a pure date value (midnight UTC, no real time captured)
      final isDateOnly = !raw.contains('T') ||
          (d.hour == 0 && d.minute == 0 && d.second == 0);

      final local = d.toLocal();
      final now = DateTime.now();

      if (isDateOnly) {
        // No real time was ever recorded — just show the date, never a fake time
        if (d.year == now.year && d.month == now.month && d.day == now.day) {
          return 'Today';
        }
        final yesterday = now.subtract(const Duration(days: 1));
        if (d.year == yesterday.year && d.month == yesterday.month && d.day == yesterday.day) {
          return 'Yesterday';
        }
        return '${d.day} ${_months[d.month - 1]} ${d.year}';
      }

      // Has a genuine time component — safe to show it
      if (local.year == now.year && local.month == now.month && local.day == now.day) {
        return 'Today, ${local.hour.toString().padLeft(2,'0')}:${local.minute.toString().padLeft(2,'0')} ${local.hour >= 12 ? 'PM' : 'AM'}';
      }
      final yesterday = now.subtract(const Duration(days: 1));
      if (local.year == yesterday.year && local.month == yesterday.month && local.day == yesterday.day) {
        return 'Yesterday';
      }
      return '${local.day} ${_months[local.month - 1]} ${local.year}';
    } catch (_) {
      return raw;
    }
  }
  static const _months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

  Widget _buildDefaulterAnalyticsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: _card(
        child: Obx(() {
          final loading = _accounting.isLoadingDefaulters.value;
          final groups = _accounting.studentDefaulters;
          final totalOutstanding =
          groups.fold<double>(0, (s, g) => s + (g['total'] as double));

          final classLabels = groups.map((g) => g['label'] as String).toSet().toList()
            ..sort();

          final filtered = _defaulterClassFilter == null
              ? groups
              : groups.where((g) => g['label'] == _defaulterClassFilter).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _sectionTitle('Student Defaulter Analytics',
                      Icons.warning_amber_rounded, _C.danger),
                  if (!loading)
                    Text(_fmt(totalOutstanding),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w800, color: _C.danger)),
                ],
              ),
              const SizedBox(height: 2),
              const Text('Class-wise breakdown of specific student dues',
                  style: TextStyle(fontSize: 9, color: _C.textMuted)),
              const SizedBox(height: 10),

              if (classLabels.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('All Classes', Icons.filter_list_rounded,
                          _defaulterClassFilter == null,
                              () => setState(() => _defaulterClassFilter = null)),
                      const SizedBox(width: 8),
                      ...classLabels.map((label) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _filterChip(label, Icons.class_rounded,
                            _defaulterClassFilter == label,
                                () => setState(() => _defaulterClassFilter = label)),
                      )),
                    ],
                  ),
                ),
              const SizedBox(height: 10),

              loading
                  ? const _LoadingPulse(height: 100)
                  : filtered.isEmpty
                  ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Column(children: [
                    Icon(Icons.emoji_events_outlined, color: _C.textMuted, size: 32),
                    const SizedBox(height: 6),
                    const Text('No defaulters found',
                        style: TextStyle(color: _C.textMuted, fontSize: 11)),
                  ]),
                ),
              )
                  : Column(children: filtered.map((g) => _defaulterGroupCard(g)).toList()),
            ],
          );
        }),
      ),
    );
  }

  Widget _defaulterGroupCard(Map<String, dynamic> group) {
    final label = group['label'] as String;
    final total = group['total'] as double;
    final students = group['students'] as List<Map<String, dynamic>>;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700, color: _C.text)),
                    Text('${students.length} Defaulter${students.length == 1 ? '' : 's'}',
                        style: const TextStyle(fontSize: 9, color: _C.textMuted)),
                  ],
                ),
              ),
              Text(_fmt(total),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800, color: _C.danger)),
            ],
          ),
          const Divider(height: 16, color: _C.border),
          ...students.map((s) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: _C.dangerBg,
                  child: Text(
                    (s['name'] as String).isNotEmpty
                        ? (s['name'] as String)[0].toUpperCase() : '?',
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700, color: _C.danger),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s['name'] as String,
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600, color: _C.text)),
                      Text('Roll: ${s['roll']}',
                          style: const TextStyle(fontSize: 9, color: _C.textMuted)),
                    ],
                  ),
                ),
                Text(_fmt(s['amount']),
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, color: _C.danger)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Map<String, Map<String, double>> _buildCategoryTimeline(List<dynamic> filtered) {
    final Map<String, Map<String, double>> result = {};
    for (final e in filtered) {
      if (e.date == null) continue;
      DateTime d;
      try {
        d = DateTime.parse(e.date.toString());
      } catch (_) {
        continue;
      }
      final label =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final cat = (e.category ?? 'Other').toString();
      result.putIfAbsent(label, () => {});
      result[label]![cat] = (result[label]![cat] ?? 0) + (e.amount as num).toDouble();
    }
    return result;
  }

  /// Sums filtered expenses per category, for the donut chart.
  Map<String, double> _buildCategoryComposition(List<dynamic> filtered) {
    final Map<String, double> result = {};
    for (final e in filtered) {
      final cat = (e.category ?? 'Other').toString();
      result[cat] = (result[cat] ?? 0) + (e.amount as num).toDouble();
    }
    return result;
  }

  /// Fixed colors for the categories seen in the web version's chart, with a
  /// palette fallback for anything else. Adjust the map if your real
  /// category names differ (these are lowercase-matched).
  Color _categoryColor(String category, int index) {
    final known = <String, Color>{
      'maintenance': _C.primary,
      'salary': const Color(0xFF8B5CF6),
      'fuel': _C.warning,
      'eb': _C.success,
    };
    final key = category.toLowerCase();
    if (known.containsKey(key)) return known[key]!;
    return _C.donutPalette[index % _C.donutPalette.length];
  }

  /// Standalone legend dot (the existing _legendDot lives inside
  /// _CashflowBarChart and isn't reachable from here).
  Widget _legendDotStatic(Color c, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 8, height: 8,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 9, color: _C.textMuted)),
    ],
  );



}

class _MultiLineChartPainter extends CustomPainter {
  final List<String> dateLabels; // sorted ascending
  final Map<String, Map<String, double>> byDate; // date -> {category: amount}
  final List<String> categories;
  final List<Color> colors;

  _MultiLineChartPainter({
    required this.dateLabels,
    required this.byDate,
    required this.categories,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dateLabels.isEmpty || categories.isEmpty) return;

    double maxVal = 0;
    for (final date in dateLabels) {
      final map = byDate[date] ?? {};
      for (final cat in categories) {
        final v = map[cat] ?? 0;
        if (v > maxVal) maxVal = v;
      }
    }
    if (maxVal == 0) maxVal = 1;

    const double leftPad = 4, rightPad = 4, topPad = 8, bottomPad = 4;
    final chartW = size.width - leftPad - rightPad;
    final chartH = size.height - topPad - bottomPad;
    final n = dateLabels.length;
    final stepX = n > 1 ? chartW / (n - 1) : 0.0;

    for (int ci = 0; ci < categories.length; ci++) {
      final cat = categories[ci];
      final linePaint = Paint()
        ..color = colors[ci % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      final path = Path();
      for (int i = 0; i < n; i++) {
        final v = byDate[dateLabels[i]]?[cat] ?? 0;
        final x = leftPad + stepX * i;
        final y = topPad + chartH - (v / maxVal) * chartH;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, linePaint);

      final dotPaint = Paint()..color = colors[ci % colors.length];
      for (int i = 0; i < n; i++) {
        final v = byDate[dateLabels[i]]?[cat] ?? 0;
        final x = leftPad + stepX * i;
        final y = topPad + chartH - (v / maxVal) * chartH;
        canvas.drawCircle(Offset(x, y), 2.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MultiLineChartPainter old) =>
      old.dateLabels != dateLabels || old.byDate != byDate;
}
// ─── DonutChart Painter ────────────────────────────────────────────────────────
class _DonutChart extends StatelessWidget {
  final Map<String, double> data;
  final String centerLabel;
  final String centerValue;
  final Color centerColor;
  final List<Color> palette;

  const _DonutChart({
    required this.data,
    required this.centerLabel,
    required this.centerValue,
    this.centerColor = _C.primary,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: 90,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pie_chart_outline_rounded, color: _C.textMuted, size: 30),
              const SizedBox(height: 4),
              const Text('No data', style: TextStyle(fontSize: 10, color: _C.textMuted)),
            ],
          ),
        ),
      );
    }
    return SizedBox(
      height: 120,
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: CustomPaint(
            painter: _DonutPainter(data: data, palette: palette,
                centerLabel: centerLabel, centerValue: centerValue, centerColor: centerColor),
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final Map<String, double> data;
  final List<Color> palette;
  final String centerLabel;
  final String centerValue;
  final Color centerColor;

  _DonutPainter({
    required this.data,
    required this.palette,
    required this.centerLabel,
    required this.centerValue,
    required this.centerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    final total  = data.values.fold<double>(0, (s, v) => s + v);
    double angle = -math.pi / 2;
    int i = 0;

    for (final entry in data.entries) {
      final sweep = total > 0 ? (entry.value / total) * 2 * math.pi : 0.0;
      final paint = Paint()
        ..color = palette[i % palette.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.38
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius * 0.82),
          angle, sweep.toDouble(), false, paint);
      angle += sweep;
      i++;
    }

    // White inner circle
    canvas.drawCircle(center, radius * 0.55,
        Paint()..color = Colors.white..style = PaintingStyle.fill);

    // Center label
    final labelPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$centerValue\n',
            style: TextStyle(color: centerColor, fontSize: 12, fontWeight: FontWeight.w800),
          ),
          TextSpan(
            text: centerLabel,
            style: const TextStyle(color: _C.textMuted, fontSize: 7.5, fontWeight: FontWeight.w500),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    labelPainter.layout(maxWidth: radius * 1.0);
    labelPainter.paint(
      canvas,
      Offset(center.dx - labelPainter.width / 2, center.dy - labelPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.data != data || old.centerValue != centerValue;
}

class _DonutLegend extends StatelessWidget {
  final Map<String, double> data;
  final List<Color> palette;
  const _DonutLegend({required this.data, required this.palette});

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold<double>(0, (s, v) => s + v);
    int i = 0;
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: data.entries.map((e) {
        final color = palette[i % palette.length];
        final pct   = total > 0 ? (e.value / total * 100).toStringAsFixed(0) : '0';
        i++;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 4),
            Text('${e.key} $pct%',
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: _C.textSub)),
          ],
        );
      }).toList(),
    );
  }
}

// ─── Cashflow Bar Chart ────────────────────────────────────────────────────────
class _CashflowBarChart extends StatelessWidget {
  final Map<String, double> incomeMap;
  final Map<String, double> expenseMap;
  const _CashflowBarChart({required this.incomeMap, required this.expenseMap});

  @override
  Widget build(BuildContext context) {
    final labels = incomeMap.keys.toList();
    final maxVal = [
      ...incomeMap.values,
      ...expenseMap.values,
    ].fold<double>(0, math.max);

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: labels.map((label) {
              final income  = incomeMap[label]  ?? 0;
              final expense = expenseMap[label] ?? 0;
              return _BarGroup(label: label, income: income, expense: expense, maxVal: maxVal);
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),
        // Legend
        Wrap(
          spacing: 16,     // Horizontal gap between Income and Expense indicators
          runSpacing: 4,   // Vertical gap if they wrap onto a second line
          alignment: WrapAlignment.center,
          children: [
            _legendDot(_C.primary, 'Income'),
            _legendDot(_C.danger, 'Expense'),
          ],
        ),
      ],
    );
  }

  Widget _legendDot(Color c, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 9, color: _C.textMuted)),
    ],
  );
}

class _BarGroup extends StatelessWidget {
  final String label;
  final double income, expense, maxVal;
  const _BarGroup({required this.label, required this.income, required this.expense, required this.maxVal});

  @override
  Widget build(BuildContext context) {
    const maxH = 70.0;
    final incH  = maxVal > 0 ? (income  / maxVal) * maxH : 0.0;
    final expH  = maxVal > 0 ? (expense / maxVal) * maxH : 0.0;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _bar(incH, _C.primary),
              const SizedBox(width: 12),
              _bar(expH, _C.danger),
            ],
          ),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 8.5, color: _C.textMuted, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _bar(double h, Color c) => Container(
    width: 10,
    height: math.max(h, 3),
    decoration: BoxDecoration(
      color: c,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
    ),
  );
}

// ─── Income vs Expense simple bar (fallback) ─────────────────────────────────
class _IncomeExpenseBar extends StatelessWidget {
  final double income, expense;
  const _IncomeExpenseBar({required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    final maxVal = math.max(income, expense);
    const maxH   = 60.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_fmt(income),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _C.primary)),
                const SizedBox(height: 4),
                Container(
                    width: 40,
                    height: maxVal > 0 ? (income / maxVal) * maxH : 4,
                    decoration: BoxDecoration(
                      color: _C.primary,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    )),
                const SizedBox(height: 4),
                const Text('Income', style: TextStyle(fontSize: 9, color: _C.textMuted)),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_fmt(expense),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _C.danger)),
                const SizedBox(height: 4),
                Container(
                    width: 40,
                    height: maxVal > 0 ? (expense / maxVal) * maxH : 4,
                    decoration: BoxDecoration(
                      color: _C.danger,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    )),
                const SizedBox(height: 4),
                const Text('Expense', style: TextStyle(fontSize: 9, color: _C.textMuted)),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Loading pulse placeholder ────────────────────────────────────────────────
class _LoadingPulse extends StatelessWidget {
  final double height;
  const _LoadingPulse({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: _C.bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _C.primary)),
    );
  }
}