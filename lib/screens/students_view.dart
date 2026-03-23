import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/students_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/widgets/permission_wrapper.dart';

class StudentsView extends GetView<StudentsController> {
  const StudentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildContent(context)),
        ],
      ),
      floatingActionButton: controller.canCreate
          ? FloatingActionButton(
              onPressed: () => _showCreateStudentDialog(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Students ${_getPermissionLabel()}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
        PermissionWrapper(
          permission: 'CREATE_student',
          child: ElevatedButton.icon(
            onPressed: () => _showCreateStudentDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Student'),
          ),
        ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: controller.loadStudents,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.filteredStudents.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No students found'),
            ],
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Column(
            children: [
              _buildTableHeader(),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: controller.filteredStudents.length,
                  itemBuilder: (context, index) {
                    final student = controller.filteredStudents[index];
                    return _buildStudentRow(context, student, index);
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          const Expanded(flex: 2, child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
          const Expanded(child: Text('Roll No', style: TextStyle(fontWeight: FontWeight.bold))),
          const Expanded(child: Text('Class', style: TextStyle(fontWeight: FontWeight.bold))),
          const Expanded(child: Text('Section', style: TextStyle(fontWeight: FontWeight.bold))),
          if (controller.isFinanceView)
            const Expanded(child: Text('Fee Status', style: TextStyle(fontWeight: FontWeight.bold))),
          if (!controller.isReadOnly)
            const SizedBox(width: 120, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildStudentRow(BuildContext context, Student student, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(student.parentName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Expanded(child: Text(student.rollNumber)),
          Expanded(child: Text(student.className)),
          Expanded(child: Text(student.section)),
          if (controller.isFinanceView)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: student.feeStatus == 'Paid' ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  student.feeStatus,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          if (!controller.isReadOnly)
            SizedBox(
              width: 120,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _showStudentDetails(context, student),
                    icon: const Icon(Icons.visibility, size: 18),
                    tooltip: 'View Details',
                  ),
                  PermissionWrapper(
                    permission: 'UPDATE_student',
                    child: IconButton(
                      onPressed: () => _showEditStudentDialog(context, student),
                      icon: const Icon(Icons.edit, size: 18),
                      tooltip: 'Edit',
                    ),
                  ),
                  PermissionWrapper(
                    permission: 'DELETE_student',
                    child: IconButton(
                      onPressed: () => _showDeleteConfirmation(context, student),
                      icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                      tooltip: 'Delete',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showStudentDetails(BuildContext context, Student student) {
    Get.dialog(
      AlertDialog(
        title: Text('Student Details - ${student.name}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Roll Number', student.rollNumber),
              _buildDetailRow('Class', student.className),
              _buildDetailRow('Section', student.section),
              _buildDetailRow('Parent Name', student.parentName),
              _buildDetailRow('Phone', student.phone),
              _buildDetailRow('Email', student.email),
              _buildDetailRow('Address', student.address),
              _buildDetailRow('Admission Date', student.admissionDate),
              if (controller.isFinanceView)
                _buildDetailRow('Fee Status', student.feeStatus),
            ],
          ),
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
            width: 120,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showCreateStudentDialog(BuildContext context) {
    final nameController = TextEditingController();
    final rollController = TextEditingController();
    final classController = TextEditingController();
    final sectionController = TextEditingController();
    final parentController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Add New Student'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Student Name'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: rollController,
                        decoration: const InputDecoration(labelText: 'Roll Number'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: classController,
                        decoration: const InputDecoration(labelText: 'Class'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: sectionController,
                        decoration: const InputDecoration(labelText: 'Section'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: parentController,
                  decoration: const InputDecoration(labelText: 'Parent Name'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: phoneController,
                        decoration: const InputDecoration(labelText: 'Phone'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                  maxLines: 2,
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
              if (nameController.text.trim().isEmpty) {
                Get.snackbar('Error', 'Please enter student name');
                return;
              }

              final student = Student(
                id: '',
                name: nameController.text.trim(),
                rollNumber: rollController.text.trim(),
                className: classController.text.trim(),
                section: sectionController.text.trim(),
                feeStatus: 'Due',
                parentName: parentController.text.trim(),
                phone: phoneController.text.trim(),
                email: emailController.text.trim(),
                address: addressController.text.trim(),
                admissionDate: DateTime.now().toString().split(' ')[0],
              );

              controller.createStudent(student);
              Get.back();
            },
            child: const Text('Add Student'),
          ),
        ],
      ),
    );
  }

  void _showEditStudentDialog(BuildContext context, Student student) {
    final nameController = TextEditingController(text: student.name);
    final rollController = TextEditingController(text: student.rollNumber);
    final classController = TextEditingController(text: student.className);
    final sectionController = TextEditingController(text: student.section);
    final parentController = TextEditingController(text: student.parentName);
    final phoneController = TextEditingController(text: student.phone);
    final emailController = TextEditingController(text: student.email);
    final addressController = TextEditingController(text: student.address);

    Get.dialog(
      AlertDialog(
        title: Text('Edit Student - ${student.name}'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Student Name'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: rollController,
                        decoration: const InputDecoration(labelText: 'Roll Number'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: classController,
                        decoration: const InputDecoration(labelText: 'Class'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: sectionController,
                        decoration: const InputDecoration(labelText: 'Section'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: parentController,
                  decoration: const InputDecoration(labelText: 'Parent Name'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: phoneController,
                        decoration: const InputDecoration(labelText: 'Phone'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                  maxLines: 2,
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
              if (nameController.text.trim().isEmpty) {
                Get.snackbar('Error', 'Please enter student name');
                return;
              }

              final updatedStudent = Student(
                id: student.id,
                name: nameController.text.trim(),
                rollNumber: rollController.text.trim(),
                className: classController.text.trim(),
                section: sectionController.text.trim(),
                feeStatus: student.feeStatus,
                parentName: parentController.text.trim(),
                phone: phoneController.text.trim(),
                email: emailController.text.trim(),
                address: addressController.text.trim(),
                admissionDate: student.admissionDate,
              );

              controller.updateStudent(updatedStudent);
              Get.back();
            },
            child: const Text('Update'),
          ),
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
          ElevatedButton(
            onPressed: () {
              controller.deleteStudent(student.id);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _getPermissionLabel() {
    switch (controller.permission) {
      case 'readOnly': return '(Read Only)';
      case 'classScopedReadOnly': return '(Class Scoped)';
      case 'financeView': return '(Finance View)';
      default: return '';
    }
  }
}