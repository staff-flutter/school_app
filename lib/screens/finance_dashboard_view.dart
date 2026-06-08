import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:school_app/controllers/finance_ledger_controller.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/widgets/responsive_wrapper.dart';

class FinanceDashboardView extends StatefulWidget {
  const FinanceDashboardView({Key? key}) : super(key: key);

  @override
  State<FinanceDashboardView> createState() => _FinanceDashboardViewState();
}

class _FinanceDashboardViewState extends State<FinanceDashboardView> {
  late FinanceLedgerController controller;
  late AuthController authController;
  late SchoolController schoolController;

  String selectedRange = 'month';
  bool _filtersExpanded = false;

  // ── derived schoolId: for correspondent use sidebar selection,
  //    for all other roles fall back to the user's own schoolId
  String? get _effectiveSchoolId {
    final role = authController.user.value?.role.toLowerCase();
    if (role == 'correspondent') {
      return schoolController.selectedSchool.value?.id;
    }
    return authController.user.value?.schoolId;
  }

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<FinanceLedgerController>()) {
      Get.put(FinanceLedgerController());
    }
    controller = Get.find<FinanceLedgerController>();
    authController = Get.find<AuthController>();
    schoolController = Get.find<SchoolController>();

    // Listen to school changes (correspondent switching schools in sidebar)
    ever(schoolController.selectedSchool, (_) => _loadData());

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    final schoolId = _effectiveSchoolId;
    if (schoolId == null) return;
    controller.getFinanceStats(schoolId: schoolId, range: selectedRange);
    controller.getTimelineData(schoolId: schoolId, range: selectedRange);
    controller.applyFilters(schoolId);
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission(['correspondent', 'accountant', 'principal'])) {
      return _buildNoPermission();
    }

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                return RefreshIndicator(
                  onRefresh: () async => _loadData(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsSection(),
                        const SizedBox(height: 20),
                        _buildChartSection(),
                        const SizedBox(height: 20),
                        _buildFiltersSection(),
                        const SizedBox(height: 20),
                        _buildQuickActions(),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // School chip — only shown for correspondent
          Obx(() {
            final role = authController.user.value?.role.toLowerCase();
            if (role != 'correspondent') return const SizedBox.shrink();
            final school = schoolController.selectedSchool.value;
            return GestureDetector(
              onTap: _showSchoolPicker,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.school_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      school?.name ?? 'Select school',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.unfold_more_rounded,
                        color: Colors.white, size: 14),
                  ],
                ),
              ),
            );
          }),
          // Title row
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Finance Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Overview & transactions',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Range selector
              PopupMenuButton<String>(
                onSelected: (value) {
                  setState(() => selectedRange = value);
                  _loadData();
                },
                color: Colors.white,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border:
                    Border.all(color: Colors.white.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          color: Colors.white, size: 13),
                      const SizedBox(width: 5),
                      Text(
                        _rangeLabel(selectedRange),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12),
                      ),
                      const Icon(Icons.expand_more_rounded,
                          color: Colors.white, size: 14),
                    ],
                  ),
                ),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'today', child: Text('Today')),
                  PopupMenuItem(value: 'week', child: Text('This week')),
                  PopupMenuItem(value: 'month', child: Text('This month')),
                  PopupMenuItem(value: 'year', child: Text('This year')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Stats ───────────────────────────────────────────────────────────────────

  Widget _buildStatsSection() {
    return Obx(() {
      final stats = controller.stats.value;
      if (stats == null) {
        return const Center(
          child: Text('No data available',
              style: TextStyle(color: Colors.grey)),
        );
      }
      final income = stats['totalIncome'] ?? 0;
      final expense = stats['totalExpense'] ?? 0;
      final balance = stats['netBalance'] ?? 0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Financial summary'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _statCard('Total income', income, Colors.green,
                      Icons.trending_up_rounded)),
              const SizedBox(width: 10),
              Expanded(
                  child: _statCard('Total expense', expense, Colors.red,
                      Icons.trending_down_rounded)),
            ],
          ),
          const SizedBox(height: 10),
          _statCard('Net balance', balance, AppTheme.primaryBlue,
              Icons.account_balance_rounded,
              wide: true),
        ],
      );
    });
  }

  Widget _statCard(
      String label,
      dynamic value,
      Color color,
      IconData icon, {
        bool wide = false,
      }) {
    return Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  '₹${_formatAmount(value)}',
                  style: TextStyle(
                    fontSize: wide ? 20 : 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Chart ───────────────────────────────────────────────────────────────────

  Widget _buildChartSection() {
    return Obx(() {
      final timelineData = controller.timelineData;
      if (timelineData.isEmpty) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _sectionTitle('Income vs expense trend'),
                ),
                _legendDot('Income', Colors.green),
                const SizedBox(width: 12),
                _legendDot('Expense', Colors.red),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 160,
              child: LineChart(LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) =>
                      FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, m) => Text(
                        '₹${_formatAmount(v)}',
                        style: const TextStyle(
                            fontSize: 9, color: Colors.grey),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, m) {
                        final i = v.toInt();
                        if (i >= 0 && i < timelineData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              timelineData[i]['label'] ?? '',
                              style: const TextStyle(
                                  fontSize: 9, color: Colors.grey),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                      left: BorderSide(color: Colors.grey.shade200)),
                ),
                lineBarsData: [
                  _lineBar(timelineData, 'income', Colors.green),
                  _lineBar(timelineData, 'expense', Colors.red),
                ],
              )),
            ),
          ],
        ),
      );
    });
  }

  LineChartBarData _lineBar(
      List<Map<String, dynamic>> data, String key, Color color) {
    return LineChartBarData(
      spots: data
          .asMap()
          .entries
          .map((e) => FlSpot(
          e.key.toDouble(), (e.value[key] ?? 0).toDouble()))
          .toList(),
      isCurved: true,
      color: color,
      barWidth: 2.5,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.06),
      ),
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  // ── Filters ─────────────────────────────────────────────────────────────────

  Widget _buildFiltersSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _filtersExpanded = !_filtersExpanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded,
                      color: AppTheme.primaryBlue, size: 18),
                  const SizedBox(width: 8),
                  const Text('Filter transactions',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue)),
                  const Spacer(),
                  Obx(() => _activeFiltersCount() > 0
                      ? Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_activeFiltersCount()}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  )
                      : const SizedBox.shrink()),
                  Icon(
                    _filtersExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Body
          if (_filtersExpanded) ...[
            Divider(height: 1, color: Colors.grey.shade200),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  // Row 1
                  Row(
                    children: [
                      Expanded(
                          child: _dropdown(
                              'Academic year',
                              controller.selectedAcademicYear,
                              ['2023-2024', '2024-2025', '2025-2026'])),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _dropdown(
                              'Type',
                              controller.selectedTransactionType,
                              ['CREDIT', 'DEBIT'])),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Row 2
                  Row(
                    children: [
                      Expanded(
                          child: _dropdown(
                              'Payment mode',
                              controller.selectedPaymentMode,
                              ['cash', 'online', 'cheque', 'card'])),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _dropdown(
                              'Section',
                              controller.selectedSection,
                              ['student_record', 'expense', 'other'])),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Date range
                  Row(
                    children: [
                      Expanded(
                          child: Obx(() => _datePicker(
                              'From',
                              controller.fromDate.value,
                                  (d) => controller.fromDate.value = d))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Obx(() => _datePicker(
                              'To',
                              controller.toDate.value,
                                  (d) => controller.toDate.value = d))),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _applyFilters,
                          icon: const Icon(Icons.search_rounded, size: 16),
                          label: const Text('Apply filters',
                              style: TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: _clearFilters,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AppTheme.primaryBlue),
                          foregroundColor: AppTheme.primaryBlue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Clear',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  Widget _dropdown(
      String label, Rx<String?> value, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Obx(() => DropdownButtonFormField<String>(
          value: value.value,
          isDense: true,
          isExpanded: true, // 1. Crucial: Allows the selected item text to truncate properly
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 8),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                BorderSide(color: Colors.grey.shade300)),
          ),
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          items: [
            const DropdownMenuItem<String>(
                value: null,
                child: Text('All', style: TextStyle(fontSize: 12))),
            ...options.map((o) => DropdownMenuItem<String>(
                value: o,
                // 2. Wrap in a SizedBox or Container with a fixed width instead of Expanded
                child: SizedBox(
                  width: 150, // Adjust this width to match your UI needs
                  child: Text(
                    o,
                    maxLines: 1, // Ensures it stays on one line
                    style: const TextStyle(
                      fontSize: 12,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ))),
          ],
          onChanged: (v) => value.value = v,
        )),
      ],
    );
  }
  Widget _datePicker(String label, DateTime? date,
      Function(DateTime?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            onChanged(picked);
          },
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    date != null
                        ? DateFormat('dd/MM/yy').format(date)
                        : 'Select',
                    style: TextStyle(
                      fontSize: 12,
                      color: date != null
                          ? Colors.black87
                          : Colors.grey,
                    ),
                  ),
                ),
                const Icon(Icons.calendar_today_rounded,
                    size: 14, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Quick actions ───────────────────────────────────────────────────────────

  Widget _buildQuickActions() {
    final actions = [
      _ActionItem('All transactions', Icons.receipt_long_rounded,
          Colors.blue, _showTransactions),
      _ActionItem('Student fees', Icons.school_rounded,
          Colors.green, _showStudentFees),
      _ActionItem('Expenses only', Icons.money_off_rounded,
          Colors.red, _showExpenses),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Quick actions'),
        const SizedBox(height: 10),
        ...actions.map((a) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListTile(
            dense: true,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: a.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(a.icon, color: a.color, size: 18),
            ),
            title: Text(a.label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
            trailing: Icon(Icons.chevron_right_rounded,
                color: Colors.grey.shade400, size: 18),
            onTap: a.onTap,
          ),
        )),
      ],
    );
  }

  // ── Transaction bottom sheet ─────────────────────────────────────────────────

  void _showTransactions() {
    final schoolId = _effectiveSchoolId;
    if (schoolId != null) {
      controller.getAllTransactions(schoolId: schoolId);
      _openTransactionSheet('All transactions');
    }
  }

  void _showStudentFees() {
    final schoolId = _effectiveSchoolId;
    if (schoolId != null) {
      controller.getAllTransactions(
          schoolId: schoolId, section: 'student_record');
      _openTransactionSheet('Student fees');
    }
  }

  void _showExpenses() {
    final schoolId = _effectiveSchoolId;
    if (schoolId != null) {
      controller.getAllTransactions(
          schoolId: schoolId, section: 'expense');
      _openTransactionSheet('Expenses');
    }
  }

  void _openTransactionSheet(String title) {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Icon(Icons.receipt_long_rounded,
                      color: AppTheme.primaryBlue, size: 20),
                  const SizedBox(width: 10),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close)),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                if (controller.transactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_outlined,
                            size: 64,
                            color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text('No transactions found',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }
                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: controller.transactions.length,
                        separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                        itemBuilder: (context, index) =>
                            _transactionCard(
                                controller.transactions[index]),
                      ),
                    ),
                    _paginationBar(),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _paginationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Obx(() => IconButton(
            onPressed: controller.currentPage.value > 1
                ? () {
              controller.currentPage.value--;
              final id = _effectiveSchoolId;
              if (id != null) controller.applyFilters(id);
            }
                : null,
            icon: const Icon(Icons.chevron_left),
          )),
          Obx(() => Text(
            'Page ${controller.currentPage.value} of ${controller.totalPages.value}',
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500),
          )),
          Obx(() => IconButton(
            onPressed: controller.currentPage.value <
                controller.totalPages.value
                ? () {
              controller.currentPage.value++;
              final id = _effectiveSchoolId;
              if (id != null) controller.applyFilters(id);
            }
                : null,
            icon: const Icon(Icons.chevron_right),
          )),
        ],
      ),
    );
  }

  Widget _transactionCard(Map<String, dynamic> tx) {
    final isCredit = tx['transactionType'] == 'CREDIT';
    final color = isCredit ? Colors.green : Colors.red;
    final studentRecord = tx['studentRecordId'];
    final studentInfo = studentRecord != null
        ? 'Class ${studentRecord['className'] ?? ''}-${studentRecord['sectionName'] ?? ''}'
        : null;
    final createdBy = tx['createdBy']?['userName'] ?? 'Unknown';

    return InkWell(
      onTap: () {
        final id = tx['_id'];
        if (id != null) Get.toNamed('/transaction_detail', arguments: id);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isCredit
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx['description'] ?? 'Transaction',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.payment_rounded,
                          size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 3),
                      Text(
                        '${tx['paymentMode'] ?? 'N/A'} · ${_formatDate(tx['date'])}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  if (studentInfo != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.school_rounded,
                            size: 12,
                            color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Text(studentInfo,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.person_rounded,
                          size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 3),
                      Text('By $createdBy',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${_formatAmount(tx['amount'] ?? 0)}',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: color),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isCredit ? 'IN' : 'OUT',
                    style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── School picker (correspondent only) ──────────────────────────────────────

  void _showSchoolPicker() {
    final schools = schoolController.schools;
    if (schools.isEmpty) return;

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.6),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Select school',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
            Expanded(
              child: ListView.builder(
                itemCount: schools.length,
                itemBuilder: (context, index) {
                  final school = schools[index];
                  final isSelected =
                      schoolController.selectedSchool.value?.id ==
                          school.id;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryBlue
                          .withOpacity(0.1),
                      child: Text(
                        school.name.isNotEmpty
                            ? school.name[0].toUpperCase()
                            : 'S',
                        style: const TextStyle(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(school.name,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? AppTheme.primaryBlue
                                : null)),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded,
                        color: AppTheme.primaryBlue, size: 18)
                        : null,
                    onTap: () {
                      schoolController.selectedSchool.value = school;
                      Get.back();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── No permission ────────────────────────────────────────────────────────────

  Widget _buildNoPermission() {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Finance Dashboard'),
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Access denied',
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            const Text('You don\'t have permission to view finance data',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ── Filter actions ───────────────────────────────────────────────────────────

  void _applyFilters() async {
    final schoolId = _effectiveSchoolId;
    if (schoolId == null) {
      Get.snackbar('Error', 'No school selected',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    await controller.applyFilters(schoolId);
    Get.snackbar('Filters applied', '',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2));
  }

  void _clearFilters() {
    controller.clearFilters();
    final schoolId = _effectiveSchoolId;
    if (schoolId != null) controller.getAllTransactions(schoolId: schoolId);
    setState(() => _filtersExpanded = false);
    Get.snackbar('Filters cleared', '',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 2));
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Widget _sectionTitle(String text) => Text(text,
      style:
      const TextStyle(fontSize: 14, fontWeight: FontWeight.w600));

  bool _hasPermission(List<String> roles) {
    final role = authController.user.value?.role.toLowerCase();
    return role != null &&
        roles.map((r) => r.toLowerCase()).contains(role);
  }

  int _activeFiltersCount() {
    int n = 0;
    if (controller.selectedAcademicYear.value != null) n++;
    if (controller.selectedTransactionType.value != null) n++;
    if (controller.selectedAccountType.value != null) n++;
    if (controller.selectedStatus.value != null) n++;
    if (controller.selectedPaymentMode.value != null) n++;
    if (controller.selectedSection.value != null) n++;
    if (controller.fromDate.value != null) n++;
    if (controller.toDate.value != null) n++;
    return n;
  }

  String _rangeLabel(String r) {
    switch (r) {
      case 'today': return 'Today';
      case 'week': return 'This week';
      case 'month': return 'This month';
      case 'year': return 'This year';
      default: return r;
    }
  }

  String _formatDate(dynamic d) {
    if (d == null) return 'N/A';
    try {
      final dt = DateTime.parse(d.toString());
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return 'N/A';
    }
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    final num v =
    amount is String ? double.tryParse(amount) ?? 0 : amount;
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _ActionItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _ActionItem(this.label, this.icon, this.color, this.onTap);
}