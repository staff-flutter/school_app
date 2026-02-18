import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/teacher_assignment_controller.dart';
import '../controllers/student_record_controller.dart';
import '../controllers/announcement_controller.dart';
import '../controllers/club_controller.dart';
import '../controllers/fee_structure_controller.dart';
import '../modules/auth/controllers/auth_controller.dart';

class ApiTestView extends StatelessWidget {
  ApiTestView({super.key});

  final teacherController = Get.put(TeacherAssignmentController());
  final studentRecordController = Get.put(StudentRecordController());
  final announcementController = Get.put(AnnouncementController());
  final clubController = Get.put(ClubController());
  final feeController = Get.put(FeeStructureController());
  final authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Test Center'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Fee Structure APIs', [
              ElevatedButton(
                onPressed: () => _testGetFeeStructure(),
                child: const Text('Test Get Fee Structure'),
              ),
            ]),
            
            const SizedBox(height: 24),
            
            _buildSection('Teacher Assignment APIs (Toggle Scenarios)', [
              ElevatedButton(
                onPressed: () => _testScenario1(),
                child: const Text('Scenario 1: Add Single Section'),
              ),
              ElevatedButton(
                onPressed: () => _testScenario2(),
                child: const Text('Scenario 2: Remove Single Section'),
              ),
              ElevatedButton(
                onPressed: () => _testScenario3(),
                child: const Text('Scenario 3: Select All Class'),
              ),
              ElevatedButton(
                onPressed: () => _testScenario4(),
                child: const Text('Scenario 4: Deselect All Class'),
              ),
              ElevatedButton(
                onPressed: () => _testScenario5(),
                child: const Text('Scenario 5: Multi-Select Save'),
              ),
            ]),
            
            const SizedBox(height: 24),
            
            _buildSection('Student Record APIs', [
              ElevatedButton(
                onPressed: () => _testApplyConcession(),
                child: const Text('Test Apply Concession'),
              ),
              ElevatedButton(
                onPressed: () => _testCollectFee(),
                child: const Text('Test Collect Fee'),
              ),
              ElevatedButton(
                onPressed: () => _testGetStudentRecord(),
                child: const Text('Test Get Student Record'),
              ),
            ]),
            
            const SizedBox(height: 24),
            
            _buildSection('Announcement APIs', [
              ElevatedButton(
                onPressed: () => _testCreateAnnouncement(),
                child: const Text('Test Create Announcement'),
              ),
              ElevatedButton(
                onPressed: () => _testGetAnnouncements(),
                child: const Text('Test Get Announcements'),
              ),
            ]),
            
            const SizedBox(height: 24),
            
            _buildSection('Club APIs', [
              ElevatedButton(
                onPressed: () => _testGetClubs(),
                child: const Text('Test Get Clubs'),
              ),
              ElevatedButton(
                onPressed: () => _testCreateClub(),
                child: const Text('Test Create Club'),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> buttons) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: buttons,
        ),
      ],
    );
  }

  // Fee Structure Tests
  void _testGetFeeStructure() {
    final schoolId = authController.user.value?.schoolId ?? 'test_school_id';
    const classId = 'test_class_id';
    
    feeController.getFeeStructureByClass(schoolId, classId);
    Get.snackbar('Test', 'Testing Get Fee Structure API');
  }

  // Teacher Assignment Tests
  void _testScenario1() {
    // Scenario 1: Single Checkbox (Add a Section)
    teacherController.toggleSectionAssignment(
      'TEACHER_ID',
      'GRADE_10_ID',
      'SECTION_A_ID',
    );
    Get.snackbar('Test', 'Testing Scenario 1: Add Single Section');
  }

  void _testScenario2() {
    // Scenario 2: Single Checkbox (Remove a Section) - Same payload as Scenario 1
    teacherController.toggleSectionAssignment(
      'TEACHER_ID',
      'GRADE_10_ID',
      'SECTION_A_ID',
    );
    Get.snackbar('Test', 'Testing Scenario 2: Remove Single Section');
  }

  void _testScenario3() {
    // Scenario 3: "Select All" (Bulk Add Class)
    teacherController.toggleClassAssignment('TEACHER_ID', 'GRADE_10_ID');
    Get.snackbar('Test', 'Testing Scenario 3: Select All Class');
  }

  void _testScenario4() {
    // Scenario 4: "Deselect All" (Bulk Remove Class) - Same payload as Scenario 3
    teacherController.toggleClassAssignment('TEACHER_ID', 'GRADE_10_ID');
    Get.snackbar('Test', 'Testing Scenario 4: Deselect All Class');
  }

  void _testScenario5() {
    // Scenario 5: Multi-Select (The "Save" Button)
    final changes = [
      {'classId': 'LKG_ID'}, // Add LKG
      {'classId': 'GRADE_10_ID', 'sectionId': 'SEC_A_ID'}, // Remove 10-A
      {'classId': 'GRADE_5_ID', 'sectionId': 'SEC_B_ID'}, // Add 5-B
    ];
    
    teacherController.saveMultipleAssignments('TEACHER_ID', changes);
    Get.snackbar('Test', 'Testing Scenario 5: Multi-Select Save');
  }

  // Student Record Tests
  void _testApplyConcession() {
    final schoolId = authController.user.value?.schoolId ?? 'test_school_id';
    
    studentRecordController.applyConcession(
      schoolId: schoolId,
      studentId: 'test_student_id',
      studentName: 'Test Student',
      concessionType: 'percentage',
      concessionValue: 10.0,
      remark: 'Test concession',
      classId: 'test_class_id',
      sectionId: 'test_section_id',
      newOld: 'new',
      // newOld: 'new',
      busPoint: 'test_point',
      isBusApplicable: true, proofFile: null,
    );
    Get.snackbar('Test', 'Testing Apply Concession API');
  }

  void _testCollectFee() {
    final schoolId = authController.user.value?.schoolId ?? 'test_school_id';
    
    studentRecordController.collectFee(
      schoolId: schoolId,
      studentId: 'test_student_id',
      classId: 'test_class_id',
      sectionId: 'test_section_id',
      amount: 1000.0,
      paymentMode: 'cash',
    );
    Get.snackbar('Test', 'Testing Collect Fee API');
  }

  void _testGetStudentRecord() {
    final schoolId = authController.user.value?.schoolId ?? 'test_school_id';
    
    studentRecordController.getStudentRecord(schoolId, 'test_student_id');
    Get.snackbar('Test', 'Testing Get Student Record API');
  }

  // Announcement Tests
  void _testCreateAnnouncement() {
    final schoolId = authController.user.value?.schoolId ?? 'test_school_id';
    
    announcementController.createAnnouncement(
      schoolId: schoolId,
      academicYear: '2024-25',
      title: 'Test Announcement',
      description: 'This is a test announcement',
      type: 'general',
      priority: 'normal',
      targetAudience: ['all'],
    );
    Get.snackbar('Test', 'Testing Create Announcement API');
  }

  void _testGetAnnouncements() {
    final schoolId = authController.user.value?.schoolId ?? 'test_school_id';
    
    announcementController.getAllAnnouncements(schoolId);
    Get.snackbar('Test', 'Testing Get Announcements API');
  }

  // Club Tests
  void _testGetClubs() {
    final schoolId = authController.user.value?.schoolId;
    
    clubController.getAllClubs(schoolId: schoolId);
    Get.snackbar('Test', 'Testing Get Clubs API');
  }

  void _testCreateClub() {
    final schoolId = authController.user.value?.schoolId ?? 'test_school_id';
    
    clubController.createClub(
      name: 'Test Club',
      description: 'This is a test club',
      schoolId: schoolId, classId: '',
    );
    Get.snackbar('Test', 'Testing Create Club API');
  }
}