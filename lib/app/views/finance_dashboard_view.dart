import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../controllers/finance_ledger_controller.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/responsive_wrapper.dart';
import '../modules/auth/controllers/auth_controller.dart';
import '../views/transaction_detail_view.dart';

class FinanceDashboardView extends StatefulWidget {
  FinanceDashboardView({Key? key}) : super(key: key);

  @override
  State<FinanceDashboardView> createState() => _FinanceDashboardViewState();
}

class _FinanceDashboardViewState extends State<FinanceDashboardView> {
  final controller = Get.put(FinanceLedgerController());
  final authController = Get.find<AuthController>();
  String selectedRange = 'today';
  bool _filtersExpanded = false;

  @override
  void initState() {
    super.initState();
    // Defer API call until after build is complete to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final schoolId = authController.user.value?.schoolId;
    if (schoolId != null) {
      controller.getFinanceStats(schoolId: schoolId, range: selectedRange);
      controller.getTimelineData(schoolId: schoolId, range: selectedRange);
      // Load transactions with current filters
      controller.applyFilters(schoolId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission(['correspondent', 'accountant', 'principal'])) {
      return _buildNoPermissionWidget();
    }

    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      body: SafeArea(
        child: ResponsiveWrapper(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.successGradient,
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            size: 48,
                            color: Colors.white,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Finance Dashboard',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Get.back(),
                ),
                actions: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.date_range, color: Colors.white),
                    onSelected: (value) {
                      setState(() => selectedRange = value);
                      _loadData();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'today', child: Text('Today')),
                      const PopupMenuItem(value: 'week', child: Text('This Week')),
                      const PopupMenuItem(value: 'month', child: Text('This Month')),
                      const PopupMenuItem(value: 'year', child: Text('This Year')),
                    ],
                  ),
                ],
              ),

              SliverFillRemaining(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _loadData(),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(screenSize.width * 0.04),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatsCards(),
                          const SizedBox(height: 24),
                          _buildCollapsibleFilters(),
                          const SizedBox(height: 24),
                          _buildTimelineChart(),
                          const SizedBox(height: 24),
                          _buildQuickActions(),
                        ],
                      ),
                    ),
                  );
                }),
              ),
      ]),
    )));
  }

  Widget _buildStatsCards() {
    final stats = controller.stats.value;
    if (stats == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial Overview (${selectedRange.toUpperCase()})',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            return isWide 
              ? Row(
                  children: [
                    Expanded(child: _buildStatCard('Total Income', stats['totalIncome'] ?? 0, Colors.green, Icons.trending_up)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard('Total Expense', stats['totalExpense'] ?? 0, Colors.red, Icons.trending_down)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard('Net Balance', stats['netBalance'] ?? 0, Colors.blue, Icons.account_balance)),
                  ],
                )
              : Column(
                  children: [
                    _buildStatCard('Total Income', stats['totalIncome'] ?? 0, Colors.green, Icons.trending_up),
                    const SizedBox(height: 12),
                    _buildStatCard('Total Expense', stats['totalExpense'] ?? 0, Colors.red, Icons.trending_down),
                    const SizedBox(height: 12),
                    _buildStatCard('Net Balance', stats['netBalance'] ?? 0, Colors.blue, Icons.account_balance),
                  ],
                );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, dynamic value, Color color, IconData icon) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Text(
                  '₹${_formatAmount(value)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineChart() {
    final timelineData = controller.timelineData;
    if (timelineData.isEmpty) return const SizedBox();

    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Income vs Expense Trend',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          '₹${_formatAmount(value)}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < timelineData.length) {
                            return Text(
                              timelineData[index]['label'] ?? '',
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: timelineData.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), (entry.value['income'] ?? 0).toDouble());
                      }).toList(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: timelineData.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), (entry.value['expense'] ?? 0).toDouble());
                      }).toList(),
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Income', Colors.green),
                const SizedBox(width: 24),
                _buildLegendItem('Expense', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            return isWide 
              ? Row(
                  children: [
                    Expanded(child: _buildActionCard('View All Transactions', Icons.list, () => _showTransactions())),
                    const SizedBox(width: 12),
                    Expanded(child: _buildActionCard('Student Fees Only', Icons.school, () => _showStudentFees())),
                    const SizedBox(width: 12),
                    Expanded(child: _buildActionCard('Expenses Only', Icons.money_off, () => _showExpenses())),
                  ],
                )
              : Column(
                  children: [
                    _buildActionCard('View All Transactions', Icons.list, () => _showTransactions()),
                    const SizedBox(height: 12),
                    _buildActionCard('Student Fees Only', Icons.school, () => _showStudentFees()),
                    const SizedBox(height: 12),
                    _buildActionCard('Expenses Only', Icons.money_off, () => _showExpenses()),
                  ],
                );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.primaryBlue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoPermissionWidget() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Dashboard'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Access Denied',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'You don\'t have permission to access finance data',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactions() {
    final schoolId = authController.user.value?.schoolId;
    if (schoolId != null) {
      controller.getAllTransactions(schoolId: schoolId);
      _showTransactionsList('All Transactions');
    }
  }

  void _showStudentFees() {
    final schoolId = authController.user.value?.schoolId;
    if (schoolId != null) {
      controller.getAllTransactions(schoolId: schoolId, section: 'student_record');
      _showTransactionsList('Student Fees');
    }
  }

  void _showExpenses() {
    final schoolId = authController.user.value?.schoolId;
    if (schoolId != null) {
      controller.getAllTransactions(schoolId: schoolId, section: 'expense');
      _showTransactionsList('Expenses');
    }
  }

  void _showTransactionsList(String title) {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(Icons.receipt_long, color: AppTheme.primaryBlue),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.transactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No transactions found', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: controller.transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = controller.transactions[index];
                          return _buildTransactionCard(transaction);
                        },
                      ),
                    ),
                    // Pagination Controls
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border(top: BorderSide(color: Colors.grey[200]!)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: controller.currentPage.value > 1
                                ? () {
                                    controller.currentPage.value--;
                                    final schoolId = authController.user.value?.schoolId;
                                    if (schoolId != null) {
                                      controller.applyFilters(schoolId);
                                    }
                                  }
                                : null,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Obx(() => Text(
                            'Page ${controller.currentPage.value} of ${controller.totalPages.value}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          )),
                          IconButton(
                            onPressed: controller.currentPage.value < controller.totalPages.value
                                ? () {
                                    controller.currentPage.value++;
                                    final schoolId = authController.user.value?.schoolId;
                                    if (schoolId != null) {
                                      controller.applyFilters(schoolId);
                                    }
                                  }
                                : null,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ),
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

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final isIncome = transaction['transactionType'] == 'CREDIT';
    final amount = transaction['amount'] ?? 0;
    final date = _formatDate(transaction['date']);
    final description = transaction['description'] ?? 'Transaction';
    final paymentMode = transaction['paymentMode'] ?? 'N/A';
    final category = transaction['category'] ?? 'General';
    
    // Extract student info if available
    final studentRecord = transaction['studentRecordId'];
    String studentInfo = '';
    if (studentRecord != null) {
      final className = studentRecord['className'] ?? '';
      final sectionName = studentRecord['sectionName'] ?? '';
      studentInfo = 'Class $className-$sectionName';
    }
    
    // Extract created by info
    final createdBy = transaction['createdBy'];
    final createdByName = createdBy?['userName'] ?? 'Unknown';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          final transactionId = transaction['_id'];
          if (transactionId != null) {
            
            Get.toNamed('/transaction_detail', arguments: transactionId);
          } else {
            Get.snackbar('Error', 'Transaction ID not found',
              backgroundColor: AppTheme.errorRed, colorText: Colors.white);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isIncome ? Colors.green : Colors.red).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isIncome ? Icons.trending_up : Icons.trending_down,
                    color: isIncome ? Colors.green : Colors.red,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        description,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${_formatAmount(amount)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isIncome ? Colors.green : Colors.red,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isIncome ? Colors.green : Colors.red).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isIncome ? 'INCOME' : 'EXPENSE',
                        style: TextStyle(
                          color: isIncome ? Colors.green : Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.payment, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(paymentMode.toUpperCase(), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(date, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
            if (studentInfo.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.school, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(studentInfo, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('By: $createdByName', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr.toString());
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    final num value = amount is String ? double.tryParse(amount) ?? 0 : amount;
    if (value >= 10000000) return '${(value / 10000000).toStringAsFixed(1)}Cr';
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }

  bool _hasPermission(List<String> allowedRoles) {
    final userRole = authController.user.value?.role.toLowerCase();
    return userRole != null && allowedRoles.map((r) => r.toLowerCase()).contains(userRole);
  }

  Widget _buildCollapsibleFilters() {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          // ================= FILTER HEADER =================
          InkWell(
            onTap: () {
              setState(() {
                _filtersExpanded = !_filtersExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, color: AppTheme.primaryBlue),
                  const SizedBox(width: 12),
                  const Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const Spacer(),
                  Obx(() => _buildActiveFiltersCount()),
                  Icon(
                    _filtersExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.primaryBlue,
                  ),
                ],
              ),
            ),
          ),

          // ================= COLLAPSIBLE CONTENT =================
          if (_filtersExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // -------- ROW 1 --------
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _responsiveFilter(
                        _buildDropdownFilter(
                          'Academic Year',
                          controller.selectedAcademicYear,
                          ['2023-2024', '2024-2025', '2025-2026'],
                        ),
                      ),
                      _responsiveFilter(
                        _buildDropdownFilter(
                          'Transaction Type',
                          controller.selectedTransactionType,
                          ['CREDIT', 'DEBIT'],
                        ),
                      ),
                      _responsiveFilter(
                        _buildDropdownFilter(
                          'Account Type',
                          controller.selectedAccountType,
                          ['student_fee', 'expense', 'other'],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // -------- ROW 2 --------
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _responsiveFilter(
                        _buildDropdownFilter(
                          'Status',
                          controller.selectedStatus,
                          ['active', 'cancelled'],
                        ),
                      ),
                      _responsiveFilter(
                        _buildDropdownFilter(
                          'Payment Mode',
                          controller.selectedPaymentMode,
                          ['cash', 'online', 'cheque', 'card'],
                        ),
                      ),
                      _responsiveFilter(
                        _buildDropdownFilter(
                          'Section',
                          controller.selectedSection,
                          ['student_record', 'expense', 'other'],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // -------- DATE RANGE --------
                  const Text(
                    'Date Range',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _responsiveFilter(
                        Obx(() => _buildDatePicker(
                          'From Date',
                          controller.fromDate.value,
                              (date) => controller.fromDate.value = date,
                        )),
                      ),
                      _responsiveFilter(
                        Obx(() => _buildDatePicker(
                          'To Date',
                          controller.toDate.value,
                              (date) => controller.toDate.value = date,
                        )),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // -------- ACTION BUTTONS --------
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 200,
                        child: ElevatedButton.icon(
                          onPressed: _applyFilters,
                          icon: const Icon(Icons.search),
                          label: const Text('Apply Filters'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 160,
                        child: OutlinedButton.icon(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.primaryBlue),
                            foregroundColor: AppTheme.primaryBlue,
                          ),
                        ),
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
  Widget _responsiveFilter(Widget child) {
    final width = MediaQuery.of(context).size.width;

    double maxWidth;
    if (width >= 1200) {
      maxWidth = (width - 64) / 3; // 3 per row
    } else if (width >= 800) {
      maxWidth = (width - 64) / 2; // 2 per row
    } else {
      maxWidth = width; // 1 per row
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    );
  }

  Widget _buildActiveFiltersCount() {
    int activeCount = 0;
    if (controller.selectedAcademicYear.value != null) activeCount++;
    if (controller.selectedTransactionType.value != null) activeCount++;
    if (controller.selectedAccountType.value != null) activeCount++;
    if (controller.selectedStatus.value != null) activeCount++;
    if (controller.selectedPaymentMode.value != null) activeCount++;
    if (controller.selectedSection.value != null) activeCount++;
    if (controller.fromDate.value != null) activeCount++;
    if (controller.toDate.value != null) activeCount++;

    return activeCount > 0
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$activeCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        : const SizedBox();
  }

  Widget _buildDropdownFilter(String label, Rx<String?> selectedValue, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Obx(() => DropdownButtonFormField<String>(
          value: selectedValue.value,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('All', style: TextStyle(fontSize: 14)),
            ),
            ...options.map((option) => DropdownMenuItem<String>(
              value: option,
              child: Text(option, style: const TextStyle(fontSize: 14)),
            )),
          ],
          onChanged: (value) => selectedValue.value = value,
        )),
      ],
    );
  }

  Widget _buildDatePicker(String label, DateTime? selectedDate, Function(DateTime?) onDateSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (pickedDate != null) {
              onDateSelected(pickedDate);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedDate != null
                        ? DateFormat('dd/MM/yyyy').format(selectedDate)
                        : 'Select date',
                    style: TextStyle(
                      color: selectedDate != null ? Colors.black : Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _applyFilters() async {
    final schoolId = authController.user.value?.schoolId;
    if (schoolId != null) {
      await controller.applyFilters(schoolId);
      Get.snackbar(
        'Success',
        'Filters applied successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  }

  void _clearFilters() {
    controller.clearFilters();
    final schoolId = authController.user.value?.schoolId;
    if (schoolId != null) {
      controller.getAllTransactions(schoolId: schoolId);
    }
    setState(() {
      _filtersExpanded = false;
    });
    Get.snackbar(
      'Success',
      'Filters cleared',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }
}