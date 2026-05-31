import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/teacher_controller.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/controllers/user_management_controller.dart';
import 'package:school_app/controllers/auth_controller.dart';

// ── reuse the same _DS design system constants ──────────────────
class _DS {
  static const primary      = Color(0xFF1E3A5F);
  static const accent       = Color(0xFF3B82F6);
  static const accentSoft   = Color(0xFFEFF6FF);
  static const accentMid    = Color(0xFFBFDBFE);
  static const bg           = Color(0xFFF0F4F8);
  static const surface      = Color(0xFFFFFFFF);
  static const surfaceAlt   = Color(0xFFF8FAFC);
  static const textPrimary  = Color(0xFF0F172A);
  static const textSecondary= Color(0xFF475569);
  static const textMuted    = Color(0xFF94A3B8);
  static const success      = Color(0xFF059669);
  static const successSoft  = Color(0xFFD1FAE5);
  static const border       = Color(0xFFE2E8F0);
  static const radius       = 14.0;
  static const radiusSm     = 8.0;
  static const shadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 4)),
  ];
}

class TeacherAssignmentView extends StatefulWidget {
  const TeacherAssignmentView({super.key});

  @override
  State<TeacherAssignmentView> createState() => _TeacherAssignmentViewState();
}

class _TeacherAssignmentViewState extends State<TeacherAssignmentView> {
  final TeacherController teacherController = Get.put(TeacherController());
  final SchoolController schoolController = Get.find<SchoolController>();
  final UserManagementController userController =
  Get.find<UserManagementController>();
  final AuthController authController = Get.find<AuthController>();

  String? selectedTeacherId;
  String? selectedTeacherName;

  final RxList<Map<String, dynamic>> selectedAssignments =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> originalAssignments =
      <Map<String, dynamic>>[].obs;

