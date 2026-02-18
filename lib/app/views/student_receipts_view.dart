import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/student_record_controller.dart';
import '../core/theme/app_theme.dart';
import '../modules/accounting/views/receipt_detail_view.dart';
import '../routes/app_routes.dart';

class StudentReceiptsView extends StatefulWidget {
  final Map<String, dynamic> studentRecord;
  
  const StudentReceiptsView({Key? key, required this.studentRecord}) : super(key: key);

  @override
  State<StudentReceiptsView> createState() => _StudentReceiptsViewState();
}

class _StudentReceiptsViewState extends State<StudentReceiptsView> {
  final controller = Get.find<StudentRecordController>();
  final receipts = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    // Use WidgetsBinding to call _loadReceipts after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReceipts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.studentRecord['studentId'] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text('${student['studentName'] ?? 'Student'} - Receipts'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Student Info Card
          Card(
            color: Colors.purple.shade100,
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: student['studentImage']?['url'] != null
                        ? NetworkImage(student['studentImage']['url'])
                        : null,
                    child: student['studentImage']?['url'] == null
                        ? Text(student['studentName']?.toString().substring(0, 1).toUpperCase() ?? 'S')
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student['studentName'] ?? 'Unknown',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Colors.black),
                        ),
                        Text('SR ID: ${student['srId'] ?? 'N/A'}',style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold)),
                        Text('Class: ${widget.studentRecord['className']} - ${widget.studentRecord['sectionName']}',style: TextStyle(color: Colors.black)),
                        Text('Academic Year: ${widget.studentRecord['academicYear'] ?? 'N/A'}',style: TextStyle(color: Colors.black),),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Receipts List
          Expanded(
            child: Obx(() {
              if (isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (receipts.isEmpty) {
                return const Center(
                  child: Text('No receipts found for this student'),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: receipts.length,
                itemBuilder: (context, index) {
                  final receipt = receipts[index];
                  return _buildReceiptCard(receipt);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptCard(Map<String, dynamic> receipt) {
    
    final isActive = receipt['status'] == 'success';
    final paymentDate = receipt['paymentDate'] ?? receipt['createdAt'];

    return Card(
      color: isActive ? Colors.green.shade100 : Colors.red.shade100,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Get.toNamed(AppRoutes.receiptDetail, arguments: receipt);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Receipt #${receipt['receiptNo'] ?? receipt['_id']?.toString().substring(0, 8) ?? 'N/A'}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text('Amount: ₹${receipt['amountPaid'] ?? receipt['amount'] ?? '0'}'),
                        Text('Payment Mode: ${(receipt['paymentMode'] ?? 'N/A').toString().toUpperCase()}'),
                        Text('Date: ${_formatDate(paymentDate)}'),
                        if (receipt['academicYear'] != null)
                          Text('Academic Year: ${receipt['academicYear']}'),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          (receipt['status']?.toString() ?? 'unknown').toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 8),
                      PopupMenuButton<String>(
                        onSelected: (value) => _handleReceiptAction(value, receipt),
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'revert', child: Text('Revert Receipt')),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Collected By: ${receipt['collectedBy']?['userName'] ?? receipt['collectedBy'] ?? 'N/A'}',
                style: const TextStyle(color: Colors.grey),
              ),
              if (receipt['remarks']?.toString().isNotEmpty == true)
                Text(
                  'Remarks: ${receipt['remarks']}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleReceiptAction(String action, Map<String, dynamic> receipt) async {

    switch (action) {
      case 'toggle':
        _showToggleStatusDialog(receipt);
        break;
      case 'revert':
        _showRevertReceiptDialog(receipt);
        break;
      case 'delete':
        
        await controller.deleteStudentRecord(receipt['recordId']);
        _loadReceipts();
        break;
    }
  }

  void _showToggleStatusDialog(Map<String, dynamic> receipt) {
    final currentStatus = receipt['status'] == 'success';
    
    Get.dialog(
      AlertDialog(
        title: const Text('Toggle Receipt Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Status: ${receipt['status']?.toString().toUpperCase() ?? 'UNKNOWN'}'),
            const SizedBox(height: 16),
            Text('Toggle to: ${currentStatus ? 'INACTIVE' : 'ACTIVE'}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newStatus = !currentStatus;
              
              Get.back();
              await controller.toggleStudentStatus(receipt['recordId'], newStatus);
              
              _loadReceipts();
            },
            child: const Text('Toggle'),
          ),
        ],
      ),
    );
  }

  void _showRevertReceiptDialog(Map<String, dynamic> receipt) {
    final reasonController = TextEditingController();
    String selectedStatus = 'cancelled';
    
    Get.dialog(
      AlertDialog(
        title: const Text('Revert Receipt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: const InputDecoration(labelText: 'Revert Type'),
              items: ['cancelled', 'bounced'].map((status) {
                return DropdownMenuItem(value: status, child: Text(status.toUpperCase()));
              }).toList(),
              onChanged: (value) => selectedStatus = value!,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason/Remarks',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await controller.revertReceipt(
                receiptId: receipt['_id'] ?? '',
                status: selectedStatus,
                reason: reasonController.text.isNotEmpty ? reasonController.text : null,
              );
              _loadReceipts();
            },
            child: const Text('Revert'),
          ),
        ],
      ),
    );
  }

  void _loadReceipts() async {
    try {
      isLoading.value = true;

      final schoolId = widget.studentRecord['schoolId'];
      final studentId = widget.studentRecord['studentId']?['_id'];

      if (schoolId == null || studentId == null) {

        Get.snackbar('Error', 'Missing school or student ID');
        return;
      }

      final response = await controller.getStudentRecord(schoolId, studentId);

      if (response != null) {
        
        if (response['receipts'] != null) {
          final receiptsList = List<Map<String, dynamic>>.from(response['receipts']);
          
          receipts.value = receiptsList;
        } else {
          
          receipts.value = [];
        }
      } else {
        
        receipts.value = [];
      }

    } catch (e) {

      Get.snackbar('Error', 'Failed to load receipts: ${e.toString()}');
    } finally {
      isLoading.value = false;
      
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
