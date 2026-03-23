import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:school_app/controllers/finance_ledger_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';

class TransactionDetailView extends StatefulWidget {
  const TransactionDetailView({Key? key}) : super(key: key);

  @override
  State<TransactionDetailView> createState() => _TransactionDetailViewState();
}

class _TransactionDetailViewState extends State<TransactionDetailView> {
  final FinanceLedgerController controller = Get.put(FinanceLedgerController());

  @override
  void initState() {
    super.initState();
    // Defer API call until after build is complete to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final transactionId = Get.arguments as String?;
      if (transactionId != null) {
        controller.getTransaction(transactionId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Obx(() {
          final transaction = controller.selectedTransaction.value;
          if (transaction == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Transaction Type Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: transaction['transactionType'] == 'CREDIT'
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: transaction['transactionType'] == 'CREDIT'
                        ? Colors.green
                        : Colors.red,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      transaction['transactionType'] == 'CREDIT'
                          ? Icons.trending_up
                          : Icons.trending_down,
                      size: 48,
                      color: transaction['transactionType'] == 'CREDIT'
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      transaction['transactionType'] == 'CREDIT' ? 'INCOME' : 'EXPENSE',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: transaction['transactionType'] == 'CREDIT'
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${_formatAmount(transaction['amount'])}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: transaction['transactionType'] == 'CREDIT'
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: transaction['status'] == 'active'
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: transaction['status'] == 'active'
                              ? Colors.blue
                              : Colors.orange,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        transaction['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: transaction['status'] == 'active'
                              ? Colors.blue
                              : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Transaction Details
              _buildSectionTitle('Transaction Details'),
              _buildInfoCard([
                _buildInfoRow('Transaction ID', transaction['_id']),
                _buildInfoRow('Transaction Type', transaction['transactionType'] ?? 'N/A'),
                _buildInfoRow('Amount', '₹${_formatAmount(transaction['amount'])}'),
                _buildInfoRow('Date', _formatDate(transaction['date'])),
                _buildInfoRow('Category', transaction['category'] ?? 'N/A'),
                _buildInfoRow('Section', transaction['section'] ?? 'N/A'),
                _buildInfoRow('Payment Mode', transaction['paymentMode'] ?? 'N/A'),
                _buildInfoRow('Status', transaction['status'] ?? 'N/A'),
                _buildInfoRow('Academic Year', transaction['academicYear'] ?? 'N/A'),
              ]),

              const SizedBox(height: 16),

              // Description
              if (transaction['description'] != null && transaction['description'].toString().isNotEmpty) ...[
                _buildSectionTitle('Description'),
                _buildInfoCard([
                  _buildInfoRow('Details', transaction['description']),
                ]),
                const SizedBox(height: 16),
              ],

              // Expense Details (if reference is an expense)
              if (transaction['referenceModel'] == 'ExpenseModel' &&
                  transaction['referenceId'] != null) ...[
                _buildSectionTitle('Expense Details'),
                _buildInfoCard([
                  _buildInfoRow('Expense No', transaction['referenceId']['expenseNo']),
                  _buildInfoRow('Category', transaction['referenceId']['category']),
                  _buildInfoRow('Amount', '₹${_formatAmount(transaction['referenceId']['amount'])}'),
                  _buildInfoRow('Payment Mode', transaction['referenceId']['paymentMode']),
                  _buildInfoRow('Date', _formatDate(transaction['referenceId']['date'])),
                  _buildInfoRow('Verification Status', transaction['referenceId']['verificationStatus']),
                  if (transaction['referenceId']['remarks'] != null &&
                      transaction['referenceId']['remarks'].toString().isNotEmpty)
                    _buildInfoRow('Remarks', transaction['referenceId']['remarks']),
                ]),
                const SizedBox(height: 16),
              ],

              // Student Information (if available - for fee transactions)
              if (transaction['studentRecordId'] != null) ...[
                _buildSectionTitle('Student Information'),
                _buildInfoCard([
                  _buildInfoRow('Student Name', controller.getStudentDisplayName()),
                  _buildInfoRow('Class', transaction['studentRecordId']['className'] ?? 'N/A'),
                  _buildInfoRow('Section', transaction['studentRecordId']['sectionName'] ?? 'N/A'),
                  if (controller.studentDetails.value != null) ...[
                    _buildInfoRow('Roll Number', controller.studentDetails.value!['rollNumber']?.toString() ?? 'N/A'),
                    _buildInfoRow('SR ID', controller.studentDetails.value!['studentId']?['srId'] ?? 'N/A'),
                    _buildInfoRow('Student Type', controller.studentDetails.value!['newOld']?.toString().toUpperCase() ?? 'N/A'),
                  ],
                ]),
                const SizedBox(height: 16),
              ],

              // Receipt Details (if available)
              if (transaction['feeReceiptId'] != null) ...[
                _buildSectionTitle('Receipt Details'),
                _buildInfoCard([
                  _buildInfoRow('Receipt No', transaction['feeReceiptId']['receiptNo'] ?? 'N/A'),
                  _buildInfoRow('Payment Date', _formatDate(transaction['feeReceiptId']['paymentDate'])),
                  _buildInfoRow('Payment Mode', transaction['feeReceiptId']['paymentMode'] ?? 'N/A'),
                  _buildInfoRow('Amount Paid', '₹${_formatAmount(transaction['feeReceiptId']['amountPaid'])}'),
                  if (transaction['feeReceiptId']['allocation'] != null) ...[
                    _buildInfoRow('Fee Allocation', _buildAllocationText(transaction['feeReceiptId']['allocation'])),
                  ],
                  if (transaction['feeReceiptId']['cashDenominations'] != null) ...[
                    _buildInfoRow('Cash Denominations', _buildDenominationsText(transaction['feeReceiptId']['cashDenominations'])),
                  ],
                ]),
                const SizedBox(height: 16),
              ],

              // Payment Proofs (always show card if receipt exists, even if empty)
              if (transaction['feeReceiptId'] != null) ...[
                _buildSectionTitle('Payment Proofs'),
                _buildProofSection(
                  (transaction['feeReceiptId']['proofUpload'] as List?) ?? [],
                  title: 'Uploaded Images',
                  emptyMessage: 'No proofs found',
                ),
                const SizedBox(height: 16),
              ],

              // Expense Bills & Work Photos (for expense references)
              if (transaction['referenceModel'] == 'ExpenseModel' &&
                  transaction['referenceId'] != null) ...[
                _buildSectionTitle('Expense Bills'),
                _buildProofSection(
                  (transaction['referenceId']['bill'] as List?) ?? [],
                  title: 'Bills',
                  emptyMessage: 'No bills found',
                ),
                const SizedBox(height: 16),
                _buildSectionTitle('Work Photos'),
                _buildProofSection(
                  (transaction['referenceId']['workPhoto'] as List?) ?? [],
                  title: 'Work Photos',
                  emptyMessage: 'No work photos found',
                ),
                const SizedBox(height: 16),
              ],

              // Reference Information
              _buildSectionTitle('Reference Information'),
              _buildInfoCard([
                _buildInfoRow('Reference Model', transaction['referenceModel'] ?? 'N/A'),
                // Show reference id as string if it's a map or plain id
                _buildInfoRow(
                  'Reference ID',
                  transaction['referenceId'] is Map
                      ? (transaction['referenceId']['_id']?.toString() ?? 'N/A')
                      : (transaction['referenceId']?.toString() ?? 'N/A'),
                ),
                _buildInfoRow('School ID', transaction['schoolId'] ?? 'N/A'),
              ]),

              const SizedBox(height: 16),

              // Created By Information
              if (transaction['createdBy'] != null) ...[
                _buildSectionTitle('Created By'),
                _buildInfoCard([
                  _buildInfoRow('User ID', transaction['createdBy']['_id'] ?? 'N/A'),
                  _buildInfoRow('User Name', transaction['createdBy']['userName'] ?? 'N/A'),
                  _buildInfoRow('Role', transaction['createdBy']['role'] ?? 'N/A'),
                ]),
                const SizedBox(height: 16),
              ],

              // Cancellation Information (if applicable)
              if (transaction['status'] == 'cancelled') ...[
                _buildSectionTitle('Cancellation Details'),
                _buildInfoCard([
                  _buildInfoRow('Reason', transaction['cancellationReason'] ?? 'N/A'),
                  if (transaction['cancelledBy'] != null) ...[
                    _buildInfoRow('Cancelled By', transaction['cancelledBy']['userName'] ?? 'N/A'),
                    _buildInfoRow('Cancelled By Role', transaction['cancelledBy']['role'] ?? 'N/A'),
                  ],
                ]),
                const SizedBox(height: 16),
              ],

              // System Information
              _buildSectionTitle('System Information'),
              _buildInfoCard([
                _buildInfoRow('Version', transaction['__v']?.toString() ?? 'N/A'),
                _buildInfoRow('Created At', _formatDate(transaction['createdAt'])),
                _buildInfoRow('Updated At', _formatDate(transaction['updatedAt'])),
                if (transaction['cancelledBy'] != null)
                  _buildInfoRow('Cancelled At', _formatDate(transaction['cancelledBy']?['updatedAt'] ?? transaction['updatedAt'])),
              ]),
            ],
          ),
          );
        }),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value == null
                  ? 'N/A'
                  : value is String
                      ? value
                      : value.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr.toString());
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (e) {
      return dateStr.toString();
    }
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    final num value = amount is String ? double.tryParse(amount) ?? 0 : amount;
    return value.toStringAsFixed(0);
  }

  String _buildAllocationText(List<dynamic> allocation) {
    if (allocation.isEmpty) return 'N/A';
    return allocation.map((item) => '${item['feeHead']}: ₹${_formatAmount(item['amount'])}').join(', ');
  }

  String _buildDenominationsText(List<dynamic> denominations) {
    if (denominations.isEmpty) return 'N/A';
    return denominations.map((item) => '₹${item['label']} x ${item['count']}').join(', ');
  }

  Widget _buildProofSection(
    List<dynamic> proofs, {
    String title = 'Uploaded Images',
    String emptyMessage = 'No proofs found',
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title (${proofs.length})',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            if (proofs.isEmpty)
              Text(
                emptyMessage,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: proofs.map((proof) => _buildProofImage(proof)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProofImage(Map<String, dynamic> proof) {
    return GestureDetector(
      onTap: () => _showFullImage(proof['url']),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            proof['url'] ?? '',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.image_not_supported,
              color: Colors.grey,
            ),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showFullImage(String? imageUrl) {
    if (imageUrl == null) return;
    
    Get.dialog(
      Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: Get.height * 0.8,
            maxWidth: Get.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Payment Proof'),
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Expanded(
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Text('Failed to load image'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
