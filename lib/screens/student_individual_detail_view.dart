import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/student_management_controller.dart';
import 'package:school_app/controllers/user_management_controller.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/controllers/club_controller.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/models/student_model.dart';
import 'package:school_app/models/school_models.dart';
import 'package:school_app/services/api_service.dart';
import 'package:school_app/core/theme/app_theme.dart';

class StudentIndividualDetailView extends StatelessWidget {
  final Student student;
  final String schoolId;

  const StudentIndividualDetailView({
    Key? key,
    required this.student,
    required this.schoolId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final studentController = Get.put(StudentManagementController());
    final userController = Get.put(UserManagementController());
    final schoolController = Get.find<SchoolController>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with gradient
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Hero(
                        tag: 'student_${student.id}',
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: Text(
                              (student.name ?? 'S').substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        student.name ?? 'Unknown Student',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Roll: ${student.rollNumber ?? 'N/A'}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Quick Info Card
                  _buildQuickInfoCard(),
                  const SizedBox(height: 16),
                  
                  // Personal Information
                  _buildSectionCard(
                    'Personal Information',
                    Icons.person,
                    Colors.blue,
                    [
                      _buildInfoRow('Gender', student.gender),
                      _buildInfoRow('Date of Birth', student.dob),
                      _buildInfoRow('Blood Group', student.bloodGroup),
                      _buildInfoRow('Mother Tongue', student.motherTongue),
                      _buildInfoRow('Height (cm)', student.heightInCm),
                      _buildInfoRow('Weight (kg)', student.weightInKg),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Family Information
                  _buildSectionCard(
                    'Family Information',
                    Icons.family_restroom,
                    Colors.green,
                    [
                      _buildInfoRow('Father Name', student.fatherName),
                      _buildInfoRow('Mother Name', student.motherName),
                      _buildInfoRow('Guardian Name', student.guardianName),
                      _buildInfoRow('Mobile Number', student.mobileNumber),
                      _buildInfoRow('Alternate Mobile', student.alternateMobile),
                      _buildInfoRow('Email', student.email),
                      _buildInfoRow('Parent Education Level', student.parentEducationLevel),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Address Information
                  _buildSectionCard(
                    'Address Information',
                    Icons.location_on,
                    Colors.orange,
                    [
                      _buildInfoRow('Address', student.address),
                      _buildInfoRow('Pincode', student.pincode),
                      _buildInfoRow('Distance to School', student.distanceToSchool),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Academic Information
                  _buildSectionCard(
                    'Academic Information',
                    Icons.school,
                    Colors.purple,
                    [
                      _buildInfoRow('Admission Date', student.admissionDate),
                      _buildInfoRow('Medium of Instruction', student.mediumOfInstruction),
                      _buildInfoRow('Languages Studied', student.languagesStudied),
                      _buildInfoRow('Academic Stream', student.academicStream),
                      _buildInfoRow('Subjects Studied', student.subjectsStudied),
                      _buildInfoRow('Previous Result', student.previousResult),
                      _buildInfoRow('Marks Obtained %', student.marksObtainedPercentage),
                      _buildInfoRow('Days Attended Last Year', student.daysAttendedLastYear),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Clubs Information
                  _buildClubsSection(context),
                  const SizedBox(height: 16),
                  
                  // Government Information
                  _buildSectionCard(
                    'Government Information',
                    Icons.account_balance,
                    Colors.indigo,
                    [
                      _buildInfoRow('Aadhaar Number', student.aadhaarNumber),
                      _buildInfoRow('Aadhaar Name', student.aadhaarName),
                      _buildInfoRow('Education Number', student.educationNumber),
                      _buildInfoRow('Social Category', student.socialCategory),
                      _buildInfoRow('Minority Group', student.minorityGroup),
                      _buildInfoRow('BPL', student.bpl),
                      _buildInfoRow('AAY', student.aay),
                      _buildInfoRow('EWS', student.ews),
                      _buildInfoRow('CWSN', student.cwsn),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Action Buttons
                  _buildActionButtons(context, studentController, userController, schoolController),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.info, color: Color(0xFF667eea)),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Quick Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickInfoItem('Student ID', student.id.substring(student.id.length - 8)),
              ),
              Expanded(
                child: _buildQuickInfoItem('Admission No', student.admissionNumber ?? 'N/A'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<Map<String, dynamic>?>(
            future: Get.put(StudentManagementController()).getStudentParent(student.id),
            builder: (context, snapshot) {
              return _buildQuickInfoItem(
                'Parent Status',
                snapshot.hasData && snapshot.data != null
                    ? '✓ ${snapshot.data!['userName'] ?? 'Assigned'}'
                    : '✗ Not assigned',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfoItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, Color color, List<Widget> children) {
    final validChildren = children.where((child) => child is! SizedBox || (child as SizedBox).height != 0).toList();
    
    if (validChildren.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: validChildren),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, StudentManagementController studentController, UserManagementController userController, SchoolController schoolController) {
    // Check user role for button visibility
    final authController = Get.find<AuthController>();
    final userRole = authController.user.value?.role?.toLowerCase() ?? '';
    final canManage = ['correspondent', 'administrator'].contains(userRole);
    
    if (!canManage) {
      return const SizedBox.shrink(); // Hide all buttons if no permission
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.settings, color: Colors.blue),
              ),
              const SizedBox(width: 16),
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [
              _buildActionButton(
                'Assign Parent',
                Icons.family_restroom,
                Colors.blue,
                () => _showAssignToParentDialog(context, student, userController),
              ),
              _buildActionButton(
                'Remove Parent',
                Icons.person_remove,
                Colors.red,
                () => _showRemoveFromParentDialog(context, student, studentController),
              ),
              _buildActionButton(
                'Assign Class',
                Icons.class_,
                Colors.green,
                () => _showAssignToClassDialog(context, student, schoolController),
              ),
              _buildActionButton(
                'Remove Class',
                Icons.class_outlined,
                Colors.orange,
                () => _showRemoveFromClassDialog(context, student, studentController),
              ),
              // _buildActionButton(
              //   'Manage Clubs',
              //   Icons.groups,
              //   Colors.teal,
              //   () => _showManageClubsDialog(context),
              // ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _buildActionButton(
              'View Attendance',
              Icons.calendar_today,
              Colors.purple,
              () => _showAttendanceDialog(context, student, studentController),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _showAssignToParentDialog(BuildContext context, Student student, UserManagementController userController) {
    final searchController = TextEditingController();
    final parentUsers = <Map<String, dynamic>>[].obs;
    final filteredParents = <Map<String, dynamic>>[].obs;
    final selectedParent = Rxn<Map<String, dynamic>>();
    final isLoadingParents = false.obs;
    
    void loadParents() async {
      isLoadingParents.value = true;
      try {
        await userController.loadUsers(schoolId: schoolId, role: 'parent');
        parentUsers.value = List<Map<String, dynamic>>.from(userController.users);
        filteredParents.value = parentUsers;
      } catch (e) {
        
      } finally {
        isLoadingParents.value = false;
      }
    }
    
    void filterParents(String query) {
      if (query.isEmpty) {
        filteredParents.value = parentUsers;
      } else {
        filteredParents.value = parentUsers.where((parent) {
          final name = parent['userName']?.toString().toLowerCase() ?? '';
          final email = parent['email']?.toString().toLowerCase() ?? '';
          return name.contains(query.toLowerCase()) || email.contains(query.toLowerCase());
        }).toList();
      }
    }
    
    loadParents();
    
    Get.dialog(
      AlertDialog(
        title: Text('Assign ${student.name} to Parent'),
        content: SizedBox(
          width: 400,
          height: 400,
          child: Column(
            children: [
              TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  labelText: 'Search Parent',
                  hintText: 'Search by name or email',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: filterParents,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Obx(() {
                  if (isLoadingParents.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (filteredParents.isEmpty) {
                    return const Center(child: Text('No parents found'));
                  }
                  
                  return ListView.builder(
                    itemCount: filteredParents.length,
                    itemBuilder: (context, index) {
                      final parent = filteredParents[index];
                      return Obx(() => RadioListTile<Map<String, dynamic>>(
                        title: Text(parent['userName'] ?? 'Unknown'),
                        subtitle: Text(parent['email'] ?? 'No email'),
                        value: parent,
                        groupValue: selectedParent.value,
                        onChanged: (value) => selectedParent.value = value,
                      ));
                    },
                  );
                }),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          Obx(() => ElevatedButton(
            onPressed: selectedParent.value != null ? () async {
              final studentController = Get.put(StudentManagementController());
              final success = await studentController.assignStudentToParent(
                selectedParent.value!['_id'],
                student.id,
              );
              if (success) {
                Navigator.of(context).pop();
                // Refresh the current page by rebuilding the widget
                (context as Element).markNeedsBuild();
              }
            } : null,
            child: const Text('Assign'),
          )),
        ],
      ),
    );
  }

  void _showRemoveFromParentDialog(BuildContext context, Student student, StudentManagementController studentController) {
    Get.dialog(
      AlertDialog(
        title: Text('Remove ${student.name} from Parent'),
        content: FutureBuilder<Map<String, dynamic>?>(
          future: studentController.getStudentParent(student.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            
            if (!snapshot.hasData || snapshot.data == null) {
              return const Text('No parent assigned to this student.');
            }
            
            final parent = snapshot.data!;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Remove student from parent: ${parent['userName']}?'),
                const SizedBox(height: 8),
                Text('Email: ${parent['email'] ?? 'N/A'}'),
              ],
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final parent = await studentController.getStudentParent(student.id);
              if (parent != null) {
                final success = await studentController.removeStudentFromParent(
                  parent['_id'],
                  student.id,
                );
                if (success) {
                  Navigator.of(context).pop();
                  // Refresh the current page by rebuilding the widget
                  (context as Element).markNeedsBuild();
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showAssignToClassDialog(BuildContext context, Student student, SchoolController schoolController) {
    SchoolClass? selectedClass;
    Section? selectedSection;
    final rollNumberController = TextEditingController();
    final academicYearController = TextEditingController(text: '2025-2026');
    bool isBusApplicable = false;
    
    Get.dialog(
      AlertDialog(
        title: Text('Assign ${student.name} to Class'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<SchoolClass>(
                    decoration: const InputDecoration(labelText: 'Select Class'),
                    value: schoolController.classes.contains(selectedClass) ? selectedClass : null,
                    items: schoolController.classes.map((cls) {
                      return DropdownMenuItem(value: cls, child: Text(cls.name));
                    }).toList(),
                    onChanged: (cls) {
                      setState(() {
                        selectedClass = cls;
                        selectedSection = null;
                      });
                      if (cls != null) {
                        schoolController.getAllSections(schoolId: schoolId);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Section>(
                    decoration: const InputDecoration(labelText: 'Select Section'),
                    value: schoolController.sections.contains(selectedSection) ? selectedSection : null,
                    items: schoolController.sections.map((section) {
                      return DropdownMenuItem(
                        value: section, 
                        child: Text('${section.name} (${section.id.substring(section.id.length - 4)})')
                      );
                    }).toList(),
                    onChanged: (section) => setState(() => selectedSection = section),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: rollNumberController,
                    decoration: const InputDecoration(labelText: 'Roll Number'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: academicYearController,
                    decoration: const InputDecoration(labelText: 'Academic Year'),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Bus Applicable'),
                    value: isBusApplicable,
                    onChanged: (value) => setState(() => isBusApplicable = value ?? false),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (selectedClass != null && selectedSection != null) {
                final studentController = Get.put(StudentManagementController());
                final success = await studentController.assignStudentToClass({
                  'schoolId': schoolId,
                  'studentId': student.id,
                  'classId': selectedClass!.id,
                  'sectionId': selectedSection!.id,
                  'academicYear': academicYearController.text,
                  'newOld': 'new',
                  'rollNumber': rollNumberController.text,
                  'sectionName': selectedSection!.name,
                  'className': selectedClass!.name,
                  'isBusApplicable': isBusApplicable,
                  'studentName': student.name,
                });
                if (success) {
                  Navigator.of(context).pop();
                  // Refresh the current page by rebuilding the widget
                  (context as Element).markNeedsBuild();
                }
              }
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  void _showRemoveFromClassDialog(BuildContext context, Student student, StudentManagementController studentController) {
    final academicYearController = TextEditingController(text: '2025-2026');
    
    Get.dialog(
      AlertDialog(
        title: Text('Remove ${student.name} from Class'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This will remove the student from their current class assignment.'),
            const SizedBox(height: 16),
            TextField(
              controller: academicYearController,
              decoration: const InputDecoration(
                labelText: 'Academic Year',
                hintText: 'e.g., 2025-2026',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final success = await studentController.removeStudentFromClass(
                schoolId,
                student.id,
                academicYearController.text,
              );
              if (success) {
                Navigator.of(context).pop();
                // Refresh the current page by rebuilding the widget
                (context as Element).markNeedsBuild();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showAttendanceDialog(BuildContext context, Student student, StudentManagementController studentController) {
    int? selectedMonth;
    int? selectedYear = DateTime.now().year;
    
    Get.dialog(
      AlertDialog(
        title: Text('${student.name} - Attendance'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Select Month'),
                  value: selectedMonth,
                  items: List.generate(12, (index) {
                    return DropdownMenuItem(
                      value: index + 1,
                      child: Text(_getMonthName(index + 1)),
                    );
                  }),
                  onChanged: (month) => setState(() => selectedMonth = month),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Select Year'),
                  value: selectedYear,
                  items: List.generate(55, (index) => DateTime.now().year - 25 + index)
                      .map((year) => DropdownMenuItem(
                    value: year,
                    child: Text(year.toString()),
                  ))
                      .toList(),
                  onChanged: (year) => setState(() => selectedYear = year),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen),
            onPressed: () async {
              Get.back();
              final attendance = await studentController.getStudentAttendance(
                student.id,
                month: selectedMonth,
                year: selectedYear,
              );
              if (attendance != null) {
                _showAttendanceDetails(student, attendance);
              } else {
                Get.snackbar('Info', 'No attendance data found for the selected period');
              }
            },
            child: const Text('View Attendance'),
          ),
        ],
      ),
    );
  }

  void _showAttendanceDetails(Student student, Map<String, dynamic> attendance) {
    Get.dialog(
      AlertDialog(
        title: Text('${student.name} - Attendance Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Days:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('${attendance['totalDays'] ?? 0}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Present Days:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          Text('${attendance['presentDays'] ?? 0}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Absent Days:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                          Text('${attendance['absentDays'] ?? 0}'),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Attendance %:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('${attendance['percentage'] ?? 0}%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Widget _buildInfoRow(String label, String? value) {
    if (value == null || value.isEmpty || value == 'null') {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClubsSection(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _getStudentClubs(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final clubs = snapshot.data ?? [];
            
            return _buildSectionCard(
              'Club Memberships',
              Icons.groups,
              Colors.teal,
              clubs.isEmpty 
                ? [const Text('No club memberships found', style: TextStyle(color: Colors.grey))]
                : clubs.map((club) => _buildClubItem(context, club, setState)).toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildClubItem(BuildContext context, Map<String, dynamic> club, StateSetter setState) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.group, color: Colors.teal.shade700, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  club['name'] ?? 'Unknown Club',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (club['description'] != null)
                  Text(
                    club['description'],
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            child: ElevatedButton(
              onPressed: () => _showRemoveFromClubDialog(context, club, setState),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade100,
                foregroundColor: Colors.red.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              child: const Text('Remove', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getStudentClubs() async {
    try {

      // Get all clubs first
      final response = await Get.find<ApiService>().get('/api/club/getall', queryParameters: {
        'schoolId': schoolId,
      });

      if (response.data['ok'] == true) {
        final allClubs = List<Map<String, dynamic>>.from(response.data['data'] ?? []);

        // Get student's club IDs from the student.clubs array
        final studentClubIds = student.clubs ?? [];

        // Filter clubs that match the student's club IDs
        final studentClubs = allClubs.where((club) {
          final clubId = club['_id'];
          final hasStudent = studentClubIds.contains(clubId);
          
          return hasStudent;
        }).toList();

        return studentClubs;
      } else {
        
        return [];
      }
    } catch (e) {
      
      return [];
    }
  }

  void _showRemoveFromClubDialog(BuildContext context, Map<String, dynamic> club, StateSetter setState) {
    final clubId = club['_id'];

    if (clubId == null || clubId.toString().isEmpty) {
      
      Get.snackbar('Error', 'Invalid club ID, cannot remove student from club',
        backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    
    Get.dialog(
      AlertDialog(
        title: const Text('Remove from Club'),
        content: Text('Are you sure you want to remove ${student.name} from ${club['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {

                final clubController = Get.find<ClubController>();
                await clubController.toggleStudentClub(student.id, clubId.toString(), false);
                
                // Update local student clubs array
                student.clubs?.remove(clubId.toString());
                
                Get.back();
                Get.snackbar('Success', 'Student removed from club successfully',
                  backgroundColor: Colors.green, colorText: Colors.white);
                
                // Refresh the clubs section
                setState(() {});
              } catch (e) {
                
                Get.snackbar('Error', 'Failed to remove student from club: ${e.toString()}',
                  backgroundColor: Colors.red, colorText: Colors.white);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showManageClubsDialog(BuildContext context) {
    final clubController = Get.find<ClubController>();
    final selectedClubs = <String>[].obs;
    final availableClubs = <Map<String, dynamic>>[].obs;
    final isLoading = false.obs;
    
    // Load clubs and current memberships
    void loadData() async {
      isLoading.value = true;
      try {
        
        await clubController.getAllClubs(schoolId: schoolId);
        availableClubs.value = clubController.clubs;
        
        // Get current club memberships
        final currentClubs = await _getStudentClubs();
        selectedClubs.value = currentClubs.map((club) => club['_id'] as String).toList();

      } catch (e) {
        
      } finally {
        isLoading.value = false;
      }
    }
    
    loadData();
    
    Get.dialog(
      AlertDialog(
        title: Text('Manage Clubs for ${student.name}'),
        content: SizedBox(
          width: 400,
          height: 400,
          child: Obx(() {
            if (isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (availableClubs.isEmpty) {
              return const Center(child: Text('No clubs available'));
            }
            
            return ListView.builder(
              itemCount: availableClubs.length,
              itemBuilder: (context, index) {
                final club = availableClubs[index];
                final clubId = club['_id'] as String;
                
                return Obx(() => CheckboxListTile(
                  title: Text(club['name'] ?? 'Unknown Club'),
                  subtitle: Text(club['description'] ?? ''),
                  value: selectedClubs.contains(clubId),
                  onChanged: (bool? value) {
                    if (value == true) {
                      selectedClubs.add(clubId);
                    } else {
                      selectedClubs.remove(clubId);
                    }
                  },
                ));
              },
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {

                // Get current memberships to compare
                final currentClubs = await _getStudentClubs();
                final currentClubIds = currentClubs.map((club) => club['_id'] as String).toSet();
                final newClubIds = selectedClubs.toSet();
                
                // Find clubs to add and remove
                final clubsToAdd = newClubIds.difference(currentClubIds).toList();
                final clubsToRemove = currentClubIds.difference(newClubIds).toList();

                // Add to new clubs
                for (String clubId in clubsToAdd) {
                  if (clubId.isNotEmpty) {
                    
                    await clubController.toggleStudentClub(student.id, clubId, true);
                  } else {
                    
                  }
                }
                
                // Remove from old clubs
                for (String clubId in clubsToRemove) {
                  if (clubId.isNotEmpty) {
                    
                    await clubController.toggleStudentClub(student.id, clubId, false);
                  } else {
                    
                  }
                }
                
                Get.back();
                Get.snackbar('Success', 'Club memberships updated successfully',
                  backgroundColor: Colors.green, colorText: Colors.white);
                // Refresh the view
                (context as Element).markNeedsBuild();
              } catch (e) {
                
                Get.snackbar('Error', 'Failed to update club memberships: ${e.toString()}',
                  backgroundColor: Colors.red, colorText: Colors.white);
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}