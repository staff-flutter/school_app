import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/teacher_controller.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/controllers/user_management_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';

class TeacherAssignmentView extends StatefulWidget {
  const TeacherAssignmentView({Key? key}) : super(key: key);

  @override
  State<TeacherAssignmentView> createState() => _TeacherAssignmentViewState();
}

class _TeacherAssignmentViewState extends State<TeacherAssignmentView> {
  final teacherController = Get.put(TeacherController());
  final schoolController = Get.find<SchoolController>();
  final userController = Get.find<UserManagementController>();
  
  String? selectedTeacherId;
  final selectedAssignments = <Map<String, dynamic>>[].obs;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() async {
    if (_isInitialized || schoolController.selectedSchool.value == null) return;
    
    _isInitialized = true;
    
    // Load data sequentially to avoid conflicts
    await userController.loadUsers(
      schoolId: schoolController.selectedSchool.value!.id,
      role: 'teacher',
    );
    
    await schoolController.getAllClasses(schoolController.selectedSchool.value!.id);
    
    await schoolController.getAllSections(schoolId: schoolController.selectedSchool.value!.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Assignments'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Teacher Selection
            _buildTeacherDropdown(),
            
            const SizedBox(height: 20),
            
            // Class-Section Assignment Grid
            Expanded(child: _buildClassSectionList()),
            
            // Save Button
            const SizedBox(height: 20),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherDropdown() {
    return Obx(() => DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Select Teacher',
        border: OutlineInputBorder(),
      ),
      value: selectedTeacherId,
      items: userController.users.map((teacher) {
        return DropdownMenuItem<String>(
          value: teacher['_id'],
          child: Text(teacher['userName'] ?? 'Unknown'),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedTeacherId = value;
          selectedAssignments.clear();
        });
      },
    ));
  }

  Widget _buildClassSectionList() {
    return Obx(() {
      if (schoolController.classes.isEmpty) {
        return const Center(child: Text('No classes available'));
      }
      
      return ListView.builder(
        itemCount: schoolController.classes.length,
        itemBuilder: (context, index) {
          final schoolClass = schoolController.classes[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              title: Text(schoolClass.name),
              children: [
                if (schoolClass.hasSections)
                  _buildSectionCheckboxes(schoolClass)
                else
                  _buildClassCheckbox(schoolClass),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildSectionCheckboxes(schoolClass) {
    return Obx(() {
      final classSections = schoolController.sections
          .where((section) => section.classId == schoolClass.id)
          .toList();
      
      if (classSections.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Text('No sections available'),
        );
      }
      
      return Wrap(
        children: classSections.map((section) => CheckboxListTile(
          title: Text(section.name),
          value: _isAssigned(schoolClass.id, section.id),
          onChanged: selectedTeacherId == null ? null : (value) {
            _toggleAssignment(schoolClass.id, section.id);
          },
        )).toList(),
      );
    });
  }

  Widget _buildClassCheckbox(schoolClass) {
    return CheckboxListTile(
      title: Text('Entire ${schoolClass.name}'),
      value: _isClassAssigned(schoolClass.id),
      onChanged: selectedTeacherId == null ? null : (value) {
        _toggleClassAssignment(schoolClass.id);
      },
    );
  }

  Widget _buildSaveButton() {
    return Obx(() => ElevatedButton(
      onPressed: selectedTeacherId == null || teacherController.isLoading.value
          ? null
          : _saveAssignments,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
      ),
      child: teacherController.isLoading.value
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text('Save Assignments'),
    ));
  }

  bool _isAssigned(String classId, String sectionId) {
    return selectedAssignments.any((assignment) =>
        assignment['classId'] == classId && assignment['sectionId'] == sectionId);
  }

  bool _isClassAssigned(String classId) {
    return selectedAssignments.any((assignment) =>
        assignment['classId'] == classId && assignment['sectionId'] == null);
  }

  void _toggleAssignment(String classId, String sectionId) {
    final existingIndex = selectedAssignments.indexWhere((assignment) =>
        assignment['classId'] == classId && assignment['sectionId'] == sectionId);
    
    if (existingIndex >= 0) {
      selectedAssignments.removeAt(existingIndex);
    } else {
      selectedAssignments.add({'classId': classId, 'sectionId': sectionId});
    }
  }

  void _toggleClassAssignment(String classId) {
    final existingIndex = selectedAssignments.indexWhere((assignment) =>
        assignment['classId'] == classId && assignment['sectionId'] == null);
    
    if (existingIndex >= 0) {
      selectedAssignments.removeAt(existingIndex);
    } else {
      selectedAssignments.add({'classId': classId});
    }
  }

  void _saveAssignments() {
    if (selectedTeacherId == null || schoolController.selectedSchool.value == null) {
      return;
    }

    teacherController.manageTeacherAssignments(
      teacherId: selectedTeacherId!,
      updates: selectedAssignments.toList(),
      schoolId: schoolController.selectedSchool.value!.id,
    );
  }
}