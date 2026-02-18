import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/student_management_controller.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/responsive_wrapper.dart';
import '../core/widgets/api_rbac_wrapper.dart';
import '../core/rbac/api_rbac.dart';
import '../modules/auth/controllers/auth_controller.dart';

class StudentManagementView extends StatefulWidget {
  const StudentManagementView({Key? key}) : super(key: key);

  @override
  State<StudentManagementView> createState() => _StudentManagementViewState();
}

class _StudentManagementViewState extends State<StudentManagementView> with TickerProviderStateMixin {
  final controller = Get.put(StudentManagementController());
  final authController = Get.find<AuthController>();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      body: SafeArea(
        child: ResponsiveWrapper(
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Get.back(),
                            ),
                            const Expanded(
                              child: Text(
                                'Student Management',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 48), // Balance the back button
                          ],
                        ),
                        TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          indicatorColor: Colors.white,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white70,
                          tabs: const [
                            Tab(text: 'Students'),
                            Tab(text: 'Records'),
                            Tab(text: 'Reports'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildParentAssignmentTab(),
                      _buildClassAssignmentTab(),
                      _buildAttendanceTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ))

    );
  }

  Widget _buildParentAssignmentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ApiRbacWrapper(
            apiEndpoint: 'PUT /api/student/assignstudent',
            child: _buildSectionCard(
              'Assign Student to Parent',
              Icons.person_add,
              Colors.green,
              () => _showAssignParentDialog(),
            ),
          ),
          const SizedBox(height: 16),
          ApiRbacWrapper(
            apiEndpoint: 'PUT /api/student/removestudent',
            child: _buildSectionCard(
              'Remove Student from Parent',
              Icons.person_remove,
              Colors.red,
              () => _showRemoveParentDialog(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassAssignmentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ApiRbacWrapper(
            apiEndpoint: 'PUT /api/studentrecord/assign',
            child: _buildSectionCard(
              'Assign Student to Class',
              Icons.school,
              Colors.blue,
              () => _showAssignClassDialog(),
            ),
          ),
          const SizedBox(height: 16),
          ApiRbacWrapper(
            apiEndpoint: 'PUT /api/studentrecord/remove',
            child: _buildSectionCard(
              'Remove Student from Class',
              Icons.remove_circle,
              Colors.orange,
              () => _showRemoveClassDialog(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ApiRbacWrapper(
            apiEndpoint: 'GET /api/attendance/student',
            child: _buildSectionCard(
              'View Student Attendance',
              Icons.calendar_today,
              Colors.purple,
              () => _showAttendanceDialog(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoPermissionWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Access Denied',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'You don\'t have permission to access this feature',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAssignParentDialog() {
    final parentIdController = TextEditingController();
    final studentIdController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Assign Student to Parent'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: parentIdController,
              decoration: const InputDecoration(
                labelText: 'Parent ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: studentIdController,
              decoration: const InputDecoration(
                labelText: 'Student ID',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          Obx(() => ElevatedButton(
            onPressed: controller.isLoading.value ? null : () async {
              if (parentIdController.text.isNotEmpty && studentIdController.text.isNotEmpty) {
                final success = await controller.assignStudentToParent(
                  parentIdController.text,
                  studentIdController.text,
                );
                if (success) Get.back();
              }
            },
            child: controller.isLoading.value 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Assign'),
          )),
        ],
      ),
    );
  }

  void _showRemoveParentDialog() {
    final parentIdController = TextEditingController();
    final studentIdController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Remove Student from Parent'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: parentIdController,
              decoration: const InputDecoration(
                labelText: 'Parent ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: studentIdController,
              decoration: const InputDecoration(
                labelText: 'Student ID',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          Obx(() => ElevatedButton(
            onPressed: controller.isLoading.value ? null : () async {
              if (parentIdController.text.isNotEmpty && studentIdController.text.isNotEmpty) {
                final success = await controller.removeStudentFromParent(
                  parentIdController.text,
                  studentIdController.text,
                );
                if (success) Get.back();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: controller.isLoading.value 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Remove'),
          )),
        ],
      ),
    );
  }

  void _showAssignClassDialog() {
    final formKey = GlobalKey<FormState>();
    final controllers = {
      'schoolId': TextEditingController(text: authController.user.value?.schoolId ?? ''),
      'studentId': TextEditingController(),
      'classId': TextEditingController(),
      'sectionId': TextEditingController(),
      'academicYear': TextEditingController(),
      'rollNumber': TextEditingController(),
      'sectionName': TextEditingController(),
      'className': TextEditingController(),
      'studentName': TextEditingController(),
    };
    bool isBusApplicable = false;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Assign Student to Class'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...controllers.entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: entry.value,
                      decoration: InputDecoration(
                        labelText: entry.key.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim(),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty == true ? 'Required' : null,
                    ),
                  )),
                  CheckboxListTile(
                    title: const Text('Bus Applicable'),
                    value: isBusApplicable,
                    onChanged: (value) => setState(() => isBusApplicable = value ?? false),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
            Obx(() => ElevatedButton(
              onPressed: controller.isLoading.value ? null : () async {
                if (formKey.currentState?.validate() == true) {
                  final data = {
                    for (var entry in controllers.entries) entry.key: entry.value.text,
                    'isBusApplicable': isBusApplicable,
                    'newOld': 'new',
                  };
                  final success = await controller.assignStudentToClass(data);
                  if (success) Get.back();
                }
              },
              child: controller.isLoading.value 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Assign'),
            )),
          ],
        ),
      ),
    );
  }

  void _showRemoveClassDialog() {
    final schoolIdController = TextEditingController(text: authController.user.value?.schoolId ?? '');
    final studentIdController = TextEditingController();
    final academicYearController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Remove Student from Class'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: schoolIdController,
              decoration: const InputDecoration(
                labelText: 'School ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: studentIdController,
              decoration: const InputDecoration(
                labelText: 'Student ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: academicYearController,
              decoration: const InputDecoration(
                labelText: 'Academic Year',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          Obx(() => ElevatedButton(
            onPressed: controller.isLoading.value ? null : () async {
              if (schoolIdController.text.isNotEmpty && 
                  studentIdController.text.isNotEmpty && 
                  academicYearController.text.isNotEmpty) {
                final success = await controller.removeStudentFromClass(
                  schoolIdController.text,
                  studentIdController.text,
                  academicYearController.text,
                );
                if (success) Get.back();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: controller.isLoading.value 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Remove'),
          )),
        ],
      ),
    );
  }

  void _showAttendanceDialog() {
    final studentIdController = TextEditingController();
    int? selectedMonth;
    int? selectedYear;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('View Student Attendance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: studentIdController,
                decoration: const InputDecoration(
                  labelText: 'Student ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedMonth,
                decoration: const InputDecoration(
                  labelText: 'Month (Optional)',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(12, (index) => DropdownMenuItem(
                  value: index + 1,
                  child: Text('${index + 1}'),
                )),
                onChanged: (value) => setState(() => selectedMonth = value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedYear,
                decoration: const InputDecoration(
                  labelText: 'Year (Optional)',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(5, (index) => DropdownMenuItem(
                  value: DateTime.now().year - 2 + index,
                  child: Text('${DateTime.now().year - 2 + index}'),
                )),
                onChanged: (value) => setState(() => selectedYear = value),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
            Obx(() => ElevatedButton(
              onPressed: controller.isLoading.value ? null : () async {
                if (studentIdController.text.isNotEmpty) {
                  final data = await controller.getStudentAttendance(
                    studentIdController.text,
                    month: selectedMonth,
                    year: selectedYear,
                  );
                  Get.back();
                  if (data != null) {
                    _showAttendanceResults(data);
                  }
                }
              },
              child: controller.isLoading.value 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('View'),
            )),
          ],
        ),
      ),
    );
  }

  void _showAttendanceResults(Map<String, dynamic> data) {
    Get.dialog(
      AlertDialog(
        title: const Text('Attendance Results'),
        content: SingleChildScrollView(
          child: Text(data.toString()),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

  bool _hasPermission(List<String> allowedRoles) {
    final userRole = authController.user.value?.role.toLowerCase();
    return userRole != null && allowedRoles.map((r) => r.toLowerCase()).contains(userRole);
  }
}