import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../modules/auth/controllers/auth_controller.dart';
import '../controllers/school_controller.dart';
import '../controllers/student_management_controller.dart';
import '../core/theme/app_theme.dart';
import 'student_individual_detail_view.dart';

class TeacherClassesView extends StatefulWidget {
  const TeacherClassesView({super.key});

  @override
  State<TeacherClassesView> createState() => _TeacherClassesViewState();
}

class _TeacherClassesViewState extends State<TeacherClassesView> {
  final AuthController authController = Get.find<AuthController>();
  final SchoolController schoolController = Get.find<SchoolController>();
  final StudentManagementController studentController =
  Get.put(StudentManagementController());

  String? selectedClassId;
  String? selectedSectionId;
  bool _initialized = false;

  // ================= HELPERS =================

  String? _extractClassId(dynamic classId) {
    if (classId is String) return classId;
    if (classId is Map<String, dynamic>) return classId['_id'];
    return null;
  }

  // ================= ASSIGNMENTS =================

  List<Map<String, dynamic>> get teacherAssignments {
    final user = authController.user.value;
    if (user == null) return [];
    return List<Map<String, dynamic>>.from(user.assignments);
  }

  /// Classes assigned to teacher (resolved with names)
  List<Map<String, String>> get assignedClasses {
    final assignments = teacherAssignments;
    final classes = schoolController.classes;

    final classIds = assignments
        .map((a) => _extractClassId(a['classId']))
        .whereType<String>()
        .toSet();

    if (classIds.isEmpty) return [];
    return classIds.map((id) {
      final cls = classes.firstWhereOrNull((c) => c.id == id);
      return {
        'id': id,
        'name': cls?.name ?? 'Class',
      };
    }).toList();
  }

  /// Sections for selected class
  List<Map<String, String?>> get sectionsForSelectedClass {
    if (selectedClassId == null) return [];

    final sections = <Map<String, String?>>[];
    bool hasAllSectionsAccess = false;

    // Check teacher assignments for this class
    for (final a in teacherAssignments) {
      final classId = _extractClassId(a['classId']);
      if (classId != selectedClassId) continue;

      final sectionId = a['sectionId'];

      if (sectionId == null) {
        // Teacher has access to all sections of this class
        hasAllSectionsAccess = true;
      } else {
        final sec = schoolController.sections
            .firstWhereOrNull((s) => s.id == sectionId);
        if (sec != null) {
          sections.add({
            'id': sectionId,
            'name': sec.name,
          });
        }
      }
    }

    // If teacher has all sections access, show all available sections for this class
    if (hasAllSectionsAccess || sections.isEmpty) {
      final availableSections = schoolController.sections
          .where((s) => s.classId == selectedClassId)
          .toList();

      if (availableSections.isNotEmpty) {
        // Add "All Sections" option first
        sections.insert(0, {'id': null, 'name': 'All Sections'});

        // If teacher has all sections access, add all individual sections
        if (hasAllSectionsAccess) {
          for (final sec in availableSections) {
            // Avoid duplicates
            if (!sections.any((s) => s['id'] == sec.id)) {
              sections.add({
                'id': sec.id,
                'name': sec.name,
              });
            }
          }
        }
      } else {
        // Fallback if no sections found
        sections.add({'id': null, 'name': 'All Sections'});
      }
    }

    return sections;
  }

  // ================= INIT =================

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    if (_initialized) return;

    // For teachers, set selectedSchool from user data if not already set
    if (schoolController.selectedSchool.value == null) {
      final user = authController.user.value;
      if (user?.schoolId != null) {
        // Find the school in the controller's schools list or set it directly
        final school = schoolController.schools.firstWhereOrNull((s) => s.id == user?.schoolId);
        if (school != null) {
          schoolController.selectedSchool.value = school;
        } else {
          await schoolController.getAllSchools();
          final foundSchool = schoolController.schools.firstWhereOrNull((s) => s.id == user?.schoolId);
          if (foundSchool != null) {
            schoolController.selectedSchool.value = foundSchool;
          } else {
            return;
          }
        }
      } else {
        return;
      }
    }

    _initialized = true;

    final schoolId = schoolController.selectedSchool.value!.id;

    // Load school data
    await schoolController.getAllClasses(schoolId);
    await schoolController.getAllSections(schoolId: schoolId);

    // Auto-select first class
    if (assignedClasses.isNotEmpty && mounted) {
      setState(() {
        selectedClassId = assignedClasses.first['id'];
      });
    }

