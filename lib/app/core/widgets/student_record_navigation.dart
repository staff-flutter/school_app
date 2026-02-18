import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../modules/auth/controllers/auth_controller.dart';

class StudentRecordNavigation extends StatelessWidget {
  const StudentRecordNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    
    // Only show for correspondent role
    if (!authController.isCorrespondent) {
      return const SizedBox.shrink();
    }
    
    return FloatingActionButton.extended(
      onPressed: () => _showStudentRecordDialog(context),
      icon: const Icon(Icons.person_search),
      label: const Text('Student Records'),
      backgroundColor: Theme.of(context).colorScheme.secondary,
    );
  }

  void _showStudentRecordDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Quick Student Access'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('View All Students'),
              onTap: () {
                Get.back();
                // Navigate to student list
                Get.toNamed('/students');
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Search Student'),
              onTap: () {
                Get.back();
                // Navigate to student search
                Get.toNamed('/students/search');
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add New Student'),
              onTap: () {
                Get.back();
                // Navigate to add student
                Get.toNamed('/students/add');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}