import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/student_record_controller.dart';
import '../modules/auth/controllers/auth_controller.dart';

// 1. Usage in Fee Collection Tab
class FeeCollectionWidget extends StatelessWidget {
  const FeeCollectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final recordController = Get.put(StudentRecordController());
    
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => _collectFee(recordController),
          child: const Text('Collect Fee'),
        ),
        ElevatedButton(
          onPressed: () => _checkDues(recordController),
          child: const Text('Check Dues'),
        ),
        Obx(() => recordController.studentDues.value != null
            ? Text('Balance: ₹${recordController.studentDues.value!['balance']}')
            : const SizedBox()),
      ],
    );
  }

  void _collectFee(StudentRecordController controller) async {
    final authController = Get.find<AuthController>();
    await controller.collectFee(
      schoolId: authController.user.value?.schoolId ?? '',
      studentId: 'student123',
      classId: 'class456',
      sectionId: 'sectionA',
      amount: 5000.0,
      paymentMode: 'cash',
    );
  }

  void _checkDues(StudentRecordController controller) async {
    final authController = Get.find<AuthController>();
    await controller.getDues(
      schoolId: authController.user.value?.schoolId ?? '',
      studentId: 'student123',
      classId: 'class456',
      sectionId: 'sectionA',
    );
  }
}

// 2. Usage in Student Management Tab
class StudentManagementWidget extends StatelessWidget {
  const StudentManagementWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final recordController = Get.put(StudentRecordController());
    
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => _loadStudents(recordController),
          child: const Text('Load Students'),
        ),
        Expanded(
          child: Obx(() => ListView.builder(
            itemCount: recordController.studentRecords.length,
            itemBuilder: (context, index) {
              final student = recordController.studentRecords[index];
              
              return ListTile(
                title: Text(student['name'] ?? 'Unknown'),
                subtitle: Text('Class: ${student['class']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editStudent(recordController, student),
                ),
              );
            },
          )),
        ),
      ],
    );
  }

  void _loadStudents(StudentRecordController controller) async {
    final authController = Get.find<AuthController>();
    await controller.loadStudentRecords(
      schoolId: authController.user.value?.schoolId ?? '',
    );
  }

  void _editStudent(StudentRecordController controller, Map<String, dynamic> student) async {
    await controller.updateStudentRecord(student['_id'], {
      'name': 'Updated Name',
      'class': '11',
    });
  }
}

// 3. Usage in Concession Management
class ConcessionWidget extends StatelessWidget {
  const ConcessionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final recordController = Get.put(StudentRecordController());
    
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => _applyConcession(recordController),
          child: const Text('Apply Concession'),
        ),
        ElevatedButton(
          onPressed: () => _updateConcession(recordController),
          child: const Text('Update Concession'),
        ),
      ],
    );
  }

  void _applyConcession(StudentRecordController controller) async {
    final authController = Get.find<AuthController>();
    
    await controller.applyConcession(
      schoolId: authController.user.value?.schoolId ?? '',
      studentId: 'student123',
      studentName: 'Demo Student',
      classId: 'class456',
      sectionId: 'sectionA',
      concessionType: 'percentage',
      concessionValue: 10.0,
      remark: 'Merit scholarship',
      newOld: 'new',
    );
  }

  void _updateConcession(StudentRecordController controller) async {
    final authController = Get.find<AuthController>();
    await controller.updateConcessionValue(
      schoolId: authController.user.value?.schoolId ?? '',
      studentId: 'student123',
      classId: 'class456',
      sectionId: 'sectionA',
      concessionType: 'percentage',
      concessionValue: 15.0,
    );
  }
}

// 4. Usage in Transaction History
class TransactionWidget extends StatelessWidget {
  const TransactionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final recordController = Get.put(StudentRecordController());
    
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => _loadTransactions(recordController),
          child: const Text('Load Transactions'),
        ),
        ElevatedButton(
          onPressed: () => _revertReceipt(recordController),
          child: const Text('Revert Receipt'),
        ),
      ],
    );
  }

  void _loadTransactions(StudentRecordController controller) async {
    final authController = Get.find<AuthController>();
    // await controller.getTransactionHistory(
    //   schoolId: authController.user.value?.schoolId ?? '',
    //   page: 1,
    //   limit: 20,
    // );
    // return Get.Snackbar('Not Implemented', 'This feature is not yet implemented');
  }

  void _revertReceipt(StudentRecordController controller) async {
    await controller.revertReceipt(
      receiptId: 'receipt123',
      status: 'cancelled',
      reason: 'Payment bounced',
    );
  }
}