    // Auto-select first section
    if (sectionsForSelectedClass.isNotEmpty && mounted) {
      setState(() {
        selectedSectionId = sectionsForSelectedClass.first['id'];
      });
      _loadStudents();
    }
  }

  Future<void> _loadStudents() async {
    if (selectedClassId == null ||
        selectedSectionId == null ||
        schoolController.selectedSchool.value == null) {
      return;
    }

    await studentController.getStudentsByClassAndSection(
      schoolId: schoolController.selectedSchool.value!.id,
      classId: selectedClassId!,
      sectionId: selectedSectionId!,
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLandscape = screenSize.width > screenSize.height;

    // Check if teacher has no assignments
    if (teacherAssignments.isEmpty) {
      final teacherName = authController.user.value?.userName ?? 'this teacher';
      return Scaffold(
        backgroundColor: AppTheme.appBackground,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: false,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'My Classes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'View your assigned classes',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: Container(
              margin: EdgeInsets.all(AppTheme.getResponsivePadding(context)),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient,
                borderRadius: BorderRadius.circular(AppTheme.radius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppTheme.warningGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.school_outlined,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Classes Assigned',
                    style: TextStyle(
                      fontSize: isTablet ? 24 : 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No classes were assigned to $teacherName yet.\nPlease contact your administrator.',
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      color: AppTheme.mutedText,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'My Classes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Manage your students',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.all(AppTheme.getResponsivePadding(context)),
          child: Column(
            children: [
              // Selection Cards Container
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.cardGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.filter_list,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select Class & Section',
                                style: TextStyle(
                                  fontSize: isTablet ? 18 : 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Choose your assigned class and section to view students',
                                style: TextStyle(
                                  fontSize: isTablet ? 14 : 12,
                                  color: AppTheme.mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Class and Section in responsive layout
                    isLandscape && isTablet
                        ? Row(
                            children: [
                              Expanded(child: _buildClassSelector(context)),
                              const SizedBox(width: 16),
                              if (selectedClassId != null)
                                Expanded(child: _buildSectionSelector(context)),
                            ],
                          )
                        : Column(
                            children: [
                              _buildClassSelector(context),
                              if (selectedClassId != null) ...[
                                const SizedBox(height: 16),
                                _buildSectionSelector(context),
                                if (selectedSectionId != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryBlue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: AppTheme.primaryBlue,
                                          size: isTablet ? 18 : 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Builder(
                                            builder: (context) {
                                              final selectedSection = sectionsForSelectedClass
                                                  .firstWhereOrNull((s) => s['id'] == selectedSectionId);
                                              final sectionName = selectedSection?['name'] ?? 'selected section';

                                              return Text(
                                                selectedSectionId == null
                                                    ? 'Showing students from all sections of the selected class'
                                                    : 'Showing students from $sectionName',
                                                style: TextStyle(
                                                  color: AppTheme.primaryBlue,
                                                  fontSize: isTablet ? 14 : 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Student List
              if (selectedClassId != null && selectedSectionId != null)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.cardGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Student List Header
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: AppTheme.successGradient,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(AppTheme.radius),
                              topRight: Radius.circular(AppTheme.radius),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.people_outline,
                                color: Colors.white,
                                size: isTablet ? 24 : 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Obx(() {
                                  final students = studentController.studentsByClassSection;
                                  return Text(
                                    'Students (${students.length})',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isTablet ? 20 : 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  );
                                }),
                              ),
                              IconButton(
                                onPressed: _loadStudents,
                                icon: const Icon(
                                  Icons.refresh,
                                  color: Colors.white,
                                ),
                                tooltip: 'Refresh',
                              ),
                            ],
                          ),
                        ),

                        // Student List Content
                        Expanded(
                          child: Obx(() {
                            if (studentController.isLoading.value) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: isTablet ? 40 : 32,
                                      height: isTablet ? 40 : 32,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        valueColor: AlwaysStoppedAnimation(AppTheme.primaryBlue),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Loading students...',
                                      style: TextStyle(
                                        color: AppTheme.mutedText,
                                        fontSize: isTablet ? 20 : 16,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final students = studentController.studentsByClassSection;

                            if (students.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      size: isTablet ? 64 : 48,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No students found',
                                      style: TextStyle(
                                        color: AppTheme.mutedText,
                                        fontSize: isTablet ? 30 : 25,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: students.length,
                              itemBuilder: (context, index) {
                                final student = students[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    leading: Container(
                                      width: isTablet ? 50 : 45,
                                      height: isTablet ? 50 : 45,
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.primaryGradient,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          student.rollNumber ??
                                              student.name?.substring(0, 1).toUpperCase() ??
                                              '?',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      student.name ?? 'Student',
                                      style: TextStyle(
                                        fontSize: isTablet ? 20 : 18,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryText,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Roll: ${student.rollNumber ?? 'N/A'}',
                                      style: TextStyle(
                                        fontSize: isTablet ? 18 : 16,
                                        color: AppTheme.mutedText,
                                      ),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryBlue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.chevron_right,
                                        color: AppTheme.primaryBlue,
                                        size: isTablet ? 20 : 18,
                                      ),
                                    ),
                                    onTap: () {
                                      Get.to(
                                        () => StudentIndividualDetailView(
                                          student: student,
                                          schoolId: schoolController.selectedSchool.value!.id,
                                        ),
                                      );
                                    },
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassSelector(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return GetBuilder<SchoolController>(
      builder: (schoolController) {
        final assignments = teacherAssignments;
        final classes = schoolController.classes;

        final classIds = assignments
            .map((a) => _extractClassId(a['classId']))
            .whereType<String>()
            .toSet();

        if (classIds.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.orange.shade600,
                  size: isTablet ? 20 : 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No classes assigned',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: isTablet ? 14 : 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (classes.isEmpty && !_initialized) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: isTablet ? 24 : 20,
                  height: isTablet ? 24 : 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppTheme.primaryBlue),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Loading classes...',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: isTablet ? 14 : 12,
                  ),
                ),
              ],
            ),
          );
        }

        final dropdownItems = classIds.map((classId) {
          final cls = classes.firstWhereOrNull((c) => c.id == classId);
          final className = cls?.name ?? 'Class $classId';
          return DropdownMenuItem<String>(
            value: classId,
            child: Text(
              className,
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList();
        
        // Sort dropdown items by class name
        dropdownItems.sort((a, b) {
          final aClass = classes.firstWhereOrNull((c) => c.id == a.value);
          final bClass = classes.firstWhereOrNull((c) => c.id == b.value);
          if (aClass != null && bClass != null) {
            final aOrder = aClass.order ?? 999;
            final bOrder = bClass.order ?? 999;
            if (aOrder != bOrder) return aOrder.compareTo(bOrder);
            return _compareClassNames(aClass.name, bClass.name);
          }
          return 0;
        });

        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Select Class',
              labelStyle: TextStyle(
                color: AppTheme.mutedText,
                fontSize: isTablet ? 20 : 18,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.class_,
                  color: AppTheme.primaryBlue,
                  size: isTablet ? 20 : 18,
                ),
              ),
            ),
            dropdownColor: Colors.white,
            menuMaxHeight: 300,
            borderRadius: BorderRadius.circular(12),
            value: selectedClassId,
            items: dropdownItems,
            onChanged: (value) {
              setState(() {
                selectedClassId = value;
                selectedSectionId = null;
              });

              if (sectionsForSelectedClass.isNotEmpty) {
                setState(() {
                  selectedSectionId = sectionsForSelectedClass.first['id'];
                });
                _loadStudents();
              }
            },
            style: TextStyle(
              color: AppTheme.primaryText,
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionSelector(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return GetBuilder<SchoolController>(
      builder: (schoolController) {
        final sections = sectionsForSelectedClass;

        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonFormField<String?>(
            decoration: InputDecoration(
              labelText: 'Select Section',
              labelStyle: TextStyle(
                color: AppTheme.mutedText,
                fontSize: isTablet ? 20 : 18,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.group,
                  color: AppTheme.primaryBlue,
                  size: isTablet ? 20 : 18,
                ),
              ),
            ),
            dropdownColor: Colors.white,
            menuMaxHeight: 300,
            borderRadius: BorderRadius.circular(12),
            value: selectedSectionId,
            items: sections.map((sec) {
              return DropdownMenuItem<String?>(
                value: sec['id'],
                child: Text(
                  sec['name']!,
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => selectedSectionId = value);
              _loadStudents();
            },
            style: TextStyle(
              color: AppTheme.primaryText,
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      },
    );
  }

  // Custom class name comparator for school class hierarchy
  int _compareClassNames(String a, String b) {
    final aLower = a.toLowerCase().trim();
    final bLower = b.toLowerCase().trim();
    
    // Define the order priority
    int _getClassPriority(String className) {
      if (className == 'lkg') return 1;
      if (className == 'ukg') return 2;
      if (className.startsWith('grade ')) {
        final match = RegExp(r'grade ([ivx]+|\d+)', caseSensitive: false).firstMatch(className);
        if (match != null) {
          final gradeStr = match.group(1)!;
          // Handle Roman numerals
          final romanToInt = {'i': 1, 'ii': 2, 'iii': 3, 'iv': 4, 'v': 5, 'vi': 6, 'vii': 7, 'viii': 8, 'ix': 9, 'x': 10};
          if (romanToInt.containsKey(gradeStr)) {
            return 2 + romanToInt[gradeStr]!;
          }
          // Handle regular numbers
          final num = int.tryParse(gradeStr);
          if (num != null) return 2 + num;
        }
      }
      if (className.startsWith('class ')) {
        final match = RegExp(r'class (\d+)', caseSensitive: false).firstMatch(className);
        if (match != null) {
          final num = int.tryParse(match.group(1)!);
          if (num != null) return 20 + num; // Start after grades
        }
      }
      return 999; // Unknown classes go last
    }
    
    final aPriority = _getClassPriority(aLower);
    final bPriority = _getClassPriority(bLower);
    
    return aPriority.compareTo(bPriority);
  }
}
