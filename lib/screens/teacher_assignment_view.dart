import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/teacher_controller.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/controllers/user_management_controller.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/widgets/responsive_wrapper.dart';

class TeacherAssignmentView extends StatefulWidget {
  const TeacherAssignmentView({super.key});

  @override
  State<TeacherAssignmentView> createState() => _TeacherAssignmentViewState();
}

class _TeacherAssignmentViewState extends State<TeacherAssignmentView> {
  final TeacherController teacherController = Get.put(TeacherController());
  final SchoolController schoolController = Get.find<SchoolController>();
  final UserManagementController userController = Get.find<UserManagementController>();
  final AuthController authController = Get.find<AuthController>();

  String? selectedTeacherId;

  /// Current UI selections (what should be assigned)
  final RxList<Map<String, dynamic>> selectedAssignments = <Map<String, dynamic>>[].obs;

  /// Original assignments when teacher was loaded
  final RxList<Map<String, dynamic>> originalAssignments = <Map<String, dynamic>>[].obs;

  /// Master data
  List<Map<String, dynamic>> classSectionData = [];

  bool _initialized = false;

  // ================= INIT =================

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    if (_initialized || schoolController.selectedSchool.value == null) {
      return;
    }

    _initialized = true;
    final schoolId = schoolController.selectedSchool.value!.id;

    await userController.loadUsers(schoolId: schoolId, role: 'teacher');

