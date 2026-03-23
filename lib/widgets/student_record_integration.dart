import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/student_record_controller.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';

class StudentRecordIntegration extends StatelessWidget {
  const StudentRecordIntegration({super.key});

  @override
  Widget build(BuildContext context) {
    final recordController = Get.put(StudentRecordController());
    final authController = Get.find<AuthController>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Student Records API', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // Load Students Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _loadStudents(recordController, authController),
                icon: const Icon(Icons.refresh),
                label: const Text('Load Students'),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Collect Fee Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _collectFee(recordController, authController),
                icon: const Icon(Icons.payment),
                label: const Text('Collect Fee (Demo)'),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Check Dues Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _checkDues(recordController, authController),
                icon: const Icon(Icons.account_balance_wallet),
                label: const Text('Check Dues (Demo)'),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Student Records Display
            Obx(() {
              if (recordController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (recordController.studentRecords.isEmpty) {
                return const Text('No student records loaded');
              }
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Students Found: ${recordController.studentRecords.length}'),
                  const SizedBox(height: 8),
                  ...recordController.studentRecords.take(3).map((student) => 
                    Text('• ${student['name'] ?? 'Unknown'} - ${student['class'] ?? 'N/A'}')),
                  if (recordController.studentRecords.length > 3)
                    Text('... and ${recordController.studentRecords.length - 3} more'),
                ],
              );
            }),
            
            // Dues Display
            Obx(() {
              final dues = recordController.studentDues.value;
              if (dues == null) return const SizedBox();
              
              return Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Student Dues:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Total Due: ₹${dues['totalDue'] ?? 0}'),
                    Text('Paid: ₹${dues['totalPaid'] ?? 0}'),
                    Text('Balance: ₹${dues['balance'] ?? 0}'),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _loadStudents(StudentRecordController controller, AuthController authController) async {
    final schoolId = authController.user.value?.schoolId ?? '';
    if (schoolId.isNotEmpty) {
      await controller.loadStudentRecords(schoolId: schoolId);
    } else {
      Get.snackbar('Error', 'School ID not found');
    }
  }

  void _collectFee(StudentRecordController controller, AuthController authController) async {
    final schoolId = authController.user.value?.schoolId ?? '';
    if (schoolId.isNotEmpty) {
      await controller.collectFee(
        schoolId: schoolId,
        studentId: 'demo_student',
        classId: 'demo_class',
        sectionId: 'demo_section',
        amount: 1000.0,
        paymentMode: 'cash',
      );
    }
  }

  void _checkDues(StudentRecordController controller, AuthController authController) async {
    final schoolId = authController.user.value?.schoolId ?? '';
    if (schoolId.isNotEmpty) {
      await controller.getDues(
        schoolId: schoolId,
        studentId: 'demo_student',
        classId: 'demo_class',
        sectionId: 'demo_section',
      );
    }
  }
}