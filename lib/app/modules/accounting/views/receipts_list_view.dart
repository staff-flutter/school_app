import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/accounting_controller.dart';
import '../widgets/receipt_list_item.dart';

class ReceiptsListView extends StatelessWidget {
  final List<Map<String, dynamic>> receipts;

  const ReceiptsListView({Key? key, required this.receipts}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipts'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: receipts.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No receipts found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: receipts.length,
              itemBuilder: (context, index) {
                return ReceiptListItem(receiptData: receipts[index]);
              },
            ),
    );
  }
}

// Example usage in your existing code:
// To show receipt details when you have the student record data:
/*
void showReceiptFromStudentRecord() {
  final controller = Get.find<AccountingController>();
  
  // Your existing student record data from the debug output
  final studentRecordData = {
    'feeStructure': {
      'admissionFee': 2000,
      'firstTermAmt': 6000,
      'secondTermAmt': 6000,
      'busFirstTermAmt': 0,
      'busSecondTermAmt': 0
    },
    'feePaid': {
      'admissionFee': 2000,
      'firstTermAmt': 6000,
      'secondTermAmt': 6000,
      'busFirstTermAmt': 0,
      'busSecondTermAmt': 0
    },
    'concession': {
      'isApplied': false,
      'type': null,
      'value': 0,
      'inAmount': 0,
      'proof': null
    },
    'dues': {
      'admissionDues': 0,
      'firstTermDues': 0,
      'secondTermDues': 0,
      'busfirstTermDues': 0,
      'busSecondTermDues': 0
    },
    'studentId': {
      'studentName': 'stu12',
      'srId': 'SR-009'
    },
    'academicYear': '2024-2025',
    'className': 'Class 8',
    'sectionName': 'Section B',
    'newOld': 'New',
    'rollNumber': null,
    'isActive': true,
    'isBusApplicable': false,
    'isFullyPaid': true,
    'busPoint': null
  };
  
  // Show the receipt detail
  controller.showReceiptDetail(studentRecordData);
}
*/