    if (!mounted) return;
    await _loadClassSectionAssignments();
  }

  // ================= API =================

  Future<void> _loadClassSectionAssignments() async {
    final schoolId = schoolController.selectedSchool.value!.id;

    final response = await teacherController.getAllClassSectionAssignments(schoolId);

    if (!mounted) return;
    setState(() {
      classSectionData = response;
    });
  }

  /// Prefill from teacher assignments API
  void _prefillFromTeacherAssignments(List assignments) {
    originalAssignments.clear();
    selectedAssignments.clear();

    for (final a in assignments) {
      final classObj = a['classId'];
      final sectionObj = a['sectionId'];

      final String classId = classObj is Map ? classObj['_id'] : classObj?.toString() ?? '';
      final String? sectionId = sectionObj == null
          ? null
          : (sectionObj is Map ? sectionObj['_id'] : sectionObj?.toString());

      final assignment = {'classId': classId, 'sectionId': sectionId};

      originalAssignments.add(assignment);
      selectedAssignments.add(assignment);
    }
  }

  // ================= PROFESSIONAL APPBAR =================

  PreferredSizeWidget _buildProfessionalAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.dividerColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.primaryText, size: 20),
            onPressed: () => Get.back(),
          ),
          title: Row(
            children: [
              _buildSchoolLogo(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Teacher Assignments',
                      style: const TextStyle(
                        color: AppTheme.primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Text(
                      'Manage teacher assignments',
                      style: TextStyle(
                        color: AppTheme.mutedText,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: GestureDetector(
                onTap: _showFullScreenProfileImage,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.5)),
                  ),
                  child: Center(
                    child: Obx(() {
                      final userName = authController.user.value?.userName ?? 'U';
                      return Text(
                        userName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolLogo() {
    try {
      final school = authController.userSchool.value;
      if (school != null && school['logo'] != null && school['logo']['url'] != null) {
        return GestureDetector(
          onTap: () => _showFullScreenSchoolLogo(school['logo']['url']),
          child: Image.network(
            school['logo']['url'],
            width: 32,
            height: 32,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.school, color: Colors.white, size: 32);
            },
          ),
        );
      }
    } catch (e) {
      // Handle error silently
    }
    return const Icon(Icons.school, color: AppTheme.primaryText, size: 32);
  }

  void _showFullScreenProfileImage() {
    final userName = authController.user.value?.userName ?? 'U';
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    userName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 120,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 40,
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.close, color: Colors.black, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenSchoolLogo(String logoUrl) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.9),
                child: Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.network(
                      logoUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        Get.back();
                        Get.snackbar(
                          'Error',
                          'Failed to load logo',
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 50,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Compact card wrapper for consistent styling
  Widget _compactCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Compact Header
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.blue[700]!, Colors.blue[500]!]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.assignment_ind, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Teacher Assignments',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            // Teacher Selection Card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _compactCard(child: _buildTeacherDropdown()),
            ),

            // Current Assignments Card (compact, only shown when teacher selected)
            if (selectedTeacherId != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: _compactCard(child: _buildCurrentAssignments()),
              ),

            // Class/Section List
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _compactCard(child: _buildClassSectionList()),
              ),
            ),

            // Save Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildSaveButton(),
            ),
          ],
        ),
      ),
    );
  }

  // ================= TEACHER DROPDOWN =================

  Widget _buildTeacherDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[700]!.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person, color: Colors.blue, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Select Teacher',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.primaryText),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GetBuilder<UserManagementController>(
          builder: (controller) {
            return DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: InputDecoration(
                hintText: 'Choose a teacher',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[700]!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.person, color: Colors.blue[700], size: 18),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              dropdownColor: Colors.white,
              menuMaxHeight: 300,
              borderRadius: BorderRadius.circular(12),
              icon: Container(
                margin: const EdgeInsets.only(right: 12),
                child: Icon(Icons.keyboard_arrow_down, color: Colors.blue[700]),
              ),
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              value: selectedTeacherId,
              selectedItemBuilder: (context) {
                return controller.users.map((teacher) {
                  return Text(
                    teacher['userName'] ?? 'Unknown',
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  );
                }).toList();
              },
              items: controller.users.map<DropdownMenuItem<String>>((teacher) {
                return DropdownMenuItem<String>(
                  value: teacher['_id'],
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blue[700]!.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(Icons.person, color: Colors.blue[700], size: 16),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            teacher['userName'] ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) async {
                if (value == null) return;

                selectedAssignments.clear();
                originalAssignments.clear();

                if (!mounted) return;
                setState(() => selectedTeacherId = value);

                final teacher = await userController.getTeacherById(value);

                if (!mounted) return;
                if (teacher != null && teacher['assignments'] != null) {
                  _prefillFromTeacherAssignments(teacher['assignments']);
                  if (mounted) setState(() {});
                }
              },
            );
          },
        ),
      ],
    );
  }

  // ================= CURRENT ASSIGNMENTS =================

  Widget _buildCurrentAssignments() {
    return Obx(() {
      if (selectedAssignments.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'No assignments yet — select classes below.',
            style: TextStyle(color: AppTheme.mutedText, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 15),
              const SizedBox(width: 6),
              Text(
                'Assigned (${selectedAssignments.length})',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryText),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: selectedAssignments.map((a) {
              final className = _getClassName(a['classId']);
              final sectionName = a['sectionId'] != null ? _getSectionName(a['sectionId']) : 'All';
              final isAll = a['sectionId'] == null;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isAll ? Colors.blue[700]!.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isAll ? Colors.blue[700]!.withOpacity(0.3) : Colors.green.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '$className · $sectionName',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isAll ? Colors.blue[700] : Colors.green[700],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );
    });
  }

  // ================= CLASS / SECTION LIST =================

  Widget _buildClassSectionList() {
    if (classSectionData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.class_, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No class data available',
                style: TextStyle(color: AppTheme.mutedText, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: classSectionData.length,
      itemBuilder: (context, index) {
        final cls = classSectionData[index];
        final classId = cls['_id'];
        final className = cls['name'] ?? 'Unknown Class';
        final sections = cls['sections'] ?? [];

        final hasAllAssigned = selectedAssignments.any(
          (a) => a['classId'] == classId && a['sectionId'] == null,
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            childrenPadding: const EdgeInsets.only(left: 14, right: 14, bottom: 10),
            collapsedBackgroundColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            shape: Border(),
            collapsedShape: Border(),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[700]!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.class_, color: Colors.blue[700], size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Class $className',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            subtitle: hasAllAssigned
                ? const Text('All sections assigned', style: TextStyle(color: Colors.green, fontSize: 11))
                : null,
            children: [
              // "All Sections" checkbox
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('All Sections', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                subtitle: const Text('Assign to entire class', style: TextStyle(fontSize: 11, color: AppTheme.mutedText)),
                value: hasAllAssigned,
                activeColor: Colors.blue[700],
                onChanged: selectedTeacherId == null
                    ? null
                    : (checked) {
                        if (checked == true) {
                          selectedAssignments.removeWhere((a) => a['classId'] == classId);
                          selectedAssignments.add({'classId': classId, 'sectionId': null});
                        } else {
                          selectedAssignments.removeWhere((a) => a['classId'] == classId);
                        }
                        setState(() {});
                      },
              ),
              const Divider(height: 1),
              if (sections.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('No sections available', style: TextStyle(color: AppTheme.mutedText, fontSize: 12)),
                )
              else
                ...sections.map<Widget>((section) {
                  final sectionId = section['_id'];
                  final sectionName = section['name'] ?? 'Unknown Section';
                  final checked = selectedAssignments.any((a) =>
                      a['classId'] == classId && a['sectionId'] == sectionId);

                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Section $sectionName', style: const TextStyle(fontSize: 13)),
                    value: checked,
                    activeColor: Colors.blue[700],
                    subtitle: hasAllAssigned
                        ? const Text('Uncheck "All Sections" above to select individual',
                            style: TextStyle(fontSize: 10, color: AppTheme.mutedText))
                        : null,
                    onChanged: selectedTeacherId == null
                        ? null
                        : (hasAllAssigned && !checked)
                            ? (_) {
                                selectedAssignments.removeWhere((a) => a['classId'] == classId);
                                _toggleAssignment(classId, sectionId);
                                setState(() {});
                              }
                            : hasAllAssigned && checked
                                ? null
                                : (_) => _toggleAssignment(classId, sectionId),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  // ================= SAVE =================

  Widget _buildSaveButton() {
    return Obx(() {
      final loading = teacherController.isLoading.value;

      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: selectedTeacherId == null || loading ? null : _saveAssignments,
          icon: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save, size: 20),
          label: Text(loading ? 'Saving...' : 'Save Assignments'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
          ),
        ),
      );
    });
  }

  Future<void> _saveAssignments() async {
    final changesToSend = <Map<String, dynamic>>[];

    // Find assignments to REMOVE
    for (final original in originalAssignments) {
      final stillSelected = selectedAssignments.any((selected) =>
          selected['classId'] == original['classId'] && selected['sectionId'] == original['sectionId']);
      if (!stillSelected) changesToSend.add(original);
    }

    // Find assignments to ADD
    for (final selected in selectedAssignments) {
      final wasOriginallyAssigned = originalAssignments.any((original) =>
          original['classId'] == selected['classId'] && original['sectionId'] == selected['sectionId']);
      if (!wasOriginallyAssigned) changesToSend.add(selected);
    }

    if (changesToSend.isEmpty) {
      Get.snackbar('Info', 'No changes to save', backgroundColor: Colors.blue[400], colorText: Colors.white);
      return;
    }

    teacherController.manageTeacherAssignments(
      teacherId: selectedTeacherId!,
      updates: changesToSend,
      schoolId: schoolController.selectedSchool.value!.id,
    );

    originalAssignments.clear();
    originalAssignments.addAll(selectedAssignments);

    Future.delayed(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      if (selectedTeacherId != null) {
        final updatedTeacher = await userController.getTeacherById(selectedTeacherId!);
        if (!mounted) return;
        if (updatedTeacher != null) {
          selectedAssignments.clear();
          originalAssignments.clear();
          if (updatedTeacher['assignments'] != null) {
            _prefillFromTeacherAssignments(updatedTeacher['assignments']);
          }
          if (mounted) setState(() {});
        }
      }
    });
  }

  void _toggleAssignment(String classId, String sectionId) {
    final assignment = {'classId': classId, 'sectionId': sectionId};
    final index = selectedAssignments.indexWhere((a) =>
        a['classId'] == classId && a['sectionId'] == sectionId);

    if (index >= 0) {
      selectedAssignments.removeAt(index);
    } else {
      selectedAssignments.add(assignment);
    }
  }

  String _getClassName(String classId) {
    final cls = classSectionData.firstWhereOrNull((c) => c['_id'] == classId);
    return cls?['name'] ?? 'Unknown Class';
  }

  String _getSectionName(String sectionId) {
    for (final item in classSectionData) {
      final List sections = item['sections'] ?? [];
      for (final sec in sections) {
        if (sec['_id'] == sectionId) return sec['name'] ?? 'Unknown Section';
      }
    }
    return 'Unknown Section';
  }
}