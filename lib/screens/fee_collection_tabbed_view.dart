import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/screens/fee_structure_view.dart';
import 'package:school_app/routes/app_routes.dart';
import 'dart:io';
import 'package:school_app/controllers/student_record_controller.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/controllers/accounting_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/screens/set_fee_configuration_page.dart';
import 'package:school_app/widgets/api_rbac_wrapper.dart';
import 'package:school_app/core/rbac/api_rbac.dart';
import 'package:school_app/widgets/student_record_integration.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/controllers/fee_structure_controller.dart';
import 'package:school_app/models/school_models.dart';
import 'package:school_app/constants/api_constants.dart';
import 'package:school_app/services/api_service.dart';

class _DS {
  // Primary palette — deep navy + sky accent
  static const primary        = Color(0xFF1E3A5F);
  static const primaryLight   = Color(0xFF2D5F9E);
  static const accent         =Color(0xFF2563EB);
  static const accentSoft     = Color(0xFFEFF6FF);
  static const accentMid      = Color(0xFFBFDBFE);

  // Surfaces
  static const bg             = Color(0xFFF0F4F8);
  static const surface        = Color(0xFFFFFFFF);
  static const surfaceAlt     = Color(0xFFF8FAFC);

  // Text
  static const textPrimary    = Color(0xFF0F172A);
  static const textSecondary  = Color(0xFF475569);
  static const textMuted      = Color(0xFF94A3B8);

  // Status
  static const success        = Color(0xFF059669);
  static const successSoft    = Color(0xFFD1FAE5);
  static const warning        = Color(0xFFD97706);
  static const warningSoft    = Color(0xFFFEF3C7);
  static const danger         = Color(0xFFDC2626);
  static const dangerSoft     = Color(0xFFFEE2E2);

  // Borders & shadows
  static const border         = Color(0xFFE2E8F0);
  static const borderFocus    = Color(0xFF93C5FD);

  static const shadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const shadowMd = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 8)),
  ];

  static const radius     = 14.0;
  static const radiusSm   = 8.0;
  static const radiusLg   = 20.0;
  static const radiusXl   = 28.0;
}

class FeeCollectionSchoolController extends GetxController {
  final selectedSchool = Rxn<School>();

  void setSchool(School school) {
    selectedSchool.value = school;
  }
}

class FeeCollectionTabbedView extends StatefulWidget {
  FeeCollectionTabbedView({super.key});

  @override
  State<FeeCollectionTabbedView> createState() => _FeeCollectionTabbedViewState();

}

class _FeeCollectionTabbedViewState extends State<FeeCollectionTabbedView> {
  final AuthController _authController = Get.find();
  final SchoolController schoolController = Get.find();
  Worker? _schoolWatcher;
  late FeeCollectionSchoolController feeSchoolController;

