import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/accounting_controller.dart';
import '../../../core/theme/app_theme.dart';

class ReportsView extends GetView<AccountingController> {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Report Type Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Report Type',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      Obx(
                        () => Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildReportChip('Fee Pending', 'fee_pending'),
                            _buildReportChip(
                                'Fee Collection', 'fee_collection'),
                            _buildReportChip('Expenses', 'expenses'),
                            _buildReportChip('Concessions', 'concessions'),
                            _buildReportChip(
                                'Income vs Expense', 'income_expense'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Filters
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filters',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Date Range',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Obx(
                        () => Wrap(
                          spacing: 8,
                          children: [
                            _buildDateRangeChip('This Month', 'this_month'),
                            _buildDateRangeChip('Last Month', 'last_month'),
                            _buildDateRangeChip('This Year', 'this_year'),
                            _buildDateRangeChip('Custom', 'custom'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Generate Report Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _generateReport(context),
                  icon: const Icon(Icons.analytics),
                  label: const Text('Generate Report'),
                ),
              ),

              const SizedBox(height: 24),

              // Report Content
              _buildReportContent(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: controller.selectedReportType.value == value,
      onSelected: (selected) {
        if (selected) controller.selectedReportType.value = value;
      },
    );
  }

  Widget _buildDateRangeChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: controller.selectedDateRange.value == value,
      onSelected: (selected) {
        if (selected) controller.selectedDateRange.value = value;
      },
    );
  }

  Widget _buildReportContent(BuildContext context) {
    return Obx(() {
      switch (controller.selectedReportType.value) {
        case 'fee_pending':
          return _buildFeePendingReport(context);
        case 'fee_collection':
          return _buildFeeCollectionReport(context);
        case 'expenses':
          return _buildExpensesReport(context);
        case 'concessions':
          return _buildConcessionsReport(context);
        case 'income_expense':
          return _buildIncomeExpenseReport(context);
        default:
          return _buildDefaultReport(context);
      }
    });
  }

  Widget _buildFeePendingReport(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pending_actions, color: AppTheme.warningYellow),
                const SizedBox(width: 8),
                Text(
                  'Fee Pending Report',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    'Total Pending',
                    '₹2,45,000',
                    AppTheme.errorRed,
                    Icons.money_off,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    'Students',
                    '156',
                    AppTheme.warningYellow,
                    Icons.people,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                _buildClassPendingItem(context, 'Class 10', '₹45,000', 25),
                _buildClassPendingItem(context, 'Class 9', '₹38,000', 22),
                _buildClassPendingItem(context, 'Class 8', '₹32,000', 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeCollectionReport(BuildContext context) {
    return SingleChildScrollView(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance_wallet,
                      color: AppTheme.successGreen),
                  const SizedBox(width: 8),
                  Text(
                    'Fee Collection Report',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      context,
                      'Total Collected',
                      '₹8,75,000',
                      AppTheme.successGreen,
                      Icons.trending_up,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      context,
                      'Receipts',
                      '342',
                      AppTheme.primaryBlue,
                      Icons.receipt,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Payment mode breakdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Mode Breakdown',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentModeItem('Cash', '₹4,25,000', 48.6),
                  _buildPaymentModeItem('UPI', '₹2,85,000', 32.6),
                  _buildPaymentModeItem('Cheque', '₹1,45,000', 16.6),
                  _buildPaymentModeItem('Bank Transfer', '₹20,000', 2.2),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpensesReport(BuildContext context) {
    return SingleChildScrollView(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.receipt_long, color: AppTheme.errorRed),
                  const SizedBox(width: 8),
                  Text(
                    'Expenses Report',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      context,
                      'Total Expenses',
                      '₹3,45,000',
                      AppTheme.errorRed,
                      Icons.money_off,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      context,
                      'Pending Verification',
                      '12',
                      AppTheme.warningYellow,
                      Icons.pending,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Category-wise breakdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category-wise Expenses',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildExpenseCategoryItem('Salary', '₹1,85,000', 53.6),
                  _buildExpenseCategoryItem('EB', '₹65,000', 18.8),
                  _buildExpenseCategoryItem('Maintenance', '₹45,000', 13.0),
                  _buildExpenseCategoryItem('Fuel', '₹35,000', 10.1),
                  _buildExpenseCategoryItem('Operations', '₹15,000', 4.3),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConcessionsReport(BuildContext context) {
    return SingleChildScrollView(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.discount, color: AppTheme.mathOrange),
                  const SizedBox(width: 8),
                  Text(
                    'Concessions Report',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      context,
                      'Total Concessions',
                      '₹85,000',
                      AppTheme.mathOrange,
                      Icons.discount,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      context,
                      'Students',
                      '28',
                      AppTheme.primaryBlue,
                      Icons.people,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  _buildConcessionItem(
                      context, 'Staff Child - 50%', '₹25,000', 'With Proof'),
                  _buildConcessionItem(
                      context, 'Sibling Discount - 25%', '₹18,000', 'With Proof'),
                  _buildConcessionItem(context, 'Merit Scholarship - 30%',
                      '₹22,000', 'With Proof'),
                  _buildConcessionItem(
                      context, 'Financial Aid - 100%', '₹20,000', 'Verified'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncomeExpenseReport(BuildContext context) {
    return SingleChildScrollView(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics, color: AppTheme.primaryBlue),
                  const SizedBox(width: 8),
                  Text(
                    'Income vs Expense',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      context,
                      'Total Income',
                      '₹8,75,000',
                      AppTheme.successGreen,
                      Icons.trending_up,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      context,
                      'Total Expense',
                      '₹3,45,000',
                      AppTheme.errorRed,
                      Icons.trending_down,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSummaryCard(
                context,
                'Net Profit',
                '₹5,30,000',
                AppTheme.primaryBlue,
                Icons.account_balance,
              ),
              const SizedBox(height: 16),

              // Profit margin indicator
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Profit Margin',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '60.6%',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: AppTheme.successGreen,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultReport(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Select a report type to view analytics',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value,
      Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassPendingItem(
      BuildContext context, String className, String amount, int students) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.warningYellow.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.class_, color: AppTheme.warningYellow),
      ),
      title: Text(className),
      subtitle: Text('$students students'),
      trailing: Text(
        amount,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.errorRed,
            ),
      ),
    );
  }

  Widget _buildPaymentModeItem(String mode, String amount, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(mode),
          ),
          Expanded(
            flex: 3,
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              amount,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCategoryItem(
      String category, String amount, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(category),
          ),
          Expanded(
            flex: 3,
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.errorRed),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              amount,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConcessionItem(
      BuildContext context, String type, String amount, String status) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.mathOrange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.discount, color: AppTheme.mathOrange),
      ),
      title: Text(type),
      subtitle: Text(status),
      trailing: Text(
        amount,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.mathOrange,
            ),
      ),
    );
  }

  void _generateReport(BuildContext context) {
    Get.snackbar(
      'Report Generated',
      'Report for ${controller.selectedReportType.value.replaceAll('_', ' ').toUpperCase()} has been generated',
    );
  }
}
