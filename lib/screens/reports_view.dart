import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/accounting_controller.dart';

// Professional light-blue theme constants
const _kBg = Color(0xFFF0F5FF);
const _kBlue = Color(0xFF2563EB);
const _kBlueDark = Color(0xFF1A2A3A);
const _kBlueMuted = Color(0xFF90A4BE);
const _kBlueBorder = Color(0xFFDDE6F5);

class ReportsView extends GetView<AccountingController> {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        top: true,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 20 : 12,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReportTypeSelector(),
                    const SizedBox(height: 12),
                    _buildDateRangeSelector(),
                    const SizedBox(height: 12),
                    _buildGenerateButton(context),
                    const SizedBox(height: 16),
                    _buildReportContent(context, isTablet),
                  ],
                ),
              ),
            ),
          ],
        ),
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
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: _kBlue.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: _kBlue, size: 16),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _kBlue.withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.assessment_rounded, color: _kBlue, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Reports & Analytics', style: TextStyle(color: _kBlueDark, fontSize: 15, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                Text('Financial insights & summaries', style: TextStyle(color: _kBlueMuted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTypeSelector() {
    final reports = [
      ('Fee Pending', 'fee_pending', Icons.pending_actions_rounded),
      ('Fee Collection', 'fee_collection', Icons.account_balance_wallet_rounded),
      ('Expenses', 'expenses', Icons.receipt_long_rounded),
      ('Concessions', 'concessions', Icons.discount_rounded),
      ('Income vs Expense', 'income_expense', Icons.analytics_rounded),
    ];
    return _card(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Select Report Type', Icons.bar_chart_rounded),
        const SizedBox(height: 12),
        Obx(() => Wrap(spacing: 8, runSpacing: 8, children: reports.map((r) => _reportChip(r.$1, r.$2, r.$3)).toList())),
      ],
    ));
  }

  Widget _reportChip(String label, String value, IconData icon) {
    return Obx(() {
      final selected = controller.selectedReportType.value == value;
      return GestureDetector(
        onTap: () => controller.selectedReportType.value = value,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? _kBlue : _kBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? _kBlue : _kBlueBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: selected ? Colors.white : _kBlueMuted),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : _kBlueDark)),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildDateRangeSelector() {
    final ranges = [('This Month', 'this_month'), ('Last Month', 'last_month'), ('This Year', 'this_year'), ('Custom', 'custom')];
    return _card(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Date Range', Icons.calendar_month_rounded),
        const SizedBox(height: 12),
        Obx(() => Wrap(spacing: 8, runSpacing: 8, children: ranges.map((r) => _dateChip(r.$1, r.$2)).toList())),
      ],
    ));
  }

  Widget _dateChip(String label, String value) {
    return Obx(() {
      final selected = controller.selectedDateRange.value == value;
      return GestureDetector(
        onTap: () => controller.selectedDateRange.value = value,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? _kBlue.withOpacity(0.12) : _kBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? _kBlue : _kBlueBorder),
          ),
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? _kBlue : _kBlueDark)),
        ),
      );
    });
  }

  Widget _buildGenerateButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: _kBlue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: () => _generateReport(context),
          icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
          label: const Text('Generate Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        ),
      ),
    );
  }

  Widget _buildReportContent(BuildContext context, bool isTablet) {
    return Obx(() {
      switch (controller.selectedReportType.value) {
        case 'fee_pending': return _buildFeePendingReport(isTablet);
        case 'fee_collection': return _buildFeeCollectionReport(isTablet);
        case 'expenses': return _buildExpensesReport(isTablet);
        case 'concessions': return _buildConcessionsReport(isTablet);
        case 'income_expense': return _buildIncomeExpenseReport(isTablet);
        default: return _buildDefaultReport();
      }
    });
  }

  Widget _buildFeePendingReport(bool isTablet) {
    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _reportHeader('Fee Pending Report', Icons.pending_actions_rounded, const Color(0xFFF59E0B)),
      const SizedBox(height: 14),
      _statsRow([_stat('Total Pending', '₹2,45,000', const Color(0xFFEF4444), Icons.money_off_rounded), _stat('Students', '156', const Color(0xFFF59E0B), Icons.people_rounded)]),
      const SizedBox(height: 14),
      _sectionLabel('Class-wise Breakdown'),
      const SizedBox(height: 8),
      _classRow('Class 10', '₹45,000', 25),
      _classRow('Class 9', '₹38,000', 22),
      _classRow('Class 8', '₹32,000', 18),
    ]));
  }

  Widget _buildFeeCollectionReport(bool isTablet) {
    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _reportHeader('Fee Collection Report', Icons.account_balance_wallet_rounded, const Color(0xFF22C55E)),
      const SizedBox(height: 14),
      _statsRow([_stat('Total Collected', '₹8,75,000', const Color(0xFF22C55E), Icons.trending_up_rounded), _stat('Receipts', '342', _kBlue, Icons.receipt_rounded)]),
      const SizedBox(height: 14),
      _sectionLabel('Payment Mode Breakdown'),
      const SizedBox(height: 8),
      _progressRow('Cash', '₹4,25,000', 48.6, const Color(0xFF2563EB)),
      _progressRow('UPI', '₹2,85,000', 32.6, const Color(0xFF7C3AED)),
      _progressRow('Cheque', '₹1,45,000', 16.6, const Color(0xFF0891B2)),
      _progressRow('Bank Transfer', '₹20,000', 2.2, const Color(0xFF059669)),
    ]));
  }

  Widget _buildExpensesReport(bool isTablet) {
    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _reportHeader('Expenses Report', Icons.receipt_long_rounded, const Color(0xFFEF4444)),
      const SizedBox(height: 14),
      _statsRow([_stat('Total Expenses', '₹3,45,000', const Color(0xFFEF4444), Icons.money_off_rounded), _stat('Pending', '12', const Color(0xFFF59E0B), Icons.pending_rounded)]),
      const SizedBox(height: 14),
      _sectionLabel('Category-wise Expenses'),
      const SizedBox(height: 8),
      _progressRow('Salary', '₹1,85,000', 53.6, const Color(0xFF2563EB)),
      _progressRow('EB', '₹65,000', 18.8, const Color(0xFF0891B2)),
      _progressRow('Maintenance', '₹45,000', 13.0, const Color(0xFF7C3AED)),
      _progressRow('Fuel', '₹35,000', 10.1, const Color(0xFF059669)),
      _progressRow('Operations', '₹15,000', 4.3, const Color(0xFFF59E0B)),
    ]));
  }

  Widget _buildConcessionsReport(bool isTablet) {
    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _reportHeader('Concessions Report', Icons.discount_rounded, const Color(0xFF8B5CF6)),
      const SizedBox(height: 14),
      _statsRow([_stat('Total Concessions', '₹85,000', const Color(0xFF8B5CF6), Icons.discount_rounded), _stat('Students', '28', _kBlue, Icons.people_rounded)]),
      const SizedBox(height: 14),
      _sectionLabel('Concession Types'),
      const SizedBox(height: 8),
      _concessionRow('Staff Child – 50%', '₹25,000', 'With Proof'),
      _concessionRow('Sibling Discount – 25%', '₹18,000', 'With Proof'),
      _concessionRow('Merit Scholarship – 30%', '₹22,000', 'With Proof'),
      _concessionRow('Financial Aid – 100%', '₹20,000', 'Verified'),
    ]));
  }

  Widget _buildIncomeExpenseReport(bool isTablet) {
    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _reportHeader('Income vs Expense', Icons.analytics_rounded, _kBlue),
      const SizedBox(height: 14),
      _statsRow([_stat('Total Income', '₹8,75,000', const Color(0xFF22C55E), Icons.trending_up_rounded), _stat('Total Expense', '₹3,45,000', const Color(0xFFEF4444), Icons.trending_down_rounded)]),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [_kBlue.withOpacity(0.08), _kBlue.withOpacity(0.04)]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBlue.withOpacity(0.2)),
        ),
        child: Column(children: [
          const Text('Net Profit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kBlueDark)),
          const SizedBox(height: 6),
          const Text('₹5,30,000', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _kBlue)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF22C55E).withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: const Text('Profit Margin: 60.6%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
          ),
        ]),
      ),
    ]));
  }

  Widget _buildDefaultReport() {
    return _card(child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(child: Column(children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: _kBlue.withOpacity(0.08), shape: BoxShape.circle),
          child: const Icon(Icons.analytics_rounded, size: 48, color: _kBlue),
        ),
        const SizedBox(height: 16),
        const Text('Select a report type above', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kBlueDark)),
        const SizedBox(height: 4),
        const Text('Choose a report and date range to generate insights', style: TextStyle(fontSize: 12, color: _kBlueMuted), textAlign: TextAlign.center),
      ])),
    ));
  }

  // ─── Shared helpers ──────────────────────────────────────────────────────────
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBlueBorder),
        boxShadow: [BoxShadow(color: _kBlueBorder.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: _kBlue.withOpacity(0.10), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: _kBlue, size: 16),
      ),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kBlueDark)),
    ]);
  }

  Widget _sectionLabel(String label) {
    return Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kBlueMuted, letterSpacing: 0.4));
  }

  Widget _reportHeader(String title, IconData icon, Color color) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kBlueDark))),
    ]);
  }

  Widget _statsRow(List<Widget> stats) {
    return Row(
      children: stats.expand((w) => [Expanded(child: w), const SizedBox(width: 10)]).toList()..removeLast(),
    );
  }

  Widget _stat(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: _kBlueMuted), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
      ]),
    );
  }

  Widget _progressRow(String label, String amount, double pct, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 12, color: _kBlueDark), maxLines: 1, overflow: TextOverflow.ellipsis)),
        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct / 100, backgroundColor: _kBlueBorder, valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 6))),
        const SizedBox(width: 8),
        SizedBox(width: 72, child: Text(amount, textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color))),
      ]),
    );
  }

  Widget _classRow(String cls, String amount, int students) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: _kBlueBorder)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.class_rounded, color: Color(0xFFF59E0B), size: 16)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(cls, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kBlueDark)),
          Text('$students students', style: const TextStyle(fontSize: 10, color: _kBlueMuted)),
        ])),
        Text(amount, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
      ]),
    );
  }

  Widget _concessionRow(String type, String amount, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: _kBlueBorder)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.discount_rounded, color: Color(0xFF8B5CF6), size: 16)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(type, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kBlueDark)),
          Text(status, style: const TextStyle(fontSize: 10, color: _kBlueMuted)),
        ])),
        Text(amount, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF8B5CF6))),
      ]),
    );
  }

  void _generateReport(BuildContext context) {
    Get.snackbar(
      'Report Generated',
      'Report for ${controller.selectedReportType.value.replaceAll('_', ' ').toUpperCase()} is ready',
      backgroundColor: _kBlue,
      colorText: Colors.white,
      borderRadius: 12,
      margin: const EdgeInsets.all(12),
      snackPosition: SnackPosition.TOP,
    );
  }
}