  @override
  void initState() {
    super.initState();

    // Register shared controller first
    feeSchoolController = Get.put(FeeCollectionSchoolController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userRole = _authController.user.value?.role?.toLowerCase() ?? '';

      try {
        final schoolCtrl = Get.find<SchoolController>();

        // For correspondent: sync sidebar school selection into feeSchoolController
        if (userRole == 'correspondent') {
          final current = schoolCtrl.selectedSchool.value;
          if (current != null) {
            feeSchoolController.setSchool(current);
          }
          _schoolWatcher = ever(schoolCtrl.selectedSchool, (school) {
            if (school != null) feeSchoolController.setSchool(school);
          });
        } else {
          // Non-correspondent: auto-set school from AuthController
          final schoolId = _authController.user.value?.schoolId;
          if (schoolId != null && schoolId.isNotEmpty) {
            final existing = schoolCtrl.schools
                .firstWhereOrNull((s) => s.id == schoolId);
            if (existing != null) {
              feeSchoolController.setSchool(existing);
            } else {
              schoolCtrl.getAllSchools().then((_) {
                final found = schoolCtrl.schools
                    .firstWhereOrNull((s) => s.id == schoolId);
                if (found != null) feeSchoolController.setSchool(found);
              });
            }
          }
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _schoolWatcher?.dispose();
    Get.delete<FeeCollectionSchoolController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F5FF),
        body: SafeArea(
          child: Column(
            children: [
              _buildModernHeader(context, isTablet),
              _buildModernTabBar(context),
              Expanded(
                child: TabBarView(
                  children: [
                    _FeeCollectionTab(),
                    _FeeStructureViewTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: _DS.accentSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.payments_rounded,
              color: _DS.accent, size: 18),
        ),
        const SizedBox(width: 10),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fee Management',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _DS.textPrimary)),
            Text('Collect fees and manage records',
                style: TextStyle(fontSize: 11, color: _DS.textMuted)),
          ],
        ),
      ]),
    );
  }

  Widget _buildModernTabBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: _DS.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _DS.border),
        ),
        padding: const EdgeInsets.all(4),
        child: TabBar(
          indicator: BoxDecoration(
            color: _DS.surface,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: _DS.border),
            boxShadow: _DS.shadow,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: _DS.accent,
          unselectedLabelColor: _DS.textMuted,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500, fontSize: 12),
          tabs: const [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payment_rounded, size: 15),
                  SizedBox(width: 5),
                  Text('Collect Fee'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_rounded, size: 15),
                  SizedBox(width: 5),
                  Text('Fee Structure'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeeCollectionTab extends StatefulWidget {

  // _FeeCollectionTab() {
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     schoolController.getAllSchools();
  //     // Note: Students will be loaded when school is selected
  //     final sidebarSchool = _feeSchoolCtrl.selectedSchool.value;
  //     if (sidebarSchool != null) {
  //       _loadStudentsForSchool(sidebarSchool.id);
  //     }
  //   });
  // }

  @override
  State<_FeeCollectionTab> createState() => _FeeCollectionTabState();
}

class _FeeCollectionTabState extends State<_FeeCollectionTab> {
  final controller = Get.put(AccountingController());
  final schoolController = Get.put(SchoolController());
  final _amountController = TextEditingController();
  final _chequeNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _chequeDateController = TextEditingController();
  final _upiReferenceController = TextEditingController();
  final _remarksController = TextEditingController();
  final _referenceNumberController = TextEditingController();
  final _busPointController = TextEditingController();
  final isBusApplicable = false.obs;
  final manualDueAllocation = false.obs;
  final _formKey = GlobalKey<FormState>();
  final AuthController _authController = Get.find();
  final _studentSearchController = TextEditingController();
  final filteredStudents = <Map<String, dynamic>>[].obs;
  final showPaymentDetails = false.obs;
  final showReceipts = false.obs;
  final isStudentSelectorCollapsed = false.obs;
  final selectedStudentType = 'old'.obs;

  final selectedFilterClass = Rxn<SchoolClass>();
  final selectedFilterSection = Rxn<Section>();

  Worker? _schoolWatcher;

  FeeCollectionSchoolController get _feeSchoolCtrl =>
      Get.find<FeeCollectionSchoolController>();

  String get _currentSchoolId =>
      _feeSchoolCtrl.selectedSchool.value?.id ??
          _authController.user.value?.schoolId ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      schoolController.getAllSchools();
      final current = _feeSchoolCtrl.selectedSchool.value;
      if (current != null) {
        _onSchoolReady(current.id);
      } else {
        final userRole = _authController.user.value?.role?.toLowerCase() ?? '';
        if (userRole != 'correspondent') {
          final userSchoolId = _authController.user.value?.schoolId;
          if (userSchoolId != null) _onSchoolReady(userSchoolId);
        }
      }
      _schoolWatcher = ever(_feeSchoolCtrl.selectedSchool, (school) {
        if (school != null) _resetAndLoad(school.id);
      });
    });
  }

  void _onSchoolReady(String schoolId) {
    // Load classes for filter chips
    schoolController.getAllClasses(schoolId);
    // Load all students initially (no filter)
    _loadStudents(schoolId: schoolId);
  }

  void _resetAndLoad(String schoolId) {
    controller.selectedStudent.value = null;
    showPaymentDetails.value = false;
    showReceipts.value = false;
    isStudentSelectorCollapsed.value = false;
    filteredStudents.clear();
    _studentSearchController.clear();
    selectedFilterClass.value = null;
    selectedFilterSection.value = null;
    schoolController.sections.clear();
    _onSchoolReady(schoolId);
  }

  Future<void> _loadStudents({
    required String schoolId,
    String? classId,
    String? sectionId,
  }) async {
    try {
      controller.isLoading.value = true;
      String url = '${ApiConstants.getAllStudents}?schoolId=$schoolId';
      if (classId != null && classId.isNotEmpty) url += '&classId=$classId';
      if (sectionId != null && sectionId.isNotEmpty) url += '&sectionId=$sectionId';

      final response = await Get.find<ApiService>().get(url);
      if (response.data['ok'] == true) {
        final list = (response.data['data'] as List)
            .cast<Map<String, dynamic>>();
        controller.students.value = list;
        filteredStudents.value = list;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load students');
    } finally {
      controller.isLoading.value = false;
    }
  }


  @override
  void dispose() {
    _schoolWatcher?.dispose();
    _amountController.dispose();
    _chequeNumberController.dispose();
    _bankNameController.dispose();
    _chequeDateController.dispose();
    _upiReferenceController.dispose();
    _remarksController.dispose();
    _referenceNumberController.dispose();
    _busPointController.dispose();
    _studentSearchController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLandscape = screenSize.width > screenSize.height;


    return Container(
      color: _DS.bg,
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildClassSectionFilterRow(),
                const SizedBox(height: 12),
                _buildCollapsibleStudentSelector(context, isTablet, isLandscape),
                const SizedBox(height: 16),
                Obx(() => showReceipts.value &&
                    controller.selectedStudent.value != null
                    ? _buildStudentReceipts(context, isTablet)
                    : const SizedBox()),
                const SizedBox(height: 16),
                Obx(() => showPaymentDetails.value
                    ? _buildPaymentDetails(context, isTablet, isLandscape)
                    : const SizedBox()),
              ],
            ),
          ),
        ),
      ),
    );
  }
  // ── NEW: Class / Section filter chips ────────────────────────
  Widget _buildClassSectionFilterRow() {
    return Obx(() {
      final hasClass = selectedFilterClass.value != null;
      final hasSection = selectedFilterSection.value != null;
      return Row(children: [
        // Class chip
        GestureDetector(
          onTap: _showClassFilterSheet,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: hasClass ? _DS.accentSoft : _DS.surface,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: hasClass ? _DS.accent : _DS.border,
                width: hasClass ? 1.5 : 1,
              ),
              boxShadow: _DS.shadow,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.class_rounded,
                  size: 13,
                  color: hasClass ? _DS.accent : _DS.textMuted),
              const SizedBox(width: 5),
              Text(
                selectedFilterClass.value?.name ?? 'All Classes',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: hasClass ? _DS.accent : _DS.textSecondary,
                ),
              ),
              const SizedBox(width: 3),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 13,
                  color: hasClass ? _DS.accent : _DS.textMuted),
            ]),
          ),
        ),
        const SizedBox(width: 8),
        // Section chip — only enabled after class is selected
        GestureDetector(
          onTap: hasClass ? _showSectionFilterSheet : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: hasSection
                  ? _DS.accentSoft
                  : (hasClass ? _DS.surface : _DS.surfaceAlt),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: hasSection
                    ? _DS.accent
                    : (hasClass ? _DS.border : _DS.border.withOpacity(0.5)),
                width: hasSection ? 1.5 : 1,
              ),
              boxShadow: hasClass ? _DS.shadow : [],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.group_rounded,
                  size: 13,
                  color: hasSection
                      ? _DS.accent
                      : (hasClass ? _DS.textMuted : _DS.border)),
              const SizedBox(width: 5),
              Text(
                selectedFilterSection.value?.name ?? 'All Sections',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: hasSection
                      ? _DS.accent
                      : (hasClass
                      ? _DS.textSecondary
                      : _DS.textMuted),
                ),
              ),
              const SizedBox(width: 3),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 13,
                  color: hasSection
                      ? _DS.accent
                      : (hasClass ? _DS.textMuted : _DS.border)),
            ]),
          ),
        ),
        const Spacer(),
        // Clear filters
        if (hasClass || hasSection)
          GestureDetector(
            onTap: () {
              selectedFilterClass.value = null;
              selectedFilterSection.value = null;
              schoolController.sections.clear();
              final sid = _currentSchoolId;
              if (sid.isNotEmpty) _loadStudents(schoolId: sid);
            },
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _DS.dangerSoft,
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Icon(Icons.close_rounded,
                  size: 13, color: _DS.danger),
            ),
          ),
      ]);
    });
  }

  void _showClassFilterSheet() {
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
                borderRadius: BorderRadius.circular(100)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(children: [
              const Text('Filter by Class',
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
          // "All Classes" option
          Obx(() => ListTile(
            leading: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: selectedFilterClass.value == null
                    ? _DS.accentSoft
                    : _DS.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.all_inclusive_rounded,
                  size: 18,
                  color: selectedFilterClass.value == null
                      ? _DS.accent
                      : _DS.textMuted),
            ),
            title: const Text('All Classes',
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
            trailing: selectedFilterClass.value == null
                ? const Icon(Icons.check_circle_rounded,
                color: _DS.accent, size: 20)
                : null,
            onTap: () {
              selectedFilterClass.value = null;
              selectedFilterSection.value = null;
              schoolController.sections.clear();
              final sid = _currentSchoolId;
              if (sid.isNotEmpty) _loadStudents(schoolId: sid);
              Get.back();
            },
          )),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: Obx(() {
              final classes = schoolController.classes;
              if (classes.isEmpty)
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                      child: Text('No classes available',
                          style: TextStyle(
                              color: _DS.textMuted, fontSize: 13))),
                );
              return ListView.builder(
                shrinkWrap: true,
                itemCount: classes.length,
                itemBuilder: (_, i) {
                  final c = classes[i];
                  final isSel = selectedFilterClass.value?.id == c.id;
                  return ListTile(
                    leading: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: isSel ? _DS.accentSoft : _DS.surfaceAlt,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.class_rounded,
                          size: 18,
                          color: isSel ? _DS.accent : _DS.textMuted),
                    ),
                    title: Text(c.name,
                        style: TextStyle(
                          fontWeight: isSel
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 14,
                          color: isSel ? _DS.accent : _DS.textPrimary,
                        )),
                    trailing: isSel
                        ? const Icon(Icons.check_circle_rounded,
                        color: _DS.accent, size: 20)
                        : null,
                    onTap: () {
                      selectedFilterClass.value = c;
                      selectedFilterSection.value = null;
                      // Load sections for this class
                      final sid = _currentSchoolId;
                      if (sid.isNotEmpty)
                        schoolController.getAllSections(
                            classId: c.id, schoolId: sid);
                      // Reload students filtered by class
                      if (sid.isNotEmpty)
                        _loadStudents(schoolId: sid, classId: c.id);
                      Get.back();
                    },
                  );
                },
              );
            }),
          ),
          const SizedBox(height: 20),
        ]),
      ),
      isScrollControlled: true,
    );
  }

  void _showSectionFilterSheet() {
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
                borderRadius: BorderRadius.circular(100)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(children: [
              const Text('Filter by Section',
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
          Obx(() => ListTile(
            leading: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: selectedFilterSection.value == null
                    ? _DS.accentSoft
                    : _DS.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.all_inclusive_rounded,
                  size: 18,
                  color: selectedFilterSection.value == null
                      ? _DS.accent
                      : _DS.textMuted),
            ),
            title: const Text('All Sections',
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
            trailing: selectedFilterSection.value == null
                ? const Icon(Icons.check_circle_rounded,
                color: _DS.accent, size: 20)
                : null,
            onTap: () {
              selectedFilterSection.value = null;
              final sid = _currentSchoolId;
              final cid = selectedFilterClass.value?.id;
              if (sid.isNotEmpty)
                _loadStudents(schoolId: sid, classId: cid);
              Get.back();
            },
          )),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: Obx(() {
              final sections = schoolController.sections;
              if (sections.isEmpty)
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                      child: Text('No sections for this class',
                          style: TextStyle(
                              color: _DS.textMuted, fontSize: 13))),
                );
              return ListView.builder(
                shrinkWrap: true,
                itemCount: sections.length,
                itemBuilder: (_, i) {
                  final s = sections[i];
                  final isSel = selectedFilterSection.value?.id == s.id;
                  return ListTile(
                    leading: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: isSel ? _DS.accentSoft : _DS.surfaceAlt,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.group_rounded,
                          size: 18,
                          color: isSel ? _DS.accent : _DS.textMuted),
                    ),
                    title: Text(s.name,
                        style: TextStyle(
                          fontWeight: isSel
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 14,
                          color: isSel ? _DS.accent : _DS.textPrimary,
                        )),
                    trailing: isSel
                        ? const Icon(Icons.check_circle_rounded,
                        color: _DS.accent, size: 20)
                        : null,
                    onTap: () {
                      selectedFilterSection.value = s;
                      final sid = _currentSchoolId;
                      final cid = selectedFilterClass.value?.id;
                      if (sid.isNotEmpty)
                        _loadStudents(
                            schoolId: sid,
                            classId: cid,
                            sectionId: s.id);
                      Get.back();
                    },
                  );
                },
              );
            }),
          ),
          const SizedBox(height: 20),
        ]),
      ),
      isScrollControlled: true,
    );
  }
  // ── FIXED _selectStudent: reads classId/sectionId from the
  //    student's own data, not from schoolController.classes.first
  void _selectStudent(Map<String, dynamic> student) {
    print('Top-level keys: ${student.keys.toList()}');
    print('Student raw data: $student');

    // Helper function to extract ID securely whether it's a raw String or a nested Map object
    String extractId(dynamic field) {
      if (field == null) return '';
      if (field is Map) {
        return (field['_id'] ?? field['id'] ?? '').toString();
      }
      return field.toString();
    }

    final classId = extractId(student['currentClassId'] ?? student['classId'] ?? selectedFilterClass.value?.id);
    final sectionId = extractId(student['currentSectionId'] ?? student['sectionId'] ?? selectedFilterSection.value?.id);

    controller.selectedStudent.value = {
      'studentId':   student['_id']?.toString() ?? '',
      'studentName': (student['studentName'] ?? '').toString(),
      'classId':     classId,
      'sectionId':   sectionId,
    };
  }

  // ── FIXED _showReceipts: reads from already-processed map ────
  Widget _buildViewReceiptsButton() {
    return ApiRbacWrapper(
      apiEndpoint: 'GET /api/studentrecord/getrecord',
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            final s = controller.selectedStudent.value;
            if (s == null) return;
            _showReceipts(s);
          },
          icon: const Icon(Icons.receipt_long_rounded, size: 16),
          label: const Text('View Receipts'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _DS.warning,
            side: BorderSide(
                color: _DS.warning.withOpacity(0.4), width: 1.5),
            backgroundColor: _DS.warningSoft,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }


  void _showReceipts(Map<String, dynamic> student) async {
    final studentId = student['studentId']?.toString()
        ?? student['_id']?.toString() ?? '';
    final schoolId = _currentSchoolId;

    if (studentId.isEmpty || schoolId.isEmpty) {
      Get.snackbar('Error', 'Missing student or school information',
          backgroundColor: _DS.danger, colorText: Colors.white);
      return;
    }

    showReceipts.value = true;
    showPaymentDetails.value = false;
    isStudentSelectorCollapsed.value = true;

    try {
      final record =
      await controller.getStudentRecord(schoolId, studentId);
      if (record != null) {
        controller.studentRecord.value = record;
      } else {
        Get.snackbar('Not Found', 'No fee record found for this student',
            backgroundColor: Colors.orange, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load records: $e',
          backgroundColor: _DS.danger, colorText: Colors.white);
    }
  }

  Widget _buildStudentTypeSelectorInPayment(BuildContext context, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Student Type',
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.3)),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.blue.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Obx(() => DropdownButtonFormField<String>(
            decoration: InputDecoration(
              hintText: 'Select student type',
              hintStyle: TextStyle(color: Colors.grey.shade600),
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.category, color: const Color(0xFF2563EB), size: 20),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            dropdownColor: Colors.white,
            menuMaxHeight: 200,
            borderRadius: BorderRadius.circular(12),
            icon: Container(
              margin: const EdgeInsets.only(right: 12),
              child: Icon(Icons.keyboard_arrow_down, color: const Color(0xFF2563EB)),
            ),
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            value: selectedStudentType.value,
            items: const [
              DropdownMenuItem<String>(
                value: 'old',
                child: Row(
                  children: [
                    Icon(Icons.school, color: Colors.blue, size: 20),
                    SizedBox(width: 12),
                    Text('Old Student', style: TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              DropdownMenuItem<String>(
                value: 'new',
                child: Row(
                  children: [
                    Icon(Icons.person_add, color: Colors.green, size: 20),
                    SizedBox(width: 12),
                    Text('New Student', style: TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                selectedStudentType.value = value;
              }
            },
          )),
        ),
      ],
    );
  }

  Widget _buildSchoolSelector(BuildContext context, bool isTablet) {
    final userRole = _authController.user.value?.role?.toLowerCase() ?? '';
    final isCorrespondent = userRole == 'correspondent';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.school, color: Color(0xFF2563EB), size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Select School',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() {
              if (isCorrespondent) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.3)),
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.blue.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: DropdownButtonFormField<School>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      hintText: 'Choose School',
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.school, color: Color(0xFF2563EB), size: 20),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    dropdownColor: Colors.white,
                    menuMaxHeight: 300,
                    borderRadius: BorderRadius.circular(12),
                    icon: Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF2563EB)),
                    ),
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    value: _feeSchoolCtrl.selectedSchool.value, // ✅ single .value
                    selectedItemBuilder: (BuildContext context) {
                      return schoolController.schools.map<Widget>((School school) {
                        return Text(
                          school.name,
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      }).toList();
                    },
                    items: schoolController.schools.map((school) {
                      return DropdownMenuItem<School>(
                        value: school,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.school, color: Color(0xFF2563EB), size: 16),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                school.name,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (school) {
                      _feeSchoolCtrl.selectedSchool.value = school; // ✅ single .value
                      controller.selectedStudent.value = null;
                      showPaymentDetails.value = false;
                      showReceipts.value = false;
                      isStudentSelectorCollapsed.value = false;
                      if (school != null) {
                        _loadStudentsForSchool(school.id);
                      }
                    },
                  ),
                );
              } else {
                final userSchoolId = _authController.user.value?.schoolId;
                final userSchool = schoolController.schools.firstWhereOrNull(
                      (school) => school.id == userSchoolId,
                );
                if (userSchool != null && _feeSchoolCtrl.selectedSchool.value == null) { // ✅ single .value
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _feeSchoolCtrl.selectedSchool.value = userSchool; // ✅ single .value
                    _loadStudentsForSchool(userSchool.id);
                  });
                }
                return const SizedBox.shrink();
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsibleStudentSelector(BuildContext context, bool isTablet, bool isLandscape) {
    return Obx(() {
      final hasStudent = controller.selectedStudent.value != null;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: isStudentSelectorCollapsed.value && hasStudent ? 60 : null,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isStudentSelectorCollapsed.value && hasStudent
            ? _buildCompactStudentSelector(context, isTablet)
            : _buildFullStudentSelector(context, isTablet, isLandscape),
      );
    });
  }

  Widget _buildCompactStudentSelector(BuildContext context, bool isTablet) {
    return Padding(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.person, color: const Color(0xFF2563EB), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              controller.selectedStudent.value?['studentName'] ?? 'Unknown Student',
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () => isStudentSelectorCollapsed.value = false,
            icon: const Icon(Icons.edit, size: 18),
            tooltip: 'Change Student',
          ),
        ],
      ),
    );
  }

  Widget _buildFullStudentSelector(BuildContext context, bool isTablet, bool isLandscape) {
    return Padding(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person, color: const Color(0xFF2563EB), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Select Student',
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: _DS.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _DS.border),
            ),
            child: TextFormField(
              controller: _studentSearchController,
              style: const TextStyle(fontSize: 14, color: _DS.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search by name or roll number',
                hintStyle: TextStyle(fontSize: 13, color: _DS.textMuted),
                prefixIcon: Icon(Icons.search_rounded,
                    color: _DS.textMuted, size: 20),
                border: InputBorder.none,
                contentPadding:
                EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onChanged: _filterStudents,
            ),
          ),
          const SizedBox(height: 16),
          // Replace the Container(height:200 ...) list with:
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: Obx(() => controller.isLoading.value
                ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: _DS.accent),
                ))
                : filteredStudents.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: const BoxDecoration(
                          color: _DS.accentSoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.search_off_rounded,
                            size: 26, color: _DS.accent),
                      ),
                      const SizedBox(height: 12),
                      const Text('No students found',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _DS.textPrimary)),
                    ]),
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              itemCount: filteredStudents.length,
              itemBuilder: (context, index) {
                final student = filteredStudents[index];
                final isSelected =
                    controller.selectedStudent.value?['studentId'] ==
                        student['_id'];
                final name =
                    student['studentName'] as String? ?? 'Unknown';
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _DS.accentSoft
                        : _DS.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? _DS.accent
                          : _DS.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    leading: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _DS.accent
                            : _DS.surfaceAlt,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty
                              ? name[0].toUpperCase()
                              : 'U',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : _DS.textSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    title: Text(name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? _DS.accent
                              : _DS.textPrimary,
                        )),
                    subtitle: Text(
                      'Roll: ${student['rollNumber'] ?? 'N/A'}',
                      style: const TextStyle(
                          fontSize: 11, color: _DS.textMuted),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded,
                        color: _DS.accent, size: 20)
                        : null,
                    onTap: () => _selectStudent(student),
                  ),
                );
              },
            )),
          ),
          const SizedBox(height: 16),
          // Action Buttons
          Obx(() => controller.selectedStudent.value != null
              ? isLandscape && isTablet
                  ? Row(
                      children: [
                        Expanded(child: _buildViewReceiptsButton()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildCollectFeeButton()),
                      ],
                    )
                  : Column(
                      children: [
                        _buildViewReceiptsButton(),
                        const SizedBox(height: 12),
                        _buildCollectFeeButton(),
                      ],
                    )
              : const SizedBox()),
        ],
      ),
    );
  }



  Widget _buildCollectFeeButton() {
    return ApiRbacWrapper(
      apiEndpoint: 'POST /api/studentrecord/collectfee',
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            showPaymentDetails.value = true;
            showReceipts.value = false;
            isStudentSelectorCollapsed.value = true;
          },
          icon: const Icon(Icons.payment_rounded, size: 16),
          label: const Text('Collect Fee'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _DS.accent,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentReceipts(BuildContext context, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.receipt_long, color: Colors.green, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Student Fee Record & Receipts',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() {
              final record = controller.studentRecord.value;
              if (record == null) {
                return const Center(child: CircularProgressIndicator());
              }

              final receipts = record['receipts'] as List? ?? [];
              if (receipts.isEmpty) {
                return _buildEmptyReceipts();
              }

              return Column(
                children: receipts.map<Widget>((receipt) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.receipt, color: Colors.green, size: 20),
                      ),
                      title: Text(
                        'Receipt #${receipt['receiptNo'] ?? 'N/A'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Date: ${receipt['paymentDate'] ?? 'N/A'} • Mode: ${receipt['paymentMode'] ?? 'N/A'}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '₹${receipt['amountPaid']?.toStringAsFixed(0) ?? '0'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                      onTap: () => controller.showReceiptDetail(record),
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyReceipts() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: const Column(
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No receipts found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'No payment receipts found for this student',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalFields(BuildContext context, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reference Number (for all payment modes)
        TextFormField(
          controller: _referenceNumberController,
          decoration: InputDecoration(
            labelText: 'Reference Number (Optional)',
            prefixIcon: const Icon(Icons.tag),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
        const SizedBox(height: 16),

        // Remarks
        TextFormField(
          controller: _remarksController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Remarks (Optional)',
            prefixIcon: const Icon(Icons.notes),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
        const SizedBox(height: 16),

        // Bus Applicable Toggle
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    fit: FlexFit.loose,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.directions_bus, color: const Color(0xFF2563EB)),
                        const SizedBox(width: 12),
                        Text(
                          'Bus Fee Applicable',
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Obx(() => Switch(
                    value: isBusApplicable.value,
                    onChanged: (value) => isBusApplicable.value = value,
                    activeColor: const Color(0xFF2563EB),
                  )),
                ],
              ),
              const SizedBox(height: 12),
              Obx(() => isBusApplicable.value
                  ? TextFormField(
                key: const ValueKey('busPointField'), // ADD THIS
                controller: _busPointController,
                decoration: InputDecoration(
                  labelText: 'Bus Stop/Point',
                  hintText: 'Enter bus stop name',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                ),
                validator: (value) {
                  if (isBusApplicable.value &&
                      (value == null || value.isEmpty)) {
                    return 'Please enter bus stop name';
                  }
                  return null;
                },
              )
                  : const SizedBox()),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Manual Due Allocation Toggle
        // Manual Due Allocation Toggle — DISABLED until paidHeads UI is built
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,  // greyed out
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calculate, color: Colors.grey.shade400),  // greyed
                  const SizedBox(width: 12),
                  Flexible(
                    fit: FlexFit.loose,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manual Due Allocation',
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade400,  // greyed
                          ),
                        ),
                        Text(
                          'Coming soon',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Switch(
                value: false,         // always off
                onChanged: null,      // disabled
                activeColor: const Color(0xFF2563EB),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFileUploadSection(BuildContext context, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload Payment Proof (Optional)',
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              // Upload Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: controller.pickFiles,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Select Images'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
                    foregroundColor: const Color(0xFF2563EB),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Selected Files List
              Obx(() => controller.selectedFiles.isEmpty
                  ? Text(
                      'No files selected',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: controller.selectedFiles.asMap().entries.map((entry) {
                        final index = entry.key;
                        final file = entry.value;
                        return GestureDetector(
                          onTap: () => _showFullImage(file.path!),
                          child: Stack(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(file.path!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Icon(Icons.image, color: Colors.grey),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => controller.removeFile(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentDetails(BuildContext context, bool isTablet, bool isLandscape) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.payment, color: const Color(0xFF2563EB), size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Payment Details',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Amount Field
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.green.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  labelStyle: TextStyle(color: Colors.green.shade700),
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.currency_rupee, color: Colors.green),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter valid amount';
                  }
                  return null;
                },
              ),
            ),

            const SizedBox(height: 20),

            // Payment Mode Selection
            Text(
              'Payment Mode',
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Obx(() => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['cash', 'upi', 'cheque', 'bank'].map((mode) {
                final isSelected = controller.selectedPaymentMode.value == mode;
                return Container(
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [const Color(0xFF2563EB), const Color(0xFF2563EB).withOpacity(0.8)],
                          )
                        : LinearGradient(
                            colors: [Colors.grey.shade100, Colors.grey.shade50],
                          ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade300,
                    ),
                  ),
                  child: FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getPaymentModeIcon(mode),
                          size: 16,
                          color: isSelected ? Colors.green : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          mode.toUpperCase(),
                          style: TextStyle(
                            color: isSelected ? Colors.green : Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    backgroundColor: Colors.transparent,
                    selectedColor: Colors.transparent,
                    checkmarkColor: Colors.transparent,
                    onSelected: (selected) {
                      if (selected) controller.selectedPaymentMode.value = mode;
                    },
                  ),
                );
              }).toList(),
            )),

            const SizedBox(height: 20),

            // Conditional Fields based on Payment Mode
            Obx(() => _buildPaymentModeFields(context, isTablet            )),

            const SizedBox(height: 20),

            // Student Type Selection (Old/New)
            _buildStudentTypeSelectorInPayment(context, isTablet),

            const SizedBox(height: 20),

            // Additional Fields
            _buildAdditionalFields(context, isTablet),

            const SizedBox(height: 20),

            // File Upload Section
            _buildFileUploadSection(context, isTablet),

            const SizedBox(height: 24),

            // Final Collect Button
            ApiRbacWrapper(
              apiEndpoint: 'POST /api/studentrecord/collectfee',
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF2563EB), Colors.blue.shade700],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Obx(() => ElevatedButton.icon(
                  onPressed: controller.isLoading.value ? null : _collectFee,
                  icon: controller.isLoading.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.payment, color: Colors.white),
                  label: Text(
                    controller.isLoading.value ? 'Processing...' : 'Process Payment',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPaymentModeIcon(String mode) {
    switch (mode) {
      case 'cash':
        return Icons.money;
      case 'upi':
        return Icons.qr_code;
      case 'cheque':
        return Icons.receipt;
      case 'bank':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }

  Widget _buildPaymentModeFields(BuildContext context, bool isTablet) {
    final paymentMode = controller.selectedPaymentMode.value;

    switch (paymentMode) {
      case 'cash':
        return _buildCashDenominationFields(context, isTablet);
      case 'cheque':
        return _buildChequeFields(context, isTablet);
      case 'upi':
        return _buildUPIFields(context, isTablet);
      default:
        return const SizedBox();
    }
  }

  Widget _buildCashDenominationFields(BuildContext context, bool isTablet) {
    final denominations = [2000, 500, 200, 100, 50, 20, 10, 5, 2, 1];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cash Denomination Tally',
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter denomination count to verify cash amount',
          style: TextStyle(
            fontSize: isTablet ? 14 : 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: denominations.map((denom) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Container(
                  constraints: BoxConstraints(maxWidth: isTablet ? 400 : 350),
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text('₹$denom:', style: const TextStyle(fontWeight: FontWeight.w500)),
                    ),
                      const SizedBox(width: 8),
                      Flexible(
                      flex: 2,
                        fit: FlexFit.loose,
                        child: SizedBox(
                          width: isTablet ? 120 : 100,
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '0',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (value) {
                          final count = int.tryParse(value) ?? 0;
                          controller.updateCashDenomination(denom.toString(), count);
                        },
                          ),
                      ),
                    ),
                    const SizedBox(width: 8),
                      Flexible(
                      flex: 1,
                        fit: FlexFit.loose,
                        child: SizedBox(
                          width: isTablet ? 80 : 70,
                      child: Obx(() {
                        final count = controller.cashDenominations[denom.toString()] ?? 0;
                        final total = denom * count;
                        return Text(
                          '₹$total',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right,
                        );
                      }),
                        ),
                    ),
                  ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Obx(() {
          final totalCash = controller.totalCashAmount;
          final enteredAmount = double.tryParse(_amountController.text) ?? 0;
          final isMatching = totalCash == enteredAmount;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isMatching ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isMatching ? Colors.green : Colors.red,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Cash: ₹$totalCash',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isMatching ? Colors.green : Colors.red,
                  ),
                ),
                Icon(
                  isMatching ? Icons.check_circle : Icons.error,
                  color: isMatching ? Colors.green : Colors.red,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildChequeFields(BuildContext context, bool isTablet) {
    return Column(
      children: [
        TextFormField(
          controller: _chequeNumberController,
          decoration: InputDecoration(
            labelText: 'Cheque Number',
            prefixIcon: const Icon(Icons.receipt),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter cheque number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _bankNameController,
          decoration: InputDecoration(
            labelText: 'Bank Name',
            prefixIcon: const Icon(Icons.account_balance),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter bank name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // Replace _chequeDateController TextFormField in _buildChequeFields:
        TextFormField(
          controller: _chequeDateController,
          readOnly: true,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) {
              _chequeDateController.text =
              '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
            }
          },
          decoration: InputDecoration(
            labelText: 'Cheque Date',
            prefixIcon: const Icon(Icons.calendar_today),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter cheque date';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildUPIFields(BuildContext context, bool isTablet) {
    return TextFormField(
      controller: _upiReferenceController,
      decoration: InputDecoration(
        labelText: 'UPI Reference (Optional)',
        prefixIcon: const Icon(Icons.qr_code),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  void _showFullImage(String imagePath) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: Image.file(
                File(imagePath),
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // All the existing methods remain the same
  void _loadStudentsForSchool(String schoolId) async {
    try {
      controller.isLoading.value = true;
      final response = await Get.find<ApiService>().get(
        '${ApiConstants.getAllStudents}?schoolId=$schoolId',
      );

      if (response.data['ok'] == true) {
        final studentList = response.data['data'] as List;
        controller.students.value = studentList.cast<Map<String, dynamic>>();
        filteredStudents.value = controller.students;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load students');
    } finally {
      controller.isLoading.value = false;
    }
  }

  void _filterStudents(String query) {
    if (query.isEmpty) {
      filteredStudents.value = controller.students;
      return;
    }

    filteredStudents.value = controller.students.where((student) {
      final name = (student['studentName'] ?? '').toLowerCase();
      final roll = (student['rollNumber'] ?? '').toLowerCase();
      final searchQuery = query.toLowerCase();
      return name.contains(searchQuery) || roll.contains(searchQuery);
    }).toList();
  }

  void _updateSelectedStudent(Map<String, dynamic> student, String classId, String sectionId) {
    controller.selectedStudent.value = {
      'studentId': student['_id'],
      'studentName': student['studentName'],
      'classId': classId,
      'sectionId': sectionId,
    };
  }


  void _collectFee() {
    _formKey.currentState!.save();
    if (_formKey.currentState!.validate()) {
      final student = controller.selectedStudent.value!;
      final amount = double.parse(_amountController.text);

      final studentId = student['studentId']?.toString() ?? '';
      final classId = student['classId']?.toString() ?? '';
      final sectionId = student['sectionId']?.toString() ?? '';
      final schoolId = _feeSchoolCtrl.selectedSchool.value?.id ?? '';
      print('studentId: $studentId');
      print('classId: $classId');
      print('sectionId: $sectionId');
      print('schoolId: $schoolId');
      if (studentId.isEmpty || schoolId.isEmpty || classId.isEmpty ) {
        Get.snackbar('Error', 'Missing required information');
        return;
      }

      final additionalData = {
        'schoolId': schoolId,
        'studentId': studentId,
        'classId': classId,
        'sectionId': sectionId,
        'amount': amount,
        'paymentMode': controller.selectedPaymentMode.value,
        'studentName': student['studentName'] ?? '',
        'newOld': selectedStudentType.value, // 'old' or 'new'
        'manualDueAllocation': false,
        'paidHeads': {}, // Empty object as default, can be populated if needed
        'remarks': _remarksController.text,
        'isBusApplicable': isBusApplicable.value,
        'busPoint': _busPointController.text,
        if (_referenceNumberController.text.isNotEmpty)
          'referenceNumber': _referenceNumberController.text,
        if (controller.selectedPaymentMode.value == 'cheque') ...{
          'chequeNumber': _chequeNumberController.text,
          'bankName': _bankNameController.text,
          'chequeDate': _chequeDateController.text,
        },
        if (controller.selectedPaymentMode.value == 'upi')
          'upiReference': _upiReferenceController.text,
      };

      controller.collectFee(
        studentId: studentId,
        classId: classId,
        sectionId: sectionId,
        amount: amount,
        paymentMode: controller.selectedPaymentMode.value,
        additionalData: additionalData,
      ).then((_) {
        // Clear form fields after successful submission
        _amountController.clear();
        _remarksController.clear();
        _referenceNumberController.clear();
        _chequeNumberController.clear();
        _bankNameController.clear();
        _chequeDateController.clear();
        _upiReferenceController.clear();
        _busPointController.clear();
        showPaymentDetails.value = false;
        isStudentSelectorCollapsed.value = false;
      });
    }else {
      // Scroll to the first error so user can see it
      Get.snackbar('Validation', 'Please check highlighted fields above',
          backgroundColor: Colors.orange, colorText: Colors.white);
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// DROP-IN REPLACEMENT for _FeeStructureViewTab + _FeeStructureViewTabState
// in fee_collection_tabbed_view.dart
// ═══════════════════════════════════════════════════════════════

class _FeeStructureViewTab extends StatefulWidget {
  @override
  State<_FeeStructureViewTab> createState() => _FeeStructureViewTabState();
}

class _FeeStructureViewTabState extends State<_FeeStructureViewTab> {
  final schoolController = Get.find<SchoolController>();
  final feeController    = Get.put(FeeStructureController());

  final selectedSchool = Rxn<School>();
  final selectedClass  = Rxn<SchoolClass>();

  final isSelectorsExpanded      = ValueNotifier<bool>(true);
  final isOldStructureExpanded   = ValueNotifier<bool>(true);
  final isNewStructureExpanded   = ValueNotifier<bool>(true);

  // ── Per-type fee head lists (populated by _loadFeeStructures) ─
  final oldFeeHeads = <Map<String, dynamic>>[].obs;
  final newFeeHeads = <Map<String, dynamic>>[].obs;

  final isLoadingOld = false.obs;
  final isLoadingNew = false.obs;

  Worker? _schoolWatcher;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveSchool());
  }

  // ── School resolution (unchanged) ─────────────────────────────
  void _resolveSchool() {
    try {
      final feeSchoolCtrl = Get.find<FeeCollectionSchoolController>();
      final current = feeSchoolCtrl.selectedSchool.value;
      if (current != null) {
        _applySchool(current);
      } else {
        _applySchoolFromAuth();
      }
      _schoolWatcher = ever(feeSchoolCtrl.selectedSchool, (school) {
        if (school != null) _applySchool(school);
      });
    } catch (_) {
      _applySchoolFromAuth();
    }
  }

  void _applySchool(School school) {
    selectedSchool.value = school;
    selectedClass.value  = null;
    oldFeeHeads.clear();
    newFeeHeads.clear();
    schoolController.getAllClasses(school.id);
    isSelectorsExpanded.value = true;
  }

  void _applySchoolFromAuth() {
    final authCtrl = Get.find<AuthController>();
    final schoolId = authCtrl.user.value?.schoolId;
    if (schoolId == null || schoolId.isEmpty) return;

    final existing = schoolController.schools.firstWhereOrNull((s) => s.id == schoolId);
    if (existing != null) {
      _applySchool(existing);
    } else {
      schoolController.getAllSchools().then((_) {
        final found = schoolController.schools.firstWhereOrNull((s) => s.id == schoolId);
        if (found != null) _applySchool(found);
      });
    }
  }

  @override
  void dispose() {
    _schoolWatcher?.dispose();
    super.dispose();
  }

  // ── KEY FIX: Load both student types in parallel ─────
  Future<void> _loadFeeStructures() async {
    final schoolId = selectedSchool.value?.id
        ?? _tryGetFeeSchoolId()
        ?? Get.find<AuthController>().user.value?.schoolId;

    if (schoolId == null || schoolId.isEmpty) {
      Get.snackbar(
        'Error',
        'No school selected',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    if (selectedClass.value == null) return;
    final classId = selectedClass.value!.id;

    // Start both loading states simultaneously
    isLoadingOld.value = true;
    isLoadingNew.value = true;

    try {
      // Run both API calls at the exact same time in parallel
      final results = await Future.wait([
        feeController.getCustomFeeHeads(
          schoolId: schoolId,
          classId:  classId,
          type:     'old',
        ),
        feeController.getCustomFeeHeads(
          schoolId: schoolId,
          classId:  classId,
          type:     'new',
        ),
      ]);

      // Assign the parallel results cleanly
      oldFeeHeads.assignAll(results[0]);
      newFeeHeads.assignAll(results[1]);

    } catch (e) {
      debugPrint('❌ Parallel fee head loading error: $e');
      Get.snackbar(
        'Error',
        'Failed to load fee configurations.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      // Ensure loaders turn off regardless of success or failure
      isLoadingOld.value = false;
      isLoadingNew.value = false;
    }
  }
  String? _tryGetFeeSchoolId() {
    try {
      return Get.find<FeeCollectionSchoolController>().selectedSchool.value?.id;
    } catch (_) {
      return null;
    }
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Container(
      color: const Color(0xFFF0F4F8),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        child: SingleChildScrollView(
          child: Column(children: [
            // ── Class selector ─────────────────────────────────
            ValueListenableBuilder<bool>(
              valueListenable: isSelectorsExpanded,
              builder: (context, isExpanded, _) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: isExpanded ? null : 60,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _DS.shadow,
                    ),
                    child: isExpanded
                        ? _buildExpandedSelectors(isTablet)
                        : _buildCompactSelectors(isTablet),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // ── Old students fee structure ─────────────────────
            _buildFeeStructureCard(
              title:     'Old Students Fee Structure',
              icon:      Icons.school_rounded,
              color:     _DS.accent,
              feeHeads:  oldFeeHeads,
              isLoading: isLoadingOld,
              isExpanded: isOldStructureExpanded,
              isTablet:  isTablet,
            ),

            const SizedBox(height: 16),

            // ── New students fee structure ─────────────────────
            _buildFeeStructureCard(
              title:     'New Students Fee Structure',
              icon:      Icons.person_add_rounded,
              color:     _DS.success,
              feeHeads:  newFeeHeads,
              isLoading: isLoadingNew,
              isExpanded: isNewStructureExpanded,
              isTablet:  isTablet,
            ),

            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  // ── Compact selector (collapsed) ──────────────────────────────
  Widget _buildCompactSelectors(bool isTablet) {
    return InkWell(
      onTap: () => isSelectorsExpanded.value = true,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _DS.accentSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.class_rounded, color: _DS.accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(() => Text(
              selectedClass.value?.name ?? 'Select a class to view fee structure',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: _DS.textPrimary),
              overflow: TextOverflow.ellipsis,
            )),
          ),
          const Icon(Icons.edit_rounded, size: 16, color: _DS.textMuted),
        ]),
      ),
    );
  }

  // ── Expanded selector (class chip) ────────────────────────────
  Widget _buildExpandedSelectors(bool isTablet) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Class',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _DS.textMuted)),
          const SizedBox(height: 10),
          Obx(() {
            final cls = selectedClass.value;
            return GestureDetector(
              onTap: _showClassSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: cls != null ? _DS.accentSoft : _DS.surfaceAlt,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: cls != null ? _DS.accent : _DS.border,
                    width: cls != null ? 1.5 : 1,
                  ),
                  boxShadow: _DS.shadow,
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.class_rounded,
                      size: 14,
                      color: cls != null ? _DS.accent : _DS.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    cls?.name ?? 'Choose a class…',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cls != null ? _DS.accent : _DS.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      size: 14,
                      color: cls != null ? _DS.accent : _DS.textMuted),
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Class picker sheet ─────────────────────────────────────────
  void _showClassSheet() {
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
                color: _DS.border, borderRadius: BorderRadius.circular(100)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(children: [
              const Text('Select Class',
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
            constraints: const BoxConstraints(maxHeight: 360),
            child: Obx(() {
              final classes = schoolController.classes;
              if (classes.isEmpty)
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                      child: Text('No classes available',
                          style: TextStyle(color: _DS.textMuted, fontSize: 14))),
                );
              return ListView.builder(
                shrinkWrap: true,
                itemCount: classes.length,
                itemBuilder: (_, i) {
                  final c = classes[i];
                  final isSel = selectedClass.value?.id == c.id;
                  return ListTile(
                    leading: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: isSel ? _DS.accentSoft : _DS.surfaceAlt,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.class_rounded,
                          size: 18,
                          color: isSel ? _DS.accent : _DS.textMuted),
                    ),
                    title: Text(c.name,
                        style: TextStyle(
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 14,
                          color: isSel ? _DS.accent : _DS.textPrimary,
                        )),
                    trailing: isSel
                        ? const Icon(Icons.check_circle_rounded,
                        color: _DS.accent, size: 20)
                        : null,
                    onTap: () {
                      selectedClass.value = c;
                      oldFeeHeads.clear();
                      newFeeHeads.clear();
                      Get.back();
                      _loadFeeStructures().then((_) {
                        isSelectorsExpanded.value = false;
                      });
                    },
                  );
                },
              );
            }),
          ),
          const SizedBox(height: 20),
        ]),
      ),
      isScrollControlled: true,
    );
  }

  // ── Fee structure card (collapsible) ──────────────────────────
  Widget _buildFeeStructureCard({
    required String title,
    required IconData icon,
    required Color color,
    required RxList<Map<String, dynamic>> feeHeads,
    required RxBool isLoading,
    required ValueNotifier<bool> isExpanded,
    required bool isTablet,
  }) {
    return ValueListenableBuilder<bool>(
      valueListenable: isExpanded,
      builder: (context, expanded, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          // collapsed: just the header bar (60px); expanded: full content
          height: expanded ? null : 60,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: _DS.shadow,
            ),
            child: expanded
                ? _buildExpandedCard(title, icon, color, feeHeads, isLoading,
                isExpanded, isTablet)
                : _buildCollapsedCard(title, icon, color, feeHeads, isExpanded),
          ),
        );
      },
    );
  }

  Widget _buildCollapsedCard(
      String title,
      IconData icon,
      Color color,
      RxList<Map<String, dynamic>> feeHeads,
      ValueNotifier<bool> isExpanded,
      ) {
    return InkWell(
      onTap: () => isExpanded.value = true,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(() => Text(
              feeHeads.isNotEmpty
                  ? '$title  (${feeHeads.length} heads)'
                  : title,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: _DS.textPrimary),
              overflow: TextOverflow.ellipsis,
            )),
          ),
          const Icon(Icons.expand_more_rounded,
              size: 18, color: _DS.textMuted),
        ]),
      ),
    );
  }

  Widget _buildExpandedCard(
      String title,
      IconData icon,
      Color color,
      RxList<Map<String, dynamic>> feeHeads,
      RxBool isLoading,
      ValueNotifier<bool> isExpanded,
      bool isTablet,
      ) {
    return Padding(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Card header
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style: TextStyle(
                    fontSize: isTablet ? 15 : 13,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ),
          // Summary badge
          Obx(() {
            if (feeHeads.isEmpty) return const SizedBox.shrink();
            final total = feeHeads.fold<double>(
                0.0, (s, h) => s + ((h['feeAmount'] ?? h['amount'] ?? 0.0) as num).toDouble());
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '₹${total % 1 == 0 ? total.toInt() : total.toStringAsFixed(2)}',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color),
              ),
            );
          }),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => isExpanded.value = false,
            child: const Icon(Icons.expand_less_rounded,
                size: 20, color: _DS.textMuted),
          ),
        ]),

        const SizedBox(height: 16),

        // Body: loading / empty / list
        Obx(() {
          if (isLoading.value) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: color, strokeWidth: 2),
              ),
            );
          }

          if (feeHeads.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.12)),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.receipt_long_rounded,
                      size: 22, color: color.withOpacity(0.6)),
                ),
                const SizedBox(height: 10),
                Text(
                  selectedClass.value != null
                      ? 'No fee heads set for ${selectedClass.value!.name}'
                      : 'Select a class above',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color.withOpacity(0.7)),
                  textAlign: TextAlign.center,
                ),
                if (selectedClass.value != null) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Go to the "Fee Structure" set tab to add fee heads.',
                    style: TextStyle(fontSize: 11, color: _DS.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ]),
            );
          }

          // Fee head rows
          return Column(
            children: feeHeads.asMap().entries.map((entry) {
              final i    = entry.key;
              final head = entry.value;
              // Friendly cycling accent colours
              final colors = [
                (_DS.accent,               const Color(0xFFEFF6FF)),
                (_DS.success,              const Color(0xFFD1FAE5)),
                (const Color(0xFFD97706), const Color(0xFFFEF3C7)),
                (const Color(0xFF7C3AED), const Color(0xFFEDE9FE)),
                (const Color(0xFF0891B2), const Color(0xFFCFFAFE)),
                (const Color(0xFF9333EA), const Color(0xFFF3E8FF)),
              ];
              final c      = colors[i % colors.length];
              final name   = (head['feeName'] ?? head['name'] ?? 'Fee Head').toString();
              final amount = (head['feeAmount'] ?? head['amount'] ?? 0);
              final amtStr = amount is double
                  ? (amount % 1 == 0
                  ? amount.toInt().toString()
                  : amount.toStringAsFixed(2))
                  : amount.toString();

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
                decoration: BoxDecoration(
                  color: c.$2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: c.$1.withOpacity(0.2)),
                ),
                child: Row(children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: c.$1.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.label_important_rounded,
                        color: c.$1, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(name,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: c.$1)),
                  ),
                  Text(
                    '₹ $amtStr',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _DS.textPrimary),
                  ),
                ]),
              );
            }).toList(),
          );
        }),
      ]),
    );
  }
}
class _FeeStructureTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FeeStructureView();
  }
}

