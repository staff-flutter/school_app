import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/accounting_controller.dart';
import 'package:school_app/controllers/finance_ledger_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'dart:math' as math;

class AccountingDashboardView extends StatefulWidget {
  const AccountingDashboardView({super.key});

  @override
  State<AccountingDashboardView> createState() => _AccountingDashboardViewState();
}

class _AccountingDashboardViewState extends State<AccountingDashboardView> with TickerProviderStateMixin {
  final AuthController _authController = Get.find<AuthController>();
  final FinanceLedgerController _financeController = Get.find<FinanceLedgerController>();
  final AccountingController _accountingController = Get.find<AccountingController>();

  // Chart data
  Map<String, double> _expenseCategories = {};
  Map<String, double> _monthlyTrends = {};
  bool _chartsLoaded = false;
  
  // Sample recent transactions (display only - no navigation)
  final List<Map<String, dynamic>> _sampleTransactions = [
    {'description': 'Fee Collection - Class X', 'amount': 45000, 'type': 'income', 'date': 'Today, 10:30 AM'},
    {'description': 'Infrastructure Expense', 'amount': 12000, 'type': 'expense', 'date': 'Today, 9:15 AM'},
    {'description': 'Fee Collection - Class IX', 'amount': 38000, 'type': 'income', 'date': 'Yesterday'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFinanceStats();
      _loadChartData();
    });
  }

  void _loadFinanceStats() {
    final userRole = _authController.user.value?.role.toLowerCase() ?? '';
    if (userRole == 'correspondent' || userRole == 'accountant') {
      final schoolId = _authController.user.value?.schoolId;
      if (schoolId != null) {
        _financeController.getFinanceStats(schoolId: schoolId, range: 'today');
      }
    }
  }

  void _loadChartData() {
    _expenseCategories = {
      'Salaries': 45.0,
      'Infrastructure': 20.0,
      'Utilities': 12.0,
      'Supplies': 10.0,
      'Maintenance': 8.0,
      'Others': 5.0,
    };

    _monthlyTrends = {
      'Jan': 125000,
      'Feb': 148000,
      'Mar': 132000,
      'Apr': 167000,
      'May': 189000,
      'Jun': 156000,
    };

    setState(() {
      _chartsLoaded = true;
    });
  }

  void _showFullScreenProfileImage() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    (_authController.user.value?.userName ?? 'U').substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: const Color(0xFF2563EB),
                      fontWeight: FontWeight.bold,
                      fontSize: 120,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 40,
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.black,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenSchoolLogo(String logoUrl) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.9),
                child: Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.network(
                      logoUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        Get.back();
                        Get.snackbar(
                          'Error',
                          'Failed to load logo',
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 50,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolLogo() {
    try {
      final school = _authController.userSchool.value;
      if (school != null && school['logo'] != null && school['logo']['url'] != null) {
        return GestureDetector(
          onTap: () => _showFullScreenSchoolLogo(school['logo']['url']),
          child: Image.network(
            school['logo']['url'],
            width: 32,
            height: 32,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.school_rounded,
                color: Color(0xFF2563EB),
                size: 30,
              );
            },
          ),
        );
      }
    } catch (e) {
      // Handle error silently
    }

    return const Icon(
      Icons.school_rounded,
      color: Color(0xFF2563EB),
      size: 30,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFF0F5FF),
        body: SafeArea(
          top: true,
          child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              // Top header bar (replaces removed AppBar)
              _buildInlineHeader(),
              const SizedBox(height: 8),
              Flexible(
                flex: 25,
                child: _buildExpenseBreakdownChart(),
              ),
              Flexible(
                flex: 20,
                child: _buildFinanceStatsSection(),
              ),
              Flexible(
                flex: 25,
                child: _buildMonthlyTrendChart(),
              ),
              Flexible(
                flex: 30,
                child: _buildRecentTransactionsSection(),
              ),
            ],
          ),
        ),
        ),
    );
  }


