import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/student_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../../core/permissions/feature_flag_service.dart';
import '../../../modules/auth/controllers/auth_controller.dart';

class StudentManagementView extends GetView<StudentController> {
  StudentManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Management'),
        automaticallyImplyLeading: false,
        actions: [
          // if (RolePermissions.canCreate('student'))
            IconButton(
              onPressed: () => _showAddStudentDialog(context),
              icon: const Icon(Icons.add),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search and Filter Section
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by name or roll number',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => controller.searchQuery.value = value,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Class and Section Filters
                  Row(
                    children: [
                      Expanded(
                        child: Obx(() => DropdownButtonFormField<String>(
                          value: controller.selectedClass.value.isEmpty ? null : controller.selectedClass.value,
                          decoration: const InputDecoration(
                            labelText: 'Class',
                            border: OutlineInputBorder(),
                          ),
                          items: ['', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10']
                              .map((cls) => DropdownMenuItem(
                                    value: cls,
                                    child: Text(cls.isEmpty ? 'All Classes' : 'Class $cls'),
                                  ))
                              .toList(),
                          onChanged: (value) => controller.selectedClass.value = value ?? '',
                        )),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Obx(() => DropdownButtonFormField<String>(
                          value: controller.selectedSection.value.isEmpty ? null : controller.selectedSection.value,
                          decoration: const InputDecoration(
                            labelText: 'Section',
                            border: OutlineInputBorder(),
                          ),
                          items: ['', 'A', 'B', 'C', 'D']
                              .map((section) => DropdownMenuItem(
                                    value: section,
                                    child: Text(section.isEmpty ? 'All Sections' : 'Section $section'),
                                  ))
                              .toList(),
                          onChanged: (value) => controller.selectedSection.value = value ?? '',
                        )),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Students List
            Expanded(
              child: Obx(() => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: controller.filteredStudents.length,
                itemBuilder: (context, index) {
                  final student = controller.filteredStudents[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          student.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(student.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Roll: ${student.rollNumber} | Class: ${student.className}-${student.section}'),
                          Text('Father: ${student.fatherName}'),
                          Text('Phone: ${student.phoneNumber}'),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'view':
                              _showStudentDetails(context, student);
                              break;
                            case 'edit':
                              _showEditStudentDialog(context, student);
                              break;
                            case 'delete':
                              _showDeleteConfirmation(context, student);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'view', child: Text('View Details')),
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              )),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddStudentDialog(BuildContext context) {
    _showStudentForm(context, null);
  }

  void _showEditStudentDialog(BuildContext context, Student student) {
    _showStudentForm(context, student);
  }

  void _showStudentForm(BuildContext context, Student? student) {
    final nameController = TextEditingController(text: student?.name ?? '');
    final rollController = TextEditingController(text: student?.rollNumber ?? '');
    final fatherController = TextEditingController(text: student?.fatherName ?? '');
    final motherController = TextEditingController(text: student?.motherName ?? '');
    final phoneController = TextEditingController(text: student?.phoneNumber ?? '');
    final addressController = TextEditingController(text: student?.address ?? '');
    final dobController = TextEditingController(text: student?.dateOfBirth ?? '');
    final bloodGroupController = TextEditingController(text: student?.bloodGroup ?? '');
    
    String selectedClass = student?.className ?? '1';
    String selectedSection = student?.section ?? 'A';

    Get.dialog(
      AlertDialog(
        title: Text(student == null ? 'Add Student' : 'Edit Student'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Student Name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: rollController,
                  decoration: const InputDecoration(labelText: 'Roll Number'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedClass,
                        decoration: const InputDecoration(labelText: 'Class'),
                        items: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10']
                            .map((cls) => DropdownMenuItem(value: cls, child: Text('Class $cls')))
                            .toList(),
                        onChanged: (value) => selectedClass = value!,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedSection,
                        decoration: const InputDecoration(labelText: 'Section'),
                        items: ['A', 'B', 'C', 'D']
                            .map((section) => DropdownMenuItem(value: section, child: Text('Section $section')))
                            .toList(),
                        onChanged: (value) => selectedSection = value!,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: fatherController,
                  decoration: const InputDecoration(labelText: 'Father Name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: motherController,
                  decoration: const InputDecoration(labelText: 'Mother Name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: dobController,
                  decoration: const InputDecoration(labelText: 'Date of Birth (YYYY-MM-DD)'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: bloodGroupController,
                  decoration: const InputDecoration(labelText: 'Blood Group'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newStudent = Student(
                id: student?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text,
                rollNumber: rollController.text,
                className: selectedClass,
                section: selectedSection,
                fatherName: fatherController.text,
                motherName: motherController.text,
                phoneNumber: phoneController.text,
                address: addressController.text,
                dateOfBirth: dobController.text,
                admissionDate: student?.admissionDate ?? DateTime.now().toString().split(' ')[0],
                bloodGroup: bloodGroupController.text,
                status: 'Active',
              );

              if (student == null) {
                controller.addStudent(newStudent);
              } else {
                controller.updateStudent(newStudent);
              }
              Get.back();
            },
            child: Text(student == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _showStudentDetails(BuildContext context, Student student) {
    Get.dialog(
      AlertDialog(
        title: Text(student.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Roll Number', student.rollNumber),
            _buildDetailRow('Class', '${student.className}-${student.section}'),
            _buildDetailRow('Father Name', student.fatherName),
            _buildDetailRow('Mother Name', student.motherName),
            _buildDetailRow('Phone', student.phoneNumber),
            _buildDetailRow('Address', student.address),
            _buildDetailRow('Date of Birth', student.dateOfBirth),
            _buildDetailRow('Blood Group', student.bloodGroup),
            _buildDetailRow('Admission Date', student.admissionDate),
            _buildDetailRow('Status', student.status),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Student student) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Are you sure you want to delete ${student.name}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          if (FeatureFlagService.canShowDeleteButtons())
            ElevatedButton(
              onPressed: () {
                controller.deleteStudent(student.id);
                Get.back();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Delete'),
            ),
        ],
      ),
    );
  }
}