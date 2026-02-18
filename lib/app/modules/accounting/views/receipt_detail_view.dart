import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../controllers/student_record_controller.dart';

class ReceiptDetailView extends StatefulWidget {
  final Map<String, dynamic> receiptData;

  const ReceiptDetailView({Key? key, required this.receiptData}) : super(key: key);

  @override
  State<ReceiptDetailView> createState() => _ReceiptDetailViewState();
}

class _ReceiptDetailViewState extends State<ReceiptDetailView> {
  final StudentRecordController studentRecordController = Get.find<StudentRecordController>();
  Map<String, dynamic>? studentRecordData;
  bool isLoadingStudent = true;

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
  }

  Future<void> _fetchStudentData() async {
    try {
      final studentIdRaw = widget.receiptData['studentId'];
      final schoolId = widget.receiptData['schoolId'];

      // Extract studentId as string
      String? studentId;
      if (studentIdRaw is String) {
        studentId = studentIdRaw;
      } else if (studentIdRaw is Map<String, dynamic> && studentIdRaw.containsKey('_id')) {
        studentId = studentIdRaw['_id'] as String?;
      }

      if (studentId != null && schoolId != null) {
        
        final studentRecord = await studentRecordController.getStudentRecord(schoolId, studentId);
        if (studentRecord != null) {
          setState(() {
            studentRecordData = studentRecord;
            isLoadingStudent = false;
          });
          
        } else {
          setState(() {
            isLoadingStudent = false;
          });
        }
      } else {
        setState(() {
          isLoadingStudent = false;
        });
      }
    } catch (e) {
      
      setState(() {
        isLoadingStudent = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header
            _buildModernHeader(context, isTablet),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: isTablet ? 800 : double.infinity),
                    child: Column(
                      children: [
                        _buildStudentInfo(isTablet),
                        const SizedBox(height: 16),
                        _buildFeeStructure(isTablet),
                        const SizedBox(height: 16),
                        _buildPaymentInfo(isTablet),
                        const SizedBox(height: 16),
                        _buildProofUploads(isTablet),
                        if (widget.receiptData['receipts'] != null && (widget.receiptData['receipts'] as List).isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildReceiptsList(isTablet),
                        ],
                      ],
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

  Widget _buildModernHeader(BuildContext context, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryBlue, Colors.indigo.shade600],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.receipt_long,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student Fee Record',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 24 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _getStudentDisplayName(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: isTablet ? 16 : 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.receiptData['status'] == 'success' ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.receiptData['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentInfo(bool isTablet) {
    return _buildModernSection(
      'Student Information',
      Icons.person,
      isTablet,
      [
        _buildInfoRow('Student Name', _getStudentDisplayName(), isTablet),
        _buildInfoRow('Student ID', _getStudentId(), isTablet),
        _buildInfoRow('Class', _getClassName(), isTablet),
        _buildInfoRow('Section', _getSectionName(), isTablet),
        _buildInfoRow('Roll Number', widget.receiptData['rollNumber']?.toString() ?? 'N/A', isTablet),
        _buildInfoRow('Academic Year', widget.receiptData['academicYear'] ?? 'N/A', isTablet),
        _buildInfoRow('Student Type', widget.receiptData['newOld'] ?? 'N/A', isTablet),
        _buildInfoRow('Bus Applicable', widget.receiptData['isBusApplicable'] == true ? 'Yes' : 'No', isTablet),
      ],
    );
  }

  Widget _buildFeeStructure(bool isTablet) {
    final feeStructure = studentRecordData?['feeStructure'] as Map<String, dynamic>? ?? {};
    final feePaid = studentRecordData?['feePaid'] as Map<String, dynamic>? ?? {};
    final dues = studentRecordData?['dues'] as Map<String, dynamic>? ?? {};
    
    return _buildModernSection(
      'Fee Structure & Payment Status',
      Icons.account_balance_wallet,
      isTablet,
      [
        _buildFeeRow('Admission Fee', feeStructure['admissionFee'], feePaid['admissionFee'], dues['admissionDues'], isTablet),
        _buildFeeRow('First Term', feeStructure['firstTermAmt'], feePaid['firstTermAmt'], dues['firstTermDues'], isTablet),
        _buildFeeRow('Second Term', feeStructure['secondTermAmt'], feePaid['secondTermAmt'], dues['secondTermDues'], isTablet),
        _buildFeeRow('Bus First Term', feeStructure['busFirstTermAmt'], feePaid['busFirstTermAmt'], dues['busfirstTermDues'], isTablet),
        _buildFeeRow('Bus Second Term', feeStructure['busSecondTermAmt'], feePaid['busSecondTermAmt'], dues['busSecondTermDues'], isTablet),
        const Divider(),
        _buildTotalRow(feeStructure, feePaid, isTablet),
      ],
    );
  }

  Widget _buildPaymentInfo(bool isTablet) {
    final concession = studentRecordData?['concession'] as Map<String, dynamic>? ?? {};

    return _buildModernSection(
      'Payment Information',
      Icons.payment,
      isTablet,
      [
        _buildInfoRow('Payment Status', studentRecordData?['isFullyPaid'] == true ? 'Fully Paid' : 'Pending', isTablet,
            valueColor: studentRecordData?['isFullyPaid'] == true ? Colors.green : Colors.orange),
        _buildInfoRow('Active Status', studentRecordData?['isActive'] == true ? 'Active' : 'Inactive', isTablet,
            valueColor: studentRecordData?['isActive'] == true ? Colors.green : Colors.red),
        _buildInfoRow('Concession Applied', concession['isApplied'] == true ? 'Yes' : 'No', isTablet),
        if (concession['isApplied'] == true) ...[
          _buildInfoRow('Concession Type', concession['type'] ?? 'N/A', isTablet),
          _buildInfoRow('Concession Value', concession['value']?.toString() ?? 'N/A', isTablet),
          _buildInfoRow('Concession Amount', '₹${concession['inAmount'] ?? 0}', isTablet),
          _buildInfoRow('Concession Remark', concession['remark'] ?? 'N/A', isTablet),
        ],
      ],
    );
  }

  Widget _buildReceiptsList(bool isTablet) {
    final receipts = widget.receiptData['receipts'] as List? ?? [];
    
    return _buildModernSection(
      'Payment Receipts',
      Icons.receipt,
      isTablet,
      receipts.map<Widget>((receipt) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.receipt, color: Colors.green, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Receipt #${receipt['receiptNo'] ?? 'N/A'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Date: ${receipt['paymentDate'] ?? 'N/A'} • Mode: ${receipt['paymentMode'] ?? 'N/A'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Text(
                'AmountPaid₹ ${receipt['amountPaid']?.toStringAsFixed(0) ?? '0'}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildModernSection(String title, IconData icon, bool isTablet, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppTheme.primaryBlue, size: isTablet ? 24 : 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isTablet, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: valueColor ?? Colors.grey[800],
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeRow(String label, dynamic total, dynamic paid, dynamic due, bool isTablet) {
    final totalAmount = (total ?? 0).toDouble();
    final paidAmount = (paid ?? 0).toDouble();
    final dueAmount = (due ?? 0).toDouble();
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '₹${totalAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  '₹${paidAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  '₹${dueAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    color: dueAmount > 0 ? Colors.red : Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          if (totalAmount > 0) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: paidAmount / totalAmount,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                paidAmount >= totalAmount ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalRow(Map<String, dynamic> feeStructure, Map<String, dynamic> feePaid, bool isTablet) {
    final totalFee = (feeStructure['admissionFee'] ?? 0) +
                    (feeStructure['firstTermAmt'] ?? 0) +
                    (feeStructure['secondTermAmt'] ?? 0) +
                    (feeStructure['busFirstTermAmt'] ?? 0) +
                    (feeStructure['busSecondTermAmt'] ?? 0);
    
    final totalPaid = (feePaid['admissionFee'] ?? 0) +
                     (feePaid['firstTermAmt'] ?? 0) +
                     (feePaid['secondTermAmt'] ?? 0) +
                     (feePaid['busFirstTermAmt'] ?? 0) +
                     (feePaid['busSecondTermAmt'] ?? 0);
    
    final totalDue = totalFee - totalPaid;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'TOTAL',
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '₹${totalFee.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              '₹${totalPaid.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              '₹${totalDue.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.bold,
                color: totalDue > 0 ? Colors.red : Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildProofUploads(bool isTablet) {
    final proofUploads = widget.receiptData['proofUpload'] as List<dynamic>? ?? [];

    return _buildModernSection(
      'Proof Uploads',
      Icons.attach_file,
      isTablet,
      [
        if (proofUploads.isEmpty) ...[
          _buildInfoRow('Status', 'No proofs uploaded', isTablet),
        ] else ...[
          _buildInfoRow('Number of Proofs', proofUploads.length.toString(), isTablet),
          const SizedBox(height: 8),
          ...proofUploads.map((proof) {
            final proofData = proof as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    proofData['originalName']?.toString() ?? 'Unknown File',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: isTablet ? 14 : 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Uploaded: ${_formatDate(proofData['uploadedAt'])}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: isTablet ? 12 : 10,
                    ),
                  ),
                  if (proofData['url'] != null) ...[
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Open image in full screen or download
                        Get.to(() => Scaffold(
                          appBar: AppBar(
                            title: Text(proofData['originalName']?.toString() ?? 'Proof'),
                            backgroundColor: Colors.black,
                          ),
                          body: Center(
                            child: InteractiveViewer(
                              child: Image.network(
                                proofData['url'].toString(),
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const CircularProgressIndicator();
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.error, size: 48, color: Colors.red);
                                },
                              ),
                            ),
                          ),
                        ));
                      },
                      icon: const Icon(Icons.visibility, size: 16),
                      label: Text(
                        'View Proof',
                        style: TextStyle(fontSize: isTablet ? 12 : 10),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ],
      ],
    );
  }

  String _getStudentDisplayName() {
    // First check if we have student record data from API
    if (studentRecordData != null && studentRecordData!['studentId'] is Map) {
      final studentInfo = studentRecordData!['studentId'];
      if (studentInfo['studentName'] != null) {
        return studentInfo['studentName'].toString();
      }
    }

    // Try different ways to get student name from receipt data
    if (widget.receiptData['studentName'] != null && widget.receiptData['studentName'].toString().isNotEmpty) {
      return widget.receiptData['studentName'].toString();
    }

    // Check if studentId is an object with studentName
    if (widget.receiptData['studentId'] is Map && widget.receiptData['studentId']['studentName'] != null) {
      return widget.receiptData['studentId']['studentName'].toString();
    }

    // If still loading student data
    if (isLoadingStudent) {
      return 'Loading...';
    }

    return 'Student Record';
  }

  String _getStudentId() {
    // First check if we have student record data from API
    if (studentRecordData != null && studentRecordData!['studentId'] is Map) {
      final studentInfo = studentRecordData!['studentId'];
      if (studentInfo['srId'] != null) {
        return studentInfo['srId'].toString();
      }
    }

    // Try to get srId from studentId object if available
    if (widget.receiptData['studentId'] is Map && widget.receiptData['studentId']['srId'] != null) {
      return widget.receiptData['studentId']['srId'].toString();
    }

    // If still loading student data
    if (isLoadingStudent) {
      return 'Loading...';
    }

    return 'N/A';
  }

  String _getClassName() {
    // First check if we have student record data from API
    if (studentRecordData != null && studentRecordData!['classId'] is Map && studentRecordData!['classId']['name'] != null) {
      return studentRecordData!['classId']['name'].toString();
    }

    // Check if className is directly available in receipt
    if (widget.receiptData['className'] != null) {
      return widget.receiptData['className'].toString();
    }

    // Check if classId is an object with name in receipt
    if (widget.receiptData['classId'] is Map && widget.receiptData['classId']['name'] != null) {
      return widget.receiptData['classId']['name'].toString();
    }

    // If still loading student data
    if (isLoadingStudent) {
      return 'Loading...';
    }

    return 'N/A';
  }

  String _getSectionName() {
    // First check if we have student record data from API
    if (studentRecordData != null && studentRecordData!['sectionId'] is Map && studentRecordData!['sectionId']['name'] != null) {
      return studentRecordData!['sectionId']['name'].toString();
    }

    // Check if sectionName is directly available in receipt
    if (widget.receiptData['sectionName'] != null) {
      return widget.receiptData['sectionName'].toString();
    }

    // Check if sectionId is an object with name in receipt
    if (widget.receiptData['sectionId'] is Map && widget.receiptData['sectionId']['name'] != null) {
      return widget.receiptData['sectionId']['name'].toString();
    }

    // If still loading student data
    if (isLoadingStudent) {
      return 'Loading...';
    }

    return 'N/A';
  }

  int min(int a, int b) => a < b ? a : b;
}