Widget _buildInlineHeader() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFDDE6F5).withOpacity(0.5),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        _buildSchoolLogo(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(() {
                final school = _authController.userSchool.value;
                final schoolName = school?['name'] ?? 'School';
                return Text(
                  schoolName,
                  style: const TextStyle(
                    color: Color(0xFF1A2A3A),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                );
              }),
              Text(
                'Welcome, ${_authController.user.value?.userName ?? 'User'}',
                style: const TextStyle(
                  color: Color(0xFF90A4BE),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildFinanceStatsSection() {
  final userRole = _authController.user.value?.role.toLowerCase() ?? '';
  if (userRole != 'correspondent' && userRole != 'accountant') {
    return const SizedBox.shrink();
  }

  return Obx(() {
    final stats = _financeController.stats.value;
    final isLoading = _financeController.isLoading.value;

    if (isLoading || stats == null) {
      return _compactCard(
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return _compactCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Logic for responsive columns
          final isWide = constraints.maxWidth > 600;
          final crossAxisCount = isWide ? 4 : 2;
          final childAspectRatio = isWide ? 2.5 : 2.1;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withOpacity(0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.analytics,
                        color: const Color(0xFF2563EB),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Financial Overview',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  primary: false,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: childAspectRatio,
                  children: [
                    _buildCompactStatCard(
                      'Income',
                      stats['totalIncome'] ?? 0,
                      const Color(0xFF1D4ED8),
                      Icons.trending_up,
                    ),
                    _buildCompactStatCard(
                      'Expense',
                      stats['totalExpense'] ?? 0,
                      const Color(0xFF60A5FA),
                      Icons.trending_down,
                    ),
                    _buildCompactStatCard(
                      'Balance',
                      stats['netBalance'] ?? 0,
                      const Color(0xFF1E3A8A),
                      Icons.account_balance,
                    ),
                    _buildCompactStatCard(
                      'Count',
                      stats['transactionCount'] ?? 0,
                      const Color(0xFF2563EB),
                      Icons.countertops,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  });
}

Widget _buildCompactStatCard(
  String title,
  dynamic value,
  Color color,
  IconData icon,
) {
  final formattedValue = value is num ? '₹${value.toStringAsFixed(0)}' : '₹0';

  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.mutedText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formattedValue,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
  Widget _buildExpenseBreakdownChart() {
    if (!_chartsLoaded) {
      return _compactCard(child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))));
    }

    return _compactCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(gradient:  LinearGradient(colors: [const Color(0xFF1D4ED8), const Color(0xFF3B82F6)]), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.pie_chart, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 6),
              const Text('Expenses', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primaryText)),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: CustomPaint(painter: ExpensePieChartPainter(_expenseCategories, small: true), size: Size.infinite),
                  ),
                ),
                Expanded(flex: 2, child: _buildCompactExpenseLegend()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactExpenseLegend() {
    final colors = [const Color(0xFF1E3A8A), const Color(0xFF1D4ED8), const Color(0xFF2563EB), const Color(0xFF60A5FA), const Color(0xFF93C5FD), const Color(0xFFBFDBFE)];
    int index = 0;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _expenseCategories.entries.map((entry) {
          final color = colors[index % colors.length];
          index++;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 4),
                Expanded(child: Text(entry.key, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: AppTheme.primaryText), maxLines: 1, overflow: TextOverflow.ellipsis)),
                Text('${entry.value.toInt()}%', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthlyTrendChart() {
    if (!_chartsLoaded) {
      return _compactCard(child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))));
    }

    return _compactCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(gradient:  LinearGradient(colors: [const Color(0xFF1E40AF), const Color(0xFF3B82F6)]), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.bar_chart, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 6),
              const Text('Trend', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primaryText)),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Column(
              children: [
                Expanded(child: CustomPaint(painter: MonthlyBarChartPainter(_monthlyTrends, small: true), size: Size.infinite)),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _monthlyTrends.keys.map((month) => Text(month, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.primaryText))).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsSection() {
    final transactions = _sampleTransactions;
    return _compactCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(gradient:  LinearGradient(colors: [const Color(0xFF1D4ED8), const Color(0xFF60A5FA)]), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.receipt_long, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 6),
              const Text('Recent', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primaryText)),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: transactions.isEmpty
                ? const Center(child: Text('No transactions', style: TextStyle(color: AppTheme.mutedText, fontSize: 11)))
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactions.length,
                    separatorBuilder: (_, __) => Divider(color: AppTheme.dividerColor.withOpacity(0.3), height: 1),
                    itemBuilder: (context, index) => _buildCompactTransactionRow(transactions[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTransactionRow(dynamic txn) {
    final isIncome = (txn['type'] ?? '').toString().toLowerCase() == 'income';
    final color = isIncome ? const Color(0xFF1D4ED8) : const Color(0xFF60A5FA);
    final icon = isIncome ? Icons.arrow_downward : Icons.arrow_upward;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]), borderRadius: BorderRadius.circular(6)),
            child: Icon(icon, color: Colors.white, size: 12),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(txn['description'] ?? 'Transaction', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryText), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(txn['date'] ?? '', style: const TextStyle(fontSize: 9, color: AppTheme.mutedText)),
              ],
            ),
          ),
          Text('₹${(txn['amount'] ?? 0).toStringAsFixed(0)}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  // Compact card wrapper for single-screen layout
  Widget _compactCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}

class ExpensePieChartPainter extends CustomPainter {
  final Map<String, double> categories;
  final bool small;
  ExpensePieChartPainter(this.categories, {this.small = false});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - (small ? 8 : 20);
    final colors = [const Color(0xFF1E3A8A), const Color(0xFF1D4ED8), const Color(0xFF2563EB), const Color(0xFF60A5FA), const Color(0xFF93C5FD), const Color(0xFFBFDBFE)];
    double startAngle = -math.pi / 2;
    final total = categories.values.fold<double>(0, (sum, val) => sum + val);
    int index = 0;
    
    for (final entry in categories.entries) {
      final sweepAngle = (entry.value / total) * 2 * math.pi;
      final paint = Paint()..color = colors[index % colors.length]..style = PaintingStyle.fill;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
      index++;
    }
    
    final innerRadius = radius * 0.55;
    canvas.drawCircle(center, innerRadius, Paint()..color = Colors.white..style = PaintingStyle.fill);
    
    final textPainter = TextPainter(
      text: TextSpan(text: small ? 'Exp' : 'Expenses', style: TextStyle(color: AppTheme.primaryText, fontSize: small ? 9 : 13, fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2));
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MonthlyBarChartPainter extends CustomPainter {
  final Map<String, double> data;
  final bool small;
  MonthlyBarChartPainter(this.data, {this.small = false});
  
  @override
  void paint(Canvas canvas, Size size) {
    final padding = small ? 8.0 : 16.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2 - (small ? 12 : 20);
    final maxValue = data.values.reduce(math.max);
    final barWidth = chartWidth / data.length - (small ? 4 : 12);
    final colors = [const Color(0xFF1E3A8A), const Color(0xFF1D4ED8), const Color(0xFF2563EB), const Color(0xFF60A5FA), const Color(0xFF93C5FD), const Color(0xFFBFDBFE)];
    
    int index = 0;
    double startX = padding;
    
    for (final entry in data.entries) {
      final barHeight = maxValue > 0 ? (entry.value / maxValue) * chartHeight : 0.toDouble();
      final rect = Rect.fromLTWH(startX, size.height - padding - barHeight - (small ? 12 : 20), barWidth, barHeight);
      final paint = Paint()
        ..shader = LinearGradient(colors: [colors[index % colors.length], colors[index % colors.length].withOpacity(0.6)], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(rect)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(small ? 3 : 6)), paint);
      
      if (!small) {
        final textPainter = TextPainter(
          text: TextSpan(text: '₹${(entry.value / 1000).toStringAsFixed(0)}k', style: const TextStyle(color: AppTheme.primaryText, fontSize: 10, fontWeight: FontWeight.w600)),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(startX + barWidth / 2 - textPainter.width / 2, size.height - padding - barHeight - 25));
      }
      
      startX += barWidth + (small ? 4 : 12);
      index++;
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}