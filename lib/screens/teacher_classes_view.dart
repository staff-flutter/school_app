import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/controllers/student_management_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/screens/student_individual_detail_view.dart';

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

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String? _extractClassId(dynamic classId) {
    if (classId is String) return classId;
    if (classId is Map<String, dynamic>) return classId['_id'];
    return null;
  }

  List<Map<String, dynamic>> get teacherAssignments {
    final user = authController.user.value;
    if (user == null) return [];
    return List<Map<String, dynamic>>.from(user.assignments);
  }

  List<Map<String, String>> get assignedClasses {
    final classIds = teacherAssignments
        .map((a) => _extractClassId(a['classId']))
        .whereType<String>()
        .toSet();
    if (classIds.isEmpty) return [];
    return classIds.map((id) {
      final cls = schoolController.classes.firstWhereOrNull((c) => c.id == id);
      return {'id': id, 'name': cls?.name ?? 'Class'};
    }).toList();
  }

  List<Map<String, String?>> get sectionsForSelectedClass {
    if (selectedClassId == null) return [];
    final sections = <Map<String, String?>>[];
    bool hasAll = false;

    for (final a in teacherAssignments) {
      final classId = _extractClassId(a['classId']);
      if (classId != selectedClassId) continue;
      final sectionId = a['sectionId'];
      if (sectionId == null) {
        hasAll = true;
      } else {
        final sec = schoolController.sections.firstWhereOrNull((s) => s.id == sectionId);
        if (sec != null) sections.add({'id': sectionId, 'name': sec.name});
      }
    }

    if (hasAll || sections.isEmpty) {
      final available = schoolController.sections
          .where((s) => s.classId == selectedClassId)
          .toList();
      if (available.isNotEmpty) {
        sections.insert(0, {'id': null, 'name': 'All Sections'});
        if (hasAll) {
          for (final sec in available) {
            if (!sections.any((s) => s['id'] == sec.id))
              sections.add({'id': sec.id, 'name': sec.name});
          }
        }
      } else {
        sections.add({'id': null, 'name': 'All Sections'});
      }
    }
    return sections;
  }

  // ─── Init ──────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    if (_initialized) return;
    if (schoolController.selectedSchool.value == null) {
      final user = authController.user.value;
      if (user?.schoolId != null) {
        var school = schoolController.schools.firstWhereOrNull((s) => s.id == user?.schoolId);
        if (school == null) {
          await schoolController.getAllSchools();
          school = schoolController.schools.firstWhereOrNull((s) => s.id == user?.schoolId);
        }
        if (school == null) return;
        schoolController.selectedSchool.value = school;
      } else return;
    }
    _initialized = true;
    final schoolId = schoolController.selectedSchool.value!.id;
    await schoolController.getAllClasses(schoolId);
    await schoolController.getAllSections(schoolId: schoolId);
    if (assignedClasses.isNotEmpty && mounted)
      setState(() => selectedClassId = assignedClasses.first['id']);
    if (sectionsForSelectedClass.isNotEmpty && mounted) {
      setState(() => selectedSectionId = sectionsForSelectedClass.first['id']);
      _loadStudents();
    }
  }

  Future<void> _loadStudents() async {
    if (selectedClassId == null ||
        selectedSectionId == null ||
        schoolController.selectedSchool.value == null) return;
    await studentController.getStudentsByClassAndSection(
      schoolId: schoolController.selectedSchool.value!.id,
      classId: selectedClassId!,
      sectionId: selectedSectionId!,
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    if (teacherAssignments.isEmpty) {
      return _buildNoAssignmentsScaffold(isTablet);
    }

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      // ── AppBar ──────────────────────────────────────────────────────────
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xFF2563EB),
            // gradient: AppTheme.primaryGradient,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            title: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                const Text('My Classes', style: TextStyle(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Text('Manage your students', style: TextStyle(
                    color: Colors.white.withOpacity(0.9), fontSize: 12)),
              ]),
            ]),
          ),
        ),
      ),

      // ── Body: single CustomScrollView — everything scrolls together ──────
      body: SafeArea(
        child: Obx(() {
          final students = studentController.studentsByClassSection;
          final loading  = studentController.isLoading.value;

          return CustomScrollView(
            slivers: [

              // ── Filter card ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.getResponsivePadding(context)),
                  child: _buildFilterCard(context, isTablet),
                ),
              ),

              // ── Student list header ─────────────────────────────────────
              if (selectedClassId != null && selectedSectionId != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: _buildStudentListHeader(isTablet, students.length),
                  ),
                ),

              // ── Loading ─────────────────────────────────────────────────
              if (selectedClassId != null && selectedSectionId != null && loading)
                SliverFillRemaining(
                  child: Center(child: Column(
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
                      Text('Loading students...',
                          style: TextStyle(color: AppTheme.mutedText, fontSize: isTablet ? 16 : 14)),
                    ],
                  )),
                ),

              // ── Empty state ─────────────────────────────────────────────
              if (selectedClassId != null && selectedSectionId != null && !loading && students.isEmpty)
                SliverFillRemaining(
                  child: Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: isTablet ? 64 : 48, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('No students found',
                          style: TextStyle(color: AppTheme.mutedText, fontSize: isTablet ? 20 : 16)),
                    ],
                  )),
                ),

              // ── Student list ────────────────────────────────────────────
              if (selectedClassId != null && selectedSectionId != null && !loading && students.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildStudentTile(context, students[index], isTablet),
                      childCount: students.length,
                    ),
                  ),
                ),

              // ── Prompt to select class/section ──────────────────────────
              if (selectedClassId == null || selectedSectionId == null)
                SliverFillRemaining(
                  child: Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.touch_app_rounded, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text('Select a class and section above',
                          style: TextStyle(color: AppTheme.mutedText, fontSize: 14)),
                    ],
                  )),
                ),
            ],
          );
        }),
      ),
    );
  }

  // ─── Filter card ───────────────────────────────────────────────────────────
  Widget _buildFilterCard(BuildContext context, bool isTablet) {
    return Row(children: [
      // Class chip
      GestureDetector(
        onTap: () => _showClassSheet(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: selectedClassId != null
                ? const Color(0xFF2563EB).withOpacity(0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: selectedClassId != null
                  ? const Color(0xFF2563EB)
                  : Colors.grey.shade300,
              width: selectedClassId != null ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.class_rounded,
                size: 14,
                color: selectedClassId != null
                    ? const Color(0xFF2563EB)
                    : Colors.grey.shade500),
            const SizedBox(width: 6),
            Text(
              selectedClassId != null
                  ? (schoolController.classes
                  .firstWhereOrNull((c) => c.id == selectedClassId)
                  ?.name ??
                  'Class')
                  : 'Select Class',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selectedClassId != null
                    ? const Color(0xFF2563EB)
                    : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 14,
                color: selectedClassId != null
                    ? const Color(0xFF2563EB)
                    : Colors.grey.shade500),
          ]),
        ),
      ),
      const SizedBox(width: 8),
      // Section chip
      if (selectedClassId != null)
        GestureDetector(
          onTap: () => _showSectionSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: selectedSectionId != null
                  ? const Color(0xFF2563EB).withOpacity(0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: selectedSectionId != null
                    ? const Color(0xFF2563EB)
                    : Colors.grey.shade300,
                width: selectedSectionId != null ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.group_rounded,
                  size: 14,
                  color: selectedSectionId != null
                      ? const Color(0xFF2563EB)
                      : Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                selectedSectionId != null
                    ? (sectionsForSelectedClass
                    .firstWhereOrNull((s) => s['id'] == selectedSectionId)
                ?['name'] ??
                    'Section')
                    : 'Select Section',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selectedSectionId != null
                      ? const Color(0xFF2563EB)
                      : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 14,
                  color: selectedSectionId != null
                      ? const Color(0xFF2563EB)
                      : Colors.grey.shade500),
            ]),
          ),
        ),
    ]);
  }
  Widget _buildSectionInfoBanner(bool isTablet) {
    final selectedSection = sectionsForSelectedClass
        .firstWhereOrNull((s) => s['id'] == selectedSectionId);
    final sectionName = selectedSection?['name'] ?? 'selected section';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Icon(Icons.info_outline, color: AppTheme.primaryBlue, size: isTablet ? 18 : 16),
        const SizedBox(width: 8),
        Expanded(child: Text(
          selectedSectionId == null
              ? 'Showing students from all sections of the selected class'
              : 'Showing students from $sectionName',
          style: TextStyle(color: AppTheme.primaryBlue,
              fontSize: isTablet ? 14 : 12, fontWeight: FontWeight.w500),
        )),
      ]),
    );
  }

  // ─── Student list header ───────────────────────────────────────────────────
  Widget _buildStudentListHeader(bool isTablet, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        // gradient: AppTheme.successGradient,
        color: Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Row(children: [
        Icon(Icons.people_outline, color: Colors.white, size: isTablet ? 24 : 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Students ($count)', style: TextStyle(
            color: Colors.white, fontSize: isTablet ? 20 : 14, fontWeight: FontWeight.w600))),
        IconButton(
          onPressed: _loadStudents,
          icon: const Icon(Icons.refresh, color: Colors.white,size: 18,),
          tooltip: 'Refresh',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ]),
    );
  }

  // ─── Student tile ──────────────────────────────────────────────────────────
  Widget _buildStudentTile(BuildContext context, dynamic student, bool isTablet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: isTablet ? 50 : 35,
          height: isTablet ? 50 : 35,
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient, shape: BoxShape.circle),
          child: Center(child: Text(
            student.rollNumber ?? student.name?.substring(0, 1).toUpperCase() ?? '?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          )),
        ),
        title: Text(student.name ?? 'Student', style: TextStyle(
            fontSize: isTablet ? 16 : 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryText)),
        subtitle: Text('Roll: ${student.rollNumber ?? 'N/A'}',
            style: TextStyle(fontSize: isTablet ? 14 : 13, color: AppTheme.mutedText)),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.chevron_right, color: AppTheme.primaryBlue, size: isTablet ? 20 : 18),
        ),
        onTap: () => Get.to(() => StudentIndividualDetailView(
          student: student,
          schoolId: schoolController.selectedSchool.value!.id,
        )),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ─── Class selector ────────────────────────────────────────────────────────
  Widget _buildClassSelector(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return GetBuilder<SchoolController>(builder: (sc) {
      final classIds = teacherAssignments
          .map((a) => _extractClassId(a['classId']))
          .whereType<String>()
          .toSet();

      if (classIds.isEmpty) {
        return _infoBox(Icons.error_outline, 'No classes assigned',
            Colors.orange.shade600, Colors.orange.shade50);
      }

      if (sc.classes.isEmpty && !_initialized) {
        return _infoBox(null, 'Loading classes...', AppTheme.primaryBlue, Colors.grey.shade50,
            loading: true);
      }

      final items = classIds.map((id) {
        final cls = sc.classes.firstWhereOrNull((c) => c.id == id);
        return DropdownMenuItem<String>(
          value: id,
          child: Text(cls?.name ?? 'Class $id',
              style: TextStyle(fontSize: isTablet ? 15 : 14, fontWeight: FontWeight.w500)),
        );
      }).toList()
        ..sort((a, b) {
          final ac = sc.classes.firstWhereOrNull((c) => c.id == a.value);
          final bc = sc.classes.firstWhereOrNull((c) => c.id == b.value);
          if (ac != null && bc != null) {
            final ao = ac.order ?? 999;
            final bo = bc.order ?? 999;
            if (ao != bo) return ao.compareTo(bo);
            return _compareClassNames(ac.name, bc.name);
          }
          return 0;
        });

      return _styledDropdown<String>(
        label: 'Select Class',
        icon: Icons.class_,
        value: selectedClassId,
        items: items,
        isTablet: isTablet,
        onChanged: (value) {
          setState(() { selectedClassId = value; selectedSectionId = null; });
          if (sectionsForSelectedClass.isNotEmpty) {
            setState(() => selectedSectionId = sectionsForSelectedClass.first['id']);
            _loadStudents();
          }
        },
      );
    });
  }

  // ─── Section selector ──────────────────────────────────────────────────────
  Widget _buildSectionSelector(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return GetBuilder<SchoolController>(builder: (_) {
      final sections = sectionsForSelectedClass;
      return _styledDropdown<String?>(
        label: 'Select Section',
        icon: Icons.group,
        value: selectedSectionId,
        isTablet: isTablet,
        items: sections.map((sec) => DropdownMenuItem<String?>(
          value: sec['id'],
          child: Text(sec['name']!,
              style: TextStyle(fontSize: isTablet ? 15 : 14, fontWeight: FontWeight.w500)),
        )).toList(),
        onChanged: (value) {
          setState(() => selectedSectionId = value);
          _loadStudents();
        },
      );
    });
  }

  // ─── Shared small widgets ──────────────────────────────────────────────────

  Widget _styledDropdown<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    required bool isTablet,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonFormField<T>(
        isExpanded: true,
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppTheme.mutedText, fontSize: isTablet ? 14 : 12),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primaryBlue, size: isTablet ? 20 : 18),
          ),
        ),
        dropdownColor: Colors.white,
        menuMaxHeight: 300,
        borderRadius: BorderRadius.circular(12),
        items: items,
        onChanged: onChanged,
        style: TextStyle(
            color: AppTheme.primaryText,
            fontSize: isTablet ? 15 : 14,
            fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _infoBox(IconData? icon, String text, Color fg, Color bg,
      {bool loading = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(children: [
        if (loading)
          SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(fg)))
        else if (icon != null)
          Icon(icon, color: fg, size: 18),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(color: fg, fontSize: 13)),
      ]),
    );
  }

  // ─── No assignments scaffold ───────────────────────────────────────────────
  Widget _buildNoAssignmentsScaffold(bool isTablet) {
    final name = authController.user.value?.userName ?? 'this teacher';
    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            // gradient: const LinearGradient(
            //   colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
            //   begin: Alignment.topLeft, end: Alignment.bottomRight,
            // ),
            color: Color(0xFF2563EB),
            borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent, elevation: 0, centerTitle: false,
            title: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text('My Classes', style: TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      ),
      body: SafeArea(child: Center(child: Container(
        margin: EdgeInsets.all(AppTheme.getResponsivePadding(context)),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              // gradient: LinearGradient(
              //   colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
              //   begin: Alignment.topLeft, end: Alignment.bottomRight,
              // ),
              color: Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school_outlined, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 24),
          Text('No Classes Assigned', style: TextStyle(
              fontSize: isTablet ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryText)),
          const SizedBox(height: 12),
          Text('No classes were assigned to $name yet.\nPlease contact your administrator.',
            style: TextStyle(fontSize: isTablet ? 16 : 14,
                color: AppTheme.mutedText, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ]),
      ))),
    );
  }

  int _compareClassNames(String a, String b) {
    int priority(String name) {
      final n = name.toLowerCase().trim();
      if (n == 'lkg') return 1;
      if (n == 'ukg') return 2;
      final grade = RegExp(r'grade ([ivx]+|\d+)', caseSensitive: false).firstMatch(n);
      if (grade != null) {
        final g = grade.group(1)!;
        const roman = {'i':1,'ii':2,'iii':3,'iv':4,'v':5,'vi':6,'vii':7,'viii':8,'ix':9,'x':10};
        return 2 + (roman[g] ?? int.tryParse(g) ?? 999);
      }
      final cls = RegExp(r'class (\d+)', caseSensitive: false).firstMatch(n);
      if (cls != null) return 20 + (int.tryParse(cls.group(1)!) ?? 999);
      return 999;
    }
    return priority(a).compareTo(priority(b));
  }

  void _showClassSheet(BuildContext context) {
    final classIds = teacherAssignments
        .map((a) => _extractClassId(a['classId']))
        .whereType<String>()
        .toSet();

    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(children: [
              const Text('Select Class',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A2A3A))),
              const Spacer(),
              GestureDetector(
                onTap: () => Get.back(),
                child: Icon(Icons.close_rounded,
                    color: Colors.grey.shade400, size: 22),
              ),
            ]),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: ListView(
              shrinkWrap: true,
              children: classIds.map((id) {
                final cls = schoolController.classes
                    .firstWhereOrNull((c) => c.id == id);
                final name = cls?.name ?? 'Class';
                final isSelected = selectedClassId == id;
                return ListTile(
                  leading: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2563EB).withOpacity(0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.class_rounded,
                        size: 18,
                        color: isSelected
                            ? const Color(0xFF2563EB)
                            : Colors.grey.shade500),
                  ),
                  title: Text(name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF1A2A3A),
                      )),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF2563EB), size: 20)
                      : null,
                  onTap: () {
                    setState(() {
                      selectedClassId = id;
                      selectedSectionId = null;
                    });
                    Get.back();
                    // Auto-select first section
                    if (sectionsForSelectedClass.isNotEmpty) {
                      setState(() =>
                      selectedSectionId =
                      sectionsForSelectedClass.first['id']);
                      _loadStudents();
                    }
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
        ]),
      ),
      isScrollControlled: true,
    );
  }

  void _showSectionSheet(BuildContext context) {
    final sections = sectionsForSelectedClass;

    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(children: [
              const Text('Select Section',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A2A3A))),
              const Spacer(),
              GestureDetector(
                onTap: () => Get.back(),
                child: Icon(Icons.close_rounded,
                    color: Colors.grey.shade400, size: 22),
              ),
            ]),
          ),
          const Divider(height: 1),
          if (sections.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('No sections available',
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 13)),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView(
                shrinkWrap: true,
                children: sections.map((sec) {
                  final isSelected = selectedSectionId == sec['id'];
                  return ListTile(
                    leading: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF2563EB).withOpacity(0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.group_rounded,
                          size: 18,
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : Colors.grey.shade500),
                    ),
                    title: Text(sec['name']!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF1A2A3A),
                        )),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF2563EB), size: 20)
                        : null,
                    onTap: () {
                      setState(() => selectedSectionId = sec['id']);
                      Get.back();
                      _loadStudents();
                    },
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 20),
        ]),
      ),
      isScrollControlled: true,
    );
  }
}