class _StudentRecordsTab extends StatelessWidget {
  final controller = Get.find<AccountingController>();
  final recordController = Get.put(StudentRecordController());

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green.shade50, Colors.teal.shade50],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 20 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.history, color: Colors.green, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Transaction Records',
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: ElevatedButton.icon(
                            onPressed: _loadTransactions,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Refresh'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Obx(() {
                      if (recordController.isLoading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (recordController.studentRecords.isEmpty) {
                        return _buildEmptyTransactions();
                      }
                      return Column(
                        children: recordController.studentRecords.map((record) {
                          return _buildTransactionItem(
                            record['studentName'] ?? 'Unknown Student',
                            '₹${record['amount'] ?? 0}',
                            record['paymentMode'] ?? 'Unknown',
                            record['date'] ?? 'Unknown Date',
                            record['_id'] ?? '',
                            record['status'] == 'paid',
                          );
                        }).toList(),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: const Column(
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No transaction records found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Collect some fees to see records here',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _loadTransactions() async {
    final schoolId = Get.find<AuthController>().user.value?.schoolId;
    if (schoolId != null) {
      Get.snackbar('Info', 'Loading transaction records from database...');
    } else {
      Get.snackbar('Error', 'School ID not found');
    }
  }

  Widget _buildTransactionItem(
    String student,
    String amount,
    String mode,
    String date,
    String transactionId,
    bool isPaid,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isPaid ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPaid ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isPaid ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPaid ? Icons.check_circle : Icons.pending,
              color: isPaid ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '$mode • $date',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                if (transactionId.isNotEmpty)
                  Text(
                    'ID: $transactionId',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPaid ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isPaid ? 'PAID' : 'PENDING',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}