  List<Map<String, dynamic>> classSectionData = [];
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    if (_initialized ||
        schoolController.selectedSchool.value == null) return;
    _initialized = true;
    final schoolId = schoolController.selectedSchool.value!.id;
    await userController.loadUsers(schoolId: schoolId, role: 'teacher');
    if (!mounted) return;
    await _loadClassSectionAssignments();
  }

  Future<void> _loadClassSectionAssignments() async {
    final schoolId = schoolController.selectedSchool.value!.id;
    final response =
    await teacherController.getAllClassSectionAssignments(schoolId);
    if (!mounted) return;
    setState(() => classSectionData = response);
  }

  void _prefillFromTeacherAssignments(List assignments) {
    originalAssignments.clear();
    selectedAssignments.clear();
    for (final a in assignments) {
      final classObj = a['classId'];
      final sectionObj = a['sectionId'];
      final String classId =
      classObj is Map ? classObj['_id'] : classObj?.toString() ?? '';
      final String? sectionId = sectionObj == null
          ? null
          : (sectionObj is Map
          ? sectionObj['_id']
          : sectionObj?.toString());
      final assignment = {'classId': classId, 'sectionId': sectionId};
      originalAssignments.add(assignment);
      selectedAssignments.add(assignment);
    }
  }

  // ── card wrapper ────────────────────────────────────────────────
  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(_DS.radius),
        border: Border.all(color: _DS.border),
        boxShadow: _DS.shadow,
      ),
      child: child,
    );
  }

  // ── teacher bottom sheet ────────────────────────────────────────
  void _showTeacherSheet() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: _DS.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: _DS.border,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(children: [
              const Text('Select Teacher',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _DS.textPrimary)),
              const Spacer(),
              GestureDetector(
                onTap: () => Get.back(),
                child: const Icon(Icons.close_rounded,
                    color: _DS.textMuted, size: 22),
              ),
            ]),
          ),
          const Divider(height: 1, color: _DS.border),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: GetBuilder<UserManagementController>(
              builder: (ctrl) {
                if (ctrl.users.isEmpty)
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text('No teachers found',
                          style: TextStyle(
                              color: _DS.textMuted, fontSize: 14)),
                    ),
                  );
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: ctrl.users.length,
                  itemBuilder: (_, i) {
                    final teacher = ctrl.users[i];
                    final tid = teacher['_id'] as String?;
                    final name =
                        teacher['userName'] as String? ?? 'Unknown';
                    final isSelected = selectedTeacherId == tid;
                    return ListTile(
                      leading: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _DS.accentSoft
                              : _DS.surfaceAlt,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.person_rounded,
                            size: 18,
                            color: isSelected
                                ? _DS.accent
                                : _DS.textMuted),
                      ),
                      title: Text(name,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 14,
                            color: isSelected
                                ? _DS.accent
                                : _DS.textPrimary,
                          )),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded,
                          color: _DS.accent, size: 20)
                          : null,
                      onTap: () async {
                        Get.back();
                        selectedAssignments.clear();
                        originalAssignments.clear();
                        setState(() {
                          selectedTeacherId = tid;
                          selectedTeacherName = name;
                        });
                        if (tid == null) return;
                        final t =
                        await userController.getTeacherById(tid);
                        if (!mounted) return;
                        if (t != null && t['assignments'] != null) {
                          _prefillFromTeacherAssignments(
                              t['assignments']);
                          if (mounted) setState(() {});
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ]),
      ),
      isScrollControlled: true,
    );
  }

  // ── build ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DS.bg,
      body: Column(children: [
        // ── Teacher chip row ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(children: [
            // Chip
            GestureDetector(
              onTap: _showTeacherSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: selectedTeacherId != null
                      ? _DS.accentSoft
                      : _DS.surface,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: selectedTeacherId != null
                        ? _DS.accent
                        : _DS.border,
                    width: selectedTeacherId != null ? 1.5 : 1,
                  ),
                  boxShadow: _DS.shadow,
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.person_rounded,
                      size: 15,
                      color: selectedTeacherId != null
                          ? _DS.accent
                          : _DS.textMuted),
                  const SizedBox(width: 7),
                  Text(
                    selectedTeacherName ?? 'Select Teacher',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selectedTeacherId != null
                          ? _DS.accent
                          : _DS.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      size: 15,
                      color: selectedTeacherId != null
                          ? _DS.accent
                          : _DS.textMuted),
                ]),
              ),
            ),
            const Spacer(),
            // Assignment count badge
            Obx(() => selectedAssignments.isNotEmpty
                ? Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _DS.successSoft,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                    color: _DS.success.withOpacity(0.3)),
              ),
              child: Text(
                '${selectedAssignments.length} assigned',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _DS.success,
                ),
              ),
            )
                : const SizedBox.shrink()),
          ]),
        ),

        // ── Current assignments chips ─────────────────────────────
        Obx(() {
          if (selectedAssignments.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: _card(
              padding: const EdgeInsets.all(12),
              child: Wrap(spacing: 8, runSpacing: 6,
                children: selectedAssignments.map((a) {
                  final className = _getClassName(a['classId']);
                  final sectionName = a['sectionId'] != null
                      ? _getSectionName(a['sectionId'])
                      : 'All';
                  final isAll = a['sectionId'] == null;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isAll
                          ? _DS.accentSoft
                          : _DS.successSoft,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isAll
                            ? _DS.accentMid
                            : _DS.success.withOpacity(0.3),
                      ),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAll ? Icons.school_rounded : Icons.layers_rounded,
                            size: 11,
                            color: isAll ? _DS.accent : _DS.success,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$className · $sectionName',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isAll ? _DS.accent : _DS.success,
                            ),
                          ),
                        ]),
                  );
                }).toList(),
              ),
            ),
          );
        }),

        // ── Class / section list ──────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: _card(
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_DS.radius),
                child: _buildClassSectionList(),
              ),
            ),
          ),
        ),

        // ── Save button ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: _buildSaveButton(),
        ),
      ]),
    );
  }

  // ── class section list ──────────────────────────────────────────
  Widget _buildClassSectionList() {
    if (classSectionData.isEmpty)
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                    color: _DS.accentSoft, shape: BoxShape.circle),
                child: const Icon(Icons.class_outlined,
                    size: 28, color: _DS.accent),
              ),
              const SizedBox(height: 16),
              const Text('No class data available',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _DS.textPrimary)),
              const SizedBox(height: 4),
              const Text('Classes will appear here once loaded',
                  style: TextStyle(fontSize: 12, color: _DS.textMuted)),
            ]),
      );

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: classSectionData.length,
      itemBuilder: (context, index) {
        final cls = classSectionData[index];
        final classId = cls['_id'] as String;
        final className = cls['name'] ?? 'Unknown Class';
        final sections = cls['sections'] as List? ?? [];

        final hasAllAssigned = selectedAssignments
            .any((a) => a['classId'] == classId && a['sectionId'] == null);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: hasAllAssigned ? _DS.accentSoft : _DS.surfaceAlt,
            borderRadius: BorderRadius.circular(_DS.radius),
            border: Border.all(
              color: hasAllAssigned ? _DS.accentMid : _DS.border,
              width: hasAllAssigned ? 1.5 : 1,
            ),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              splashColor: Colors.transparent,
            ),
            child: ExpansionTile(
              tilePadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              collapsedBackgroundColor: Colors.transparent,
              backgroundColor: Colors.transparent,
              title: Row(children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: hasAllAssigned
                        ? _DS.accent.withOpacity(0.15)
                        : _DS.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: hasAllAssigned ? _DS.accentMid : _DS.border,
                    ),
                  ),
                  child: Icon(Icons.class_rounded,
                      size: 16,
                      color: hasAllAssigned ? _DS.accent : _DS.textMuted),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Class $className',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: hasAllAssigned
                                ? _DS.accent
                                : _DS.textPrimary,
                          )),
                      if (hasAllAssigned)
                        const Text('All sections assigned',
                            style: TextStyle(
                                fontSize: 10,
                                color: _DS.accent,
                                fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ]),
              children: [
                const Divider(height: 1, color: _DS.border),
                const SizedBox(height: 6),
                // All sections row
                _assignmentRow(
                  label: 'All Sections',
                  subtitle: 'Assign teacher to entire class',
                  icon: Icons.all_inclusive_rounded,
                  checked: hasAllAssigned,
                  enabled: selectedTeacherId != null,
                  onChanged: (checked) {
                    if (checked == true) {
                      selectedAssignments.removeWhere(
                              (a) => a['classId'] == classId);
                      selectedAssignments
                          .add({'classId': classId, 'sectionId': null});
                    } else {
                      selectedAssignments.removeWhere(
                              (a) => a['classId'] == classId);
                    }
                    setState(() {});
                  },
                ),
                if (sections.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Divider(height: 1, color: _DS.border),
                  ),
                  ...sections.map<Widget>((section) {
                    final sectionId = section['_id'] as String;
                    final sectionName =
                        section['name'] ?? 'Unknown Section';
                    final checked = selectedAssignments.any((a) =>
                    a['classId'] == classId &&
                        a['sectionId'] == sectionId);
                    return _assignmentRow(
                      label: 'Section $sectionName',
                      icon: Icons.layers_rounded,
                      checked: checked,
                      enabled:
                      selectedTeacherId != null && !hasAllAssigned,
                      onChanged: (_) =>
                          _toggleAssignment(classId, sectionId),
                    );
                  }),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _assignmentRow({
    required String label,
    String? subtitle,
    required IconData icon,
    required bool checked,
    required bool enabled,
    required void Function(bool?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        onTap: enabled ? () => onChanged(!checked) : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: checked ? _DS.successSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: checked
                ? Border.all(color: _DS.success.withOpacity(0.3))
                : null,
          ),
          child: Row(children: [
            Icon(icon,
                size: 15,
                color: checked
                    ? _DS.success
                    : enabled
                    ? _DS.textMuted
                    : _DS.border),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: checked
                              ? _DS.success
                              : enabled
                              ? _DS.textPrimary
                              : _DS.textMuted,
                        )),
                    if (subtitle != null)
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 10, color: _DS.textMuted)),
                  ]),
            ),
            if (enabled)
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: checked ? _DS.success : _DS.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: checked ? _DS.success : _DS.border,
                    width: 1.5,
                  ),
                ),
                child: checked
                    ? const Icon(Icons.check_rounded,
                    size: 13, color: Colors.white)
                    : null,
              ),
          ]),
        ),
      ),
    );
  }

  // ── save button ─────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return Obx(() {
      final loading = teacherController.isLoading.value;
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: selectedTeacherId == null || loading
              ? null
              : _saveAssignments,
          style: ElevatedButton.styleFrom(
            backgroundColor: _DS.accent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: _DS.border,
            padding: const EdgeInsets.symmetric(vertical: 15),
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_DS.radius)),
          ),
          child: loading
              ? const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
              : Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.save_rounded, size: 18),
                const SizedBox(width: 8),
                Text(
                  selectedTeacherId == null
                      ? 'Select a teacher first'
                      : 'Save Assignments',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ]),
        ),
      );
    });
  }

  // ── unchanged API methods ───────────────────────────────────────
  Future<void> _saveAssignments() async {
    final changesToSend = <Map<String, dynamic>>[];
    for (final original in originalAssignments) {
      final stillSelected = selectedAssignments.any((s) =>
      s['classId'] == original['classId'] &&
          s['sectionId'] == original['sectionId']);
      if (!stillSelected) changesToSend.add(original);
    }
    for (final selected in selectedAssignments) {
      final wasOriginal = originalAssignments.any((o) =>
      o['classId'] == selected['classId'] &&
          o['sectionId'] == selected['sectionId']);
      if (!wasOriginal) changesToSend.add(selected);
    }
    if (changesToSend.isEmpty) {
      Get.snackbar('Info', 'No changes to save',
          backgroundColor: _DS.accent, colorText: Colors.white);
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
      final updated =
      await userController.getTeacherById(selectedTeacherId!);
      if (!mounted) return;
      if (updated != null) {
        selectedAssignments.clear();
        originalAssignments.clear();
        if (updated['assignments'] != null)
          _prefillFromTeacherAssignments(updated['assignments']);
        if (mounted) setState(() {});
      }
    });
  }

  void _toggleAssignment(String classId, String sectionId) {
    final index = selectedAssignments.indexWhere(
            (a) => a['classId'] == classId && a['sectionId'] == sectionId);
    if (index >= 0)
      selectedAssignments.removeAt(index);
    else
      selectedAssignments.add({'classId': classId, 'sectionId': sectionId});
  }

  String _getClassName(String classId) {
    final cls =
    classSectionData.firstWhereOrNull((c) => c['_id'] == classId);
    return cls?['name'] ?? 'Unknown';
  }

  String _getSectionName(String sectionId) {
    for (final item in classSectionData) {
      for (final sec in (item['sections'] as List? ?? [])) {
        if (sec['_id'] == sectionId) return sec['name'] ?? 'Unknown';
      }
    }
    return 'Unknown';
  }
}