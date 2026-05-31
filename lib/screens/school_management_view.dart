import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:collection/collection.dart';
import 'package:school_app/controllers/clubs_controller.dart';
import 'package:school_app/widgets/clubs_dialogue_in_students_tab.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/controllers/student_record_controller.dart';
import 'package:school_app/controllers/user_management_controller.dart';
import 'package:school_app/controllers/student_management_controller.dart';
import 'package:school_app/controllers/attendance_controller.dart'
    as old_attendance;
import 'package:school_app/controllers/fee_structure_controller.dart';
import 'package:school_app/controllers/club_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/widgets/responsive_wrapper.dart';
import 'package:school_app/widgets/api_rbac_wrapper.dart';
import 'package:school_app/widgets/school_logo_helper.dart';
import 'package:school_app/core/utils/class_utils.dart';
import 'package:school_app/core/rbac/api_rbac.dart';
import 'package:school_app/core/extensions/widget_extensions.dart';
import 'package:school_app/models/school_models.dart';
import 'package:school_app/models/student_model.dart';
import 'package:school_app/models/club_model.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/widgets/fee_structure_widgets.dart';
import 'package:school_app/screens/student_form_page.dart';
import 'package:school_app/screens/student_individual_detail_view.dart';
import 'package:school_app/screens/user_detail_view.dart';
import 'package:school_app/screens/teacher_assignment_view.dart';
import '../controllers/marks_controller.dart';

// ─── Design System ────────────────────────────────────────────────────────────
class _DS {
  static const primary = Color(0xFF1E3A5F);
  static const primaryLight = Color(0xFF2D5F9E);
  static const accent = Color(0xFF3B82F6);
  static const accentSoft = Color(0xFFEFF6FF);
  static const accentMid = Color(0xFFBFDBFE);
  static const bg = Color(0xFFF0F4F8);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF8FAFC);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const textMuted = Color(0xFF94A3B8);
  static const success = Color(0xFF059669);
  static const successSoft = Color(0xFFD1FAE5);
  static const warning = Color(0xFFD97706);
  static const warningSoft = Color(0xFFFEF3C7);
  static const danger = Color(0xFFDC2626);
  static const dangerSoft = Color(0xFFFEE2E2);
  static const border = Color(0xFFE2E8F0);
  static const borderFocus = Color(0xFF93C5FD);
  static const shadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const shadowMd = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 8)),
  ];
  static const radius = 14.0;
  static const radiusSm = 8.0;
  static const radiusLg = 20.0;
  static const radiusXl = 28.0;
}

// ─── Reusable Design Components ───────────────────────────────────────────────
Widget _card({required Widget child, EdgeInsets? padding, Color? color}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: padding ?? const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color ?? _DS.surface,
      borderRadius: BorderRadius.circular(_DS.radius),
      border: Border.all(color: _DS.border),
      boxShadow: _DS.shadow,
    ),
    child: child,
  );
}

Widget _badge(String label, {Color? bg, Color? fg}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: bg ?? _DS.accentSoft,
      borderRadius: BorderRadius.circular(100),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: fg ?? _DS.accent,
        letterSpacing: 0.3,
      ),
    ),
  );
}

Widget _iconBox(IconData icon, {Color? bg, Color? fg, double size = 20}) {
  return Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: bg ?? _DS.accentSoft,
      borderRadius: BorderRadius.circular(_DS.radiusSm),
    ),
    child: Icon(icon, color: fg ?? _DS.accent, size: size),
  );
}

Widget _sectionHeader(String title, {Widget? action}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
    child: Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: _DS.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _DS.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        if (action != null) ...[const Spacer(), action],
      ],
    ),
  );
}

Widget _primaryBtn({
  required String label,
  required VoidCallback? onPressed,
  IconData? icon,
  bool loading = false,
  Color? color,
}) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? _DS.accent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: _DS.accentMid,
        padding: const EdgeInsets.symmetric(vertical: 15),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radius)),
      ),
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
    ),
  );
}

Widget _field(TextEditingController ctrl, String label,
    {TextInputType? keyboardType, bool obscure = false, String? prefix}) {
  return TextField(
    controller: ctrl,
    obscureText: obscure,
    keyboardType: keyboardType,
    style: const TextStyle(fontSize: 15, color: _DS.textPrimary),
    decoration: InputDecoration(
      labelText: label,
      prefixText: prefix,
      labelStyle: const TextStyle(color: _DS.textSecondary, fontSize: 14),
      filled: true,
      fillColor: _DS.surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_DS.radiusSm),
        borderSide: const BorderSide(color: _DS.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_DS.radiusSm),
        borderSide: const BorderSide(color: _DS.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_DS.radiusSm),
        borderSide: const BorderSide(color: _DS.accent, width: 1.5),
      ),
    ),
  );
}

Widget _dropdown<T>({
  required T? value,
  required List<DropdownMenuItem<T>> items,
  required void Function(T?) onChanged,
  required String hint,
  required IconData icon,
  List<Widget>? selectedItemBuilder,
}) {
  return Container(
    decoration: BoxDecoration(
      color: _DS.surfaceAlt,
      borderRadius: BorderRadius.circular(_DS.radiusSm),
      border: Border.all(color: _DS.border),
    ),
    child: DropdownButtonFormField<T>(
      isExpanded: true,
      value: value,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _DS.textMuted, fontSize: 14),
        prefixIcon: Icon(icon, color: _DS.accent, size: 20),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      dropdownColor: _DS.surface,
      menuMaxHeight: 300,
      borderRadius: BorderRadius.circular(_DS.radius),
      icon: const Icon(Icons.unfold_more_rounded, color: _DS.textMuted, size: 20),
      style: const TextStyle(color: _DS.textPrimary, fontSize: 15),
      selectedItemBuilder: selectedItemBuilder != null ? (_) => selectedItemBuilder : null,
      items: items,
      onChanged: onChanged,
    ),
  );
}

Widget _emptyState({required IconData icon, required String title, required String subtitle}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _DS.accentSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: _DS.accent),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _DS.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: _DS.textMuted),
          ),
        ],
      ),
    ),
  );
}

// ─── MAIN VIEW ────────────────────────────────────────────────────────────────
class SchoolManagementView extends StatefulWidget {
  SchoolManagementView({super.key});

  @override
  State<SchoolManagementView> createState() => _SchoolManagementViewState();
}

class _SchoolManagementViewState extends State<SchoolManagementView> {
  late SchoolController controller;
  late UserManagementController userController;
  late MarksController marksController;
  Worker? _schoolWatcher;

  @override
  void initState() {
    super.initState();
    controller = Get.find<SchoolController>();
    userController = Get.put(UserManagementController());
    marksController = Get.put(MarksController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.getAllSchools();
      _initializeSchoolForUser();
    });
    _schoolWatcher = ever(controller.selectedSchool, (school) {
      if (school == null) return;
      controller.getAllClasses(school.id);
      controller.getAllSections(schoolId: school.id);
      controller.getAllStudents(schoolId: school.id);
      userController.loadUsers(
        schoolId: school.id,
        role: userController.selectedRole.value,
      );
    });
  }

  @override
  void dispose() {
    _schoolWatcher?.dispose();
    super.dispose();
  }

  void _initializeSchoolForUser() {
    final authController = Get.find<AuthController>();
    final userSchoolId = authController.user.value?.schoolId;
    if (userSchoolId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final userSchool = controller.schools.firstWhereOrNull(
          (school) => school.id == userSchoolId,
        );
        if (userSchool != null) {
          controller.selectedSchool.value = userSchool;
        } else {
          controller.getAllSchools().then((_) {
            final school = controller.schools.firstWhereOrNull(
              (s) => s.id == userSchoolId,
            );
            if (school != null) controller.selectedSchool.value = school;
          });
        }
      });
    }
  }

  bool canCreateUser(String role) => role == 'correspondent';
  bool canDeleteUser(String role) => role == 'correspondent';
  bool canEditUser(String role) =>
      ['correspondent', 'teacher', 'principal', 'administrator', 'viceprincipal']
          .contains(role);
  bool canAssignRole(String role) => ['correspondent', 'administrator'].contains(role);
  bool canCreateSchool(String role) => role == 'correspondent';
  bool canEditSchool(String role) => role == 'correspondent';
  bool canDeleteSchool(String role) => role == 'correspondent';
  bool canUpdateSchoolLogo(String role) => role == 'correspondent';
  bool canCreateClass(String role) => ['correspondent', 'administrator'].contains(role);
  bool canEditClass(String role) => ['correspondent', 'administrator'].contains(role);
  bool canDeleteClass(String role) => ['correspondent', 'administrator'].contains(role);
  bool canCreateSection(String role) => ['correspondent', 'administrator'].contains(role);
  bool canEditSection(String role) => ['correspondent', 'administrator'].contains(role);
  bool canDeleteSection(String role) => role == 'correspondent';
  bool canCreateStudent(String role) => ['correspondent', 'administrator', 'accountant'].contains(role);
  bool canEditStudent(String role) => ['correspondent', 'administrator', 'accountant'].contains(role);
  bool canDeleteStudent(String role) => role == 'correspondent';

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'correspondent':
        return Icons.admin_panel_settings;
      case 'teacher':
        return Icons.school;
      case 'principal':
        return Icons.account_balance;
      case 'viceprincipal':
        return Icons.supervisor_account;
      case 'administrator':
        return Icons.settings;
      case 'accountant':
        return Icons.calculate;
      case 'parent':
        return Icons.family_restroom;
      default:
        return Icons.person;
    }
  }

  int get initialTab {
    final tabParam = Get.parameters['initialTab'] ?? Get.arguments?['initialTab'];
    if (tabParam == null) return 0;
    final tabName = tabParam.toString().toLowerCase();
    final tabs = availableTabs;
    final tabIndex = tabs.indexWhere((t) => (t['title'] as String).toLowerCase() == tabName);
    if (tabIndex >= 0) return tabIndex;
    return int.tryParse(tabParam.toString()) ?? 0;
  }

  int getAdjustedInitialTab(List<Map<String, dynamic>> tabs) {
    if (tabs.isEmpty) return 0;
    if (initialTab == 0) return 0;
    return initialTab < tabs.length ? initialTab : 0;
  }

  List<Map<String, dynamic>> get availableTabs {
    final authController = Get.find<AuthController>();
    final currentUserRole = authController.user.value?.role?.toLowerCase() ?? '';
    return [
      if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/school/create') ||
          ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/school/update') ||
          ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/school/delete') ||
          ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/school/updatelogo'))
        {'title': 'Schools', 'icon': Icons.school, 'builder': _buildSchoolsTab},
      if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/class/create') ||
          ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/class/update') ||
          ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/class/delete'))
        {'title': 'Classes', 'icon': Icons.class_, 'builder': _buildClassesTab},
      if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/section/create') ||
          ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/section/update') ||
          ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/section/delete'))
        {'title': 'Sections', 'icon': Icons.group, 'builder': _buildSectionsTab},
      if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/student/create') ||
          ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/student/update') ||
          ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/student/delete'))
        {'title': 'Students', 'icon': Icons.people, 'builder': _buildStudentsTab},
      if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/user/create'))
        {'title': 'Users', 'icon': Icons.person, 'builder': _buildUsersTab},
      if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/teacher/assignments/manage'))
        {'title': 'Teachers', 'icon': Icons.assignment_ind, 'builder': _buildTeacherAssignmentTab},
      if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/feestructure/set') ||
          ApiPermissions.hasApiAccess(currentUserRole, 'GET /api/feestructure/getbyclass'))
        {'title': 'Fees', 'icon': Icons.payment, 'builder': _buildFeeStructureTab},
      if (ApiPermissions.hasApiAccess(currentUserRole, 'GET /api/attendance/sheet') ||
          ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/attendance/mark') ||
          ApiPermissions.hasApiAccess(currentUserRole, 'GET /api/attendance/getallclass'))
        {'title': 'Attendance', 'icon': Icons.how_to_reg, 'builder': _buildAttendanceTab},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tabs = availableTabs;
    if (tabs.isEmpty) {
      return PopScope(
        canPop: true,
        child: Scaffold(
          backgroundColor: _DS.bg,
          appBar: _buildAppBar(context),
          body: _emptyState(
            icon: Icons.lock_outline_rounded,
            title: 'No Management Access',
            subtitle: 'No management options available for your role',
          ),
        ),
      );
    }
    final adjustedInitialTab = getAdjustedInitialTab(tabs);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Get.back();
      },
      child: DefaultTabController(
        length: tabs.length,
        initialIndex: adjustedInitialTab,
        child: Scaffold(
          backgroundColor: _DS.bg,
          appBar: _buildAppBar(context),
          body: Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                decoration: BoxDecoration(
                  color: _DS.surface,
                  borderRadius: BorderRadius.circular(_DS.radiusLg),
                  border: Border.all(color: _DS.border),
                  boxShadow: _DS.shadow,
                ),
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  padding: const EdgeInsets.all(5),
                  indicator: BoxDecoration(
                    color: _DS.accent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _DS.accent.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: _DS.textSecondary,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  tabs: tabs.map((tab) => Tab(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(tab['icon'] as IconData, size: 16),
                          const SizedBox(width: 6),
                          Text(tab['title'] as String),
                        ],
                      ),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ResponsiveWrapper(
                  child: TabBarView(
                    children: tabs.map((tab) => (tab['builder'] as Widget Function())()).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(68),
      child: SafeArea(
        bottom: false,
        child: Container(
          decoration: BoxDecoration(
            color: _DS.surface,
            border: const Border(bottom: BorderSide(color: _DS.border)),
            boxShadow: _DS.shadow,
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            title: Row(
              children: [
                _buildSchoolLogo(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Obx(() {
                        final school = controller.selectedSchool.value;
                        String name;
                        if (school is School) name = school.name;
                        else if (school is Map) name = school?['name'] ?? 'School Management';
                        else name = 'School Management';
                        return Text(
                          name,
                          style: const TextStyle(
                            color: _DS.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        );
                      }),
                      const Text(
                        'Management Portal',
                        style: TextStyle(
                            color: _DS.textMuted, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: _showFullScreenProfileImage,
                  child: Obx(() {
                    final auth = Get.find<AuthController>();
                    final name = auth.user.value?.userName ?? 'U';
                    return Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_DS.accent, _DS.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: _DS.accentMid, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSchoolLogo() {
    try {
      final authController = Get.find<AuthController>();
      final school = authController.userSchool.value;
      if (school != null && school['logo']?['url'] != null) {
        return GestureDetector(
          onTap: () => _showFullScreenSchoolLogo(school['logo']['url']),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_DS.radiusSm),
              border: Border.all(color: _DS.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_DS.radiusSm),
              child: Image.network(
                school['logo']['url'],
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.school, color: _DS.accent, size: 24),
              ),
            ),
          ),
        );
      }
    } catch (_) {}
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _DS.accentSoft,
        borderRadius: BorderRadius.circular(_DS.radiusSm),
      ),
      child: const Icon(Icons.school, color: _DS.accent, size: 22),
    );
  }

  void _showFullScreenProfileImage() {
    final authController = Get.find<AuthController>();
    final userName = authController.user.value?.userName ?? 'U';
    Get.dialog(Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(children: [
        Center(
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_DS.accent, _DS.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: _DS.shadowMd,
            ),
            child: Center(
              child: Text(
                userName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800, fontSize: 90),
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
                boxShadow: _DS.shadow,
              ),
              child: const Icon(Icons.close, size: 20, color: _DS.textPrimary),
            ),
          ),
        ),
      ]),
    ));
  }

  void _showFullScreenSchoolLogo(String logoUrl) {
    Get.dialog(Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(children: [
        GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black87,
            child: Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  logoUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) {
                    Get.back();
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
              color: Colors.black54,
              borderRadius: BorderRadius.circular(100),
            ),
            child: IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.close, color: Colors.white, size: 22),
            ),
          ),
        ),
      ]),
    ));
  }

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

  Widget _buildSchoolsTab() {
    final authController = Get.find<AuthController>();
    final currentUserRole = authController.user.value?.role?.toLowerCase() ?? '';
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: _DS.accent));
        }
        return RefreshIndicator(
          onRefresh: controller.refreshSchools,
          color: _DS.accent,
          child: controller.schools.isEmpty
              ? _emptyState(
                  icon: Icons.school_outlined,
                  title: 'No Schools Yet',
                  subtitle: 'Create your first school to get started')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: controller.schools.length,
                  itemBuilder: (context, index) =>
                      _buildSchoolCard(controller.schools[index], currentUserRole),
                ),
        );
      }),
      floatingActionButton: ApiPermissions.hasApiAccess(
              currentUserRole, 'POST /api/school/create')
          ? _buildFAB(
              onPressed: () => Get.toNamed('/create-school'),
              icon: Icons.add_rounded,
              label: 'Add School')
          : null,
    );
  }

  Widget _buildSchoolCard(School school, String currentUserRole) {
    return _card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _DS.accentSoft,
                  borderRadius: BorderRadius.circular(_DS.radiusSm),
                  border: Border.all(color: _DS.accentMid),
                ),
                child: school.logo?['url'] != null && school.logo!['url']!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(_DS.radiusSm),
                        child: Image.network(
                          school.logo!['url']!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.school, color: _DS.accent, size: 24),
                        ),
                      )
                    : const Icon(Icons.school, color: _DS.accent, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      school.name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700, color: _DS.textPrimary),
                    ),
                    if (school.schoolCode != null)
                      Text('Code: ${school.schoolCode}',
                          style: const TextStyle(fontSize: 12, color: _DS.textMuted)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz_rounded, color: _DS.textMuted, size: 22),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radius)),
                elevation: 3,
                itemBuilder: (context) => [
                  if (ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/school/update'))
                    _menuItem('edit', Icons.edit_rounded, 'Edit'),
                  if (ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/school/updatelogo'))
                    _menuItem('logo', Icons.image_rounded, 'Update Logo'),
                  if (ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/school/delete'))
                    _menuItem('delete', Icons.delete_rounded, 'Delete', danger: true),
                ],
                onSelected: (value) {
                  if (value == 'edit') controller.showEditSchoolDialog(school);
                  else if (value == 'logo') controller.pickAndUploadLogo(school.id);
                  else if (value == 'delete') _showDeleteConfirmation(school);
                },
              ),
            ],
          ),
          if (school.email != null ||
              school.phoneNo != null ||
              school.currentAcademicYear != null ||
              school.address != null) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: _DS.border),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (school.email != null) _infoChip(Icons.email_rounded, school.email!),
                if (school.phoneNo != null) _infoChip(Icons.phone_rounded, school.phoneNo!),
                if (school.currentAcademicYear != null)
                  _infoChip(Icons.calendar_today_rounded, school.currentAcademicYear!),
                if (school.address != null)
                  _infoChip(Icons.location_on_rounded, school.address!),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _DS.surfaceAlt,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: _DS.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _DS.accent),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 12, color: _DS.textSecondary, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassesTab() {
    final authController = Get.find<AuthController>();
    final currentUserRole = authController.user.value?.role?.toLowerCase() ?? '';
    final isCorrespondent = currentUserRole == 'correspondent';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.schools.isEmpty) {
        controller.getAllSchools();
      }
      if (controller.selectedSchool.value != null) {
        controller.getAllClasses(controller.selectedSchool.value!.id);
      }
    });
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _compactCard(
            child: Obx(() {
              if (controller.schools.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              final selectedSchool = controller.schools.contains(controller.selectedSchool.value)
                  ? controller.selectedSchool.value
                  : null;
              if (isCorrespondent) {
                return DropdownButtonFormField<School>(
                  isExpanded: true,
                  decoration: InputDecoration(
                    hintText: 'Choose School',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[700]!.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.school, color: Colors.blue[700], size: 20),
                    ),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  value: selectedSchool,
                  selectedItemBuilder: (context) {
                    return controller.schools.map((school) {
                      return Text(
                        school.name,
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      );
                    }).toList();
                  },
                  items: controller.schools.map((school) {
                    return DropdownMenuItem<School>(
                      value: school,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.blue[700]!.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(Icons.school, color: Colors.blue[700], size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                school.name,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (School? school) {
                    controller.selectedSchool.value = school;
                    if (school != null) {
                      controller.getAllClasses(school.id);
                    } else {
                      controller.classes.clear();
                    }
                  },
                );
              } else {
                if (controller.selectedSchool.value != null && controller.classes.isEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    controller.getAllClasses(controller.selectedSchool.value!.id);
                  });
                }
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[700]!.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.school, color: Colors.blue[700], size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          controller.selectedSchool.value?.name ?? 'Loading...',
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
            }),
          ),
          if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/class/create'))
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showCreateClassDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Class'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.classes.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.class_,
                  title: 'No Classes Found',
                  subtitle: 'Add classes to organize your students',
                );
              }
              final sortedClasses = ClassUtils.sortClasses(controller.classes);
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: sortedClasses.length,
                itemBuilder: (context, index) {
                  final schoolClass = sortedClasses[index];
                  return _buildClassCard(schoolClass, currentUserRole, index);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(SchoolClass schoolClass, String currentUserRole, int index) {
    return _card(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _iconBox(Icons.class_rounded),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              schoolClass.name,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: _DS.textPrimary),
            ),
          ),
          if (schoolClass.hasSections)
            _badge('Has Sections', bg: _DS.successSoft, fg: _DS.success),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz_rounded, color: _DS.textMuted, size: 22),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radius)),
            itemBuilder: (context) => [
              if (ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/class/update'))
                _menuItem('edit', Icons.edit_rounded, 'Edit'),
              if (ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/class/delete'))
                _menuItem('delete', Icons.delete_rounded, 'Delete', danger: true),
            ],
            onSelected: (value) {
              if (value == 'edit') _showEditClassDialog(schoolClass);
              else if (value == 'delete')
                controller.deleteClass(schoolClass.id).then((_) {
                  if (controller.selectedSchool.value != null)
                    controller.getAllClasses(controller.selectedSchool.value!.id);
                });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionsTab() {
    final authController = Get.find<AuthController>();
    final currentUserRole = authController.user.value?.role?.toLowerCase() ?? '';
    final isCorrespondent = currentUserRole == 'correspondent';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.schools.isEmpty) {
        controller.getAllSchools();
      }
      if (controller.selectedSchool.value != null) {
        controller.getAllSections(schoolId: controller.selectedSchool.value!.id);
      }
    });
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _compactCard(
            child: Obx(() {
              if (controller.schools.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (isCorrespondent) {
                return DropdownButtonFormField<School>(
                  isExpanded: true,
                  decoration: InputDecoration(
                    hintText: 'Choose School',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[700]!.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.school, color: Colors.blue[700], size: 20),
                    ),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  value: controller.selectedSchool.value,
                  selectedItemBuilder: (context) {
                    return controller.schools.map((school) {
                      return Text(
                        school.name,
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      );
                    }).toList();
                  },
                  items: controller.schools.isEmpty
                      ? []
                      : controller.schools.map<DropdownMenuItem<School>>((school) {
                          return DropdownMenuItem<School>(
                            value: school,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[700]!.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(Icons.school, color: Colors.blue[700], size: 16),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    school.name,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                  onChanged: (School? school) {
                    controller.selectedSchool.value = school;
                    if (school != null) {
                      controller.getAllSections(schoolId: school.id);
                    }
                  },
                );
              } else {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[700]!.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.school, color: Colors.blue[700], size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          controller.selectedSchool.value?.name ?? 'Loading...',
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
            }),
          ),
          if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/section/create'))
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showCreateSectionDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Section'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF667eea)));
              }
              if (controller.sections.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.group,
                  title: 'No Sections Found',
                  subtitle: 'Add sections to organize classes better',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: controller.sections.length,
                itemBuilder: (context, index) {
                  final section = controller.sections[index];
                  return _compactCard(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue[400]!.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.group, color: Colors.blue[400], size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                section.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryText,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Class: ${section.className ?? "N/A"}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.mutedText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Room: ${section.roomNumber ?? "N/A"}',
                                style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
                              ),
                              if (section.classTeachers != null &&
                                  section.classTeachers!.isNotEmpty)
                                Text(
                                  'Teachers: ${section.classTeachers!.map((t) => t['userName'] ?? 'Unknown').join(', ')}',
                                  style: TextStyle(fontSize: 11, color: Colors.blue[600]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'view',
                              child: Row(children: [
                                Icon(Icons.visibility, size: 18),
                                SizedBox(width: 8),
                                Text('View Details'),
                              ]),
                            ),
                            if (ApiPermissions.hasApiAccess(
                                currentUserRole, 'PUT /api/section/update'))
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(children: [
                                  Icon(Icons.edit, size: 18),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ]),
                              ),
                            if (ApiPermissions.hasApiAccess(
                                currentUserRole, 'DELETE /api/section/delete'))
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(children: [
                                  Icon(Icons.delete, size: 18, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ]),
                              ),
                          ],
                          onSelected: (value) {
                            if (value == 'view') {
                              _showSectionDetailsDialog(context, section);
                            } else if (value == 'edit') {
                              _showEditSectionDialog(section);
                            } else if (value == 'delete') {
                              controller.deleteSection(section.id).then((_) {
                                if (controller.selectedSchool.value != null) {
                                  controller.getAllSections(
                                      schoolId: controller.selectedSchool.value!.id);
                                }
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsTab() {
    final authController = Get.find<AuthController>();
    final currentUserRole = authController.user.value?.role?.toLowerCase() ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.selectedSchool.value != null)
        controller.getAllStudents(schoolId: controller.selectedSchool.value!.id);
    });
    final selectedClass = Rxn<SchoolClass>();
    final selectedSection = Rxn<Section>();
    final isFiltersExpanded = true.obs;
    final clubsController = Get.put(ClubController());
    final clubController = Get.put(ClubsController());
    final canManageClubs =
        ['correspondent', 'administrator'].contains(currentUserRole);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Obx(() {
              final hasSelections = controller.selectedSchool.value != null;
              final isExpanded = !hasSelections || isFiltersExpanded.value;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                child: isExpanded
                    ? _card(
                        padding: const EdgeInsets.all(16),
                        child: _buildFullStudentFilters(
                            selectedClass, selectedSection, isFiltersExpanded))
                    : _card(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: _buildCompactStudentFilters(
                            selectedClass, selectedSection, isFiltersExpanded)),
              );
            }),
          ),
          if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/student/create'))
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showCreateStudentDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Student'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          if (canManageClubs)
            Obx(() {
              final students = controller.students;
              return students.isNotEmpty
                  ? Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final studentsToShow = students.toList();
                          if (studentsToShow.isEmpty) return;
                          final studentsByClass = <String, List<Student>>{};
                          for (final student in studentsToShow) {
                            final classId = student.classId ?? '';
                            if (classId.isNotEmpty) {
                              studentsByClass.putIfAbsent(classId, () => []).add(student);
                            }
                          }
                          if (studentsByClass.isEmpty) {
                            Get.snackbar('Error', 'No students with valid class information');
                            return;
                          }
                          if (studentsByClass.length > 1) {
                            _showClassSelectionForBulkClub(studentsByClass);
                          } else {
                            final classId = studentsByClass.keys.first;
                            final classObj = controller.classes.firstWhereOrNull((c) => c.id == classId);
                            if (classObj != null) {
                              _showBulkClubDialog(studentsByClass[classId]!, classObj);
                            }
                          }
                        },
                        icon: const Icon(Icons.group_add, size: 18),
                        label: Text('Add ${students.length} students to clubs'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink();
            }),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF667eea)));
              }
              final studentsToShow = controller.students;
              if (studentsToShow.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.people,
                  title: 'No Students Found',
                  subtitle: controller.selectedSchool.value == null
                      ? 'Select a school to view students'
                      : 'No students found',
                );
              }
              final sorted = List<Student>.from(studentsToShow)
                ..sort((a, b) => (a.name ?? '').toLowerCase()
                    .compareTo((b.name ?? '').toLowerCase()));
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: sorted.length,
                itemBuilder: (context, i) =>
                    _buildStudentCard(sorted[i], currentUserRole, canManageClubs),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Student student, String currentUserRole, bool canManageClubs) {
    return _card(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(_DS.radiusSm),
            ),
            child: Center(
              child: Text(
                (student.name ?? 'U').substring(0, 1).toUpperCase(),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name ?? 'N/A',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: _DS.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                    (student.rollNumber == null || student.rollNumber!.trim().isEmpty)
                        ? 'No roll number'
                        : 'Roll: ${student.rollNumber}',
                    style: const TextStyle(fontSize: 12, color: _DS.textMuted)),
              ],
            ),
          ),
          if (canManageClubs) ...[
            SizedBox(
              width: 72,
              height: 32,
              child: ElevatedButton(
                onPressed: () {
                  final studentClassId = student.classId;
                  if (studentClassId == null || studentClassId.isEmpty) {
                    Get.snackbar('Error', 'Student has no class assigned');
                    return;
                  }
                  final studentClass = controller.classes
                      .firstWhereOrNull((c) => c.id == studentClassId);
                  if (studentClass == null) {
                    Get.snackbar('Error', 'Student class not found');
                    return;
                  }
                  _showStudentClubDialog(student, studentClass);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _DS.successSoft,
                  foregroundColor: _DS.success,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_DS.radiusSm)),
                ),
                child: const Text(
                  '+ Club',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz_rounded, color: _DS.textMuted, size: 22),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radius)),
            itemBuilder: (context) => [
              _menuItem('details', Icons.visibility_rounded, 'View Details'),
              if (ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/student/update'))
                _menuItem('edit', Icons.edit_rounded, 'Edit'),
              if (ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/club/addtoclub'))
                _menuItem('assignClub', Icons.add_circle_rounded, 'Assign Club'),
              if (ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/club/removefromclub'))
                _menuItem('removeClub', Icons.remove_circle_rounded, 'Remove Club', danger: true),
              if (ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/student/delete'))
                _menuItem('delete', Icons.delete_rounded, 'Delete', danger: true),
            ],
            onSelected: (value) {
              if (value == 'details')
                Get.to(() => StudentIndividualDetailView(
                    student: student,
                    schoolId: controller.selectedSchool.value!.id))?.then((_) {
                  if (controller.selectedSchool.value != null)
                    controller.getAllStudents(schoolId: controller.selectedSchool.value!.id);
                });
              else if (value == 'assignClub') _showAssignClubToStudentDialog(student);
              else if (value == 'removeClub') _showRemoveClubFromStudentDialog(student);
              else if (value == 'edit') _showEditStudentDialog(student);
              else if (value == 'delete') _showDeleteStudentConfirmation(student);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStudentFilters(
      Rxn<SchoolClass> selectedClass, Rxn<Section> selectedSection, RxBool isFiltersExpanded) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.school, color: Colors.blue[700], size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              controller.selectedSchool.value?.name ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (selectedClass.value != null) ...[
            const SizedBox(width: 12),
            Icon(Icons.class_, color: Colors.blue[700], size: 18),
            const SizedBox(width: 6),
            Text(
              selectedClass.value!.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ],
          if (selectedSection.value != null) ...[
            const SizedBox(width: 12),
            Icon(Icons.group, color: Colors.blue[700], size: 18),
            const SizedBox(width: 6),
            Text(
              selectedSection.value!.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ],
          const Spacer(),
          IconButton(
            onPressed: () => isFiltersExpanded.value = true,
            icon: const Icon(Icons.expand_more, size: 18),
            tooltip: 'Expand Filters',
          ),
        ],
      ),
    );
  }

  Widget _buildFullStudentFilters(
      Rxn<SchoolClass> selectedClass, Rxn<Section> selectedSection, RxBool isFiltersExpanded) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Filters',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue[700],
                ),
              ),
              const Spacer(),
              if (controller.selectedSchool.value != null)
                IconButton(
                  onPressed: () => isFiltersExpanded.value = false,
                  icon: const Icon(Icons.expand_less, size: 20),
                  tooltip: 'Collapse Filters',
                ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() {
            final authController = Get.find<AuthController>();
            final currentUserRole = authController.user.value?.role?.toLowerCase() ?? '';
            final isCorrespondent = currentUserRole == 'correspondent';
            if (isCorrespondent) {
              return DropdownButtonFormField<School>(
                isExpanded: true,
                decoration: InputDecoration(
                  hintText: 'Choose School',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[700]!.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.school, color: Colors.blue[700], size: 20),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                value: controller.selectedSchool.value,
                selectedItemBuilder: (context) {
                  return controller.schools.map((school) {
                    return Text(
                      school.name,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    );
                  }).toList();
                },
                items: controller.schools.map((school) {
                  return DropdownMenuItem<School>(
                    value: school,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.blue[700]!.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(Icons.school, color: Colors.blue[700], size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              school.name,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (School? school) {
                  controller.selectedSchool.value = school;
                  selectedClass.value = null;
                  selectedSection.value = null;
                  if (school != null) {
                    controller.getAllClasses(school.id);
                  }
                },
              );
            } else {
              if (controller.selectedSchool.value != null && controller.sections.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  controller.getAllSections(schoolId: controller.selectedSchool.value!.id);
                });
              }
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[700]!.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.school, color: Colors.blue[700], size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        controller.selectedSchool.value?.name ?? 'Loading...',
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          }),
          const SizedBox(height: 12),
          Obx(() {
            final sortedClasses = ClassUtils.sortClasses(controller.classes);
            final uniqueClasses = <SchoolClass>[];
            final seenIds = <String>{};
            for (final cls in sortedClasses) {
              if (!seenIds.contains(cls.id)) {
                seenIds.add(cls.id);
                uniqueClasses.add(cls);
              }
            }
            return DropdownButtonFormField<SchoolClass>(
              isExpanded: true,
              decoration: InputDecoration(
                hintText: 'Choose Class (Optional)',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[700]!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.class_, color: Colors.blue[700], size: 20),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              value: selectedClass.value,
              selectedItemBuilder: (context) {
                return [
                  Row(
                    children: [
                      Icon(Icons.all_inclusive, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      const Text('All Classes'),
                    ],
                  ),
                  ...uniqueClasses.map((cls) {
                    return Row(
                      children: [
                        Icon(ClassUtils.getClassIcon(cls.name), size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          cls.name,
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    );
                  }),
                ];
              },
              items: [
                DropdownMenuItem<SchoolClass>(
                  value: null,
                  child: Row(
                    children: [
                      Icon(Icons.all_inclusive, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'All Classes',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                ...uniqueClasses.map((cls) {
                  return DropdownMenuItem<SchoolClass>(
                    value: cls,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.blue[700]!.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(ClassUtils.getClassIcon(cls.name),
                                color: Colors.blue[700], size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              cls.name,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
              onChanged: (SchoolClass? cls) {
                selectedClass.value = cls;
                selectedSection.value = null;
                if (cls != null && controller.selectedSchool.value != null) {
                  controller.getAllSections(
                    classId: cls.id,
                    schoolId: controller.selectedSchool.value!.id,
                  );
                }
                _loadStudentsByFilters(selectedClass.value, selectedSection.value);
              },
            );
          }),
          const SizedBox(height: 12),
          Obx(() => DropdownButtonFormField<Section>(
                isExpanded: true,
                decoration: InputDecoration(
                  hintText: 'Choose Section (Optional)',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[700]!.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.group, color: Colors.blue[700], size: 20),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                value: selectedSection.value,
                selectedItemBuilder: (context) {
                  return [
                    Text(
                      'All Sections',
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    ...controller.sections.map((section) {
                      return Text(
                        section.name,
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      );
                    }),
                  ];
                },
                items: [
                  DropdownMenuItem<Section>(
                    value: null,
                    child: Text(
                      'All Sections',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  ...controller.sections.map((section) {
                    return DropdownMenuItem<Section>(
                      value: section,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.blue[700]!.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(Icons.group, color: Colors.blue[700], size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                section.name,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
                onChanged: (Section? section) {
                  selectedSection.value = section;
                  _loadStudentsByFilters(selectedClass.value, selectedSection.value);
                },
              )),
        ],
      ),
    );
  }

  void _loadStudentsByFilters(SchoolClass? selectedClass, Section? selectedSection) {
    if (controller.selectedSchool.value == null) return;
    controller.getAllStudents(
      schoolId: controller.selectedSchool.value!.id,
      classId: selectedClass?.id,
      sectionId: selectedSection?.id,
    ).then((_) => print('📋 Students loaded: ${controller.students.length}'));
  }

  Widget _buildUsersTab() {
    final authController = Get.find<AuthController>();
    final currentUserRole = authController.user.value?.role?.toLowerCase() ?? '';
    final isReadOnly = !['correspondent'].contains(currentUserRole);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _compactCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                if (isReadOnly)
                  Obx(() {
                    final userSchoolId = authController.user.value?.schoolId;
                    final userSchool = controller.schools.firstWhereOrNull(
                      (school) => school.id == userSchoolId,
                    );
                    final schoolName = controller.selectedSchool.value?.name ??
                        userSchool?.name ??
                        'Loading...';
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue[700]!.withOpacity(0.05),
                            Colors.blue[700]!.withOpacity(0.02)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.blue[700]!.withOpacity(0.2),
                          width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                Colors.blue[700]!,
                                Colors.blue[500]!
                              ]),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.business, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              schoolName,
                              style: TextStyle(
                                color: AppTheme.primaryText,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  })
                else
                  Obx(() => DropdownButtonFormField<School>(
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: 'Choose School',
                          hintStyle: TextStyle(color: Colors.grey.shade600),
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue[700]!.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.school, color: Colors.blue[700], size: 20),
                          ),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        value: controller.selectedSchool.value,
                        selectedItemBuilder: (context) {
                          return controller.schools.map((school) {
                            return Text(
                              school.name,
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            );
                          }).toList();
                        },
                        items: controller.schools
                            .map((school) => DropdownMenuItem<School>(
                                  value: school,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[700]!
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Icon(Icons.school,
                                              color: Colors.blue[700], size: 16),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          school.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ))
                            .toList(),
                        onChanged: (school) {
                          controller.selectedSchool.value = school;
                          if (school != null) {
                            userController.loadUsers(
                              schoolId: school.id,
                              role: userController.selectedRole.value,
                            );
                          }
                        },
                      )),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(16),
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
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue[700]!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.filter_list, color: Colors.blue[700], size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    value: userController.selectedRole.value,
                    selectedItemBuilder: (context) {
                      return const [
                        'all',
                        'correspondent',
                        'teacher',
                        'principal',
                        'viceprincipal',
                        'administrator',
                        'accountant',
                        'parent'
                      ].map((r) {
                        return Text(
                          r.toUpperCase(),
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        );
                      }).toList();
                    },
                    items: const [
                      'all',
                      'correspondent',
                      'teacher',
                      'principal',
                      'viceprincipal',
                      'administrator',
                      'accountant',
                      'parent'
                    ].map((r) {
                      return DropdownMenuItem<String>(
                        value: r,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.blue[700]!.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(_getRoleIcon(r), color: Colors.blue[700], size: 16),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                r.toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (role) {
                      if (role != null) {
                        userController.selectedRole.value = role;
                        final schoolId = controller.selectedSchool.value?.id ??
                            authController.user.value?.schoolId;
                        if (schoolId != null) {
                          userController.loadUsers(schoolId: schoolId, role: role);
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (userController.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF667eea)));
              }
              if (userController.users.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.person,
                  title: 'No Users Found',
                  subtitle: 'Add users to manage your school',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: userController.users.length,
                itemBuilder: (context, index) {
                  final user = userController.users[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Get.to(() => UserDetailView(user: user));
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getRoleIcon(user['role'] ?? 'person'),
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user['userName'] ?? 'Unknown',
                                      style: const TextStyle(
                                        color: AppTheme.titleOnWhite,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Role: ${user['role'] ?? 'No Role'}',
                                      style: const TextStyle(color: AppTheme.subtitleOnWhite, fontSize: 14),
                                    ),
                                    Text(
                                      'Email: ${user['email'] ?? 'N/A'}',
                                      style: const TextStyle(color: AppTheme.mutedText, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              if (user['role'] == null &&
                                  ['correspondent', 'administrator']
                                      .contains(currentUserRole) &&
                                  ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/user/assignrole'))
                                SizedBox(
                                  width: 100,
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    child: ElevatedButton(
                                      onPressed: () => _showAssignRoleDialog(user),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryBlue,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('Assign Role', style: TextStyle(fontSize: 12)),
                                    ),
                                  ),
                                ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: AppTheme.primaryText),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                itemBuilder: (context) => [
                                  if (ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/user/update') && currentUserRole != 'teacher')
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 18),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                  if (ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/user/assignrole') &&
                                      ['correspondent', 'administrator'].contains(currentUserRole))
                                    const PopupMenuItem(
                                      value: 'role',
                                      child: Row(
                                        children: [
                                          Icon(Icons.admin_panel_settings, size: 18),
                                          SizedBox(width: 8),
                                          Text('Change Role'),
                                        ],
                                      ),
                                    ),
                                  if (ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/user/delete'))
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, size: 18, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Delete', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                ],
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditUserDialog(user);
                                  } else if (value == 'role') {
                                    _showAssignRoleDialog(user);
                                  } else if (value == 'delete') {
                                    _showDeleteUserDialog(user);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/user/create')
          ? _buildFloatingActionButton(
              onPressed: _showCreateUserDialog,
              icon: Icons.person_add,
              label: 'Add User',
            )
          : null,
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: AppTheme.primaryBlue,
      foregroundColor: AppTheme.titleOnGradient,
      elevation: 4,
      icon: Icon(icon),
      label: Text(label),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, String currentUserRole) {
    final role = user['role'] ?? '';
    return _card(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_DS.primaryLight, _DS.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(_DS.radiusSm),
            ),
            child: Icon(_getRoleIcon(role), color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['userName'] ?? 'Unknown',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: _DS.textPrimary),
                ),
                const SizedBox(height: 2),
                if (role.isNotEmpty)
                  _badge(role.toUpperCase(), bg: _DS.accentSoft, fg: _DS.accent),
                const SizedBox(height: 2),
                Text(
                  user['email'] ?? 'N/A',
                  style: const TextStyle(fontSize: 12, color: _DS.textMuted),
                ),
              ],
            ),
          ),
          if (user['role'] == null &&
              ['correspondent', 'administrator'].contains(currentUserRole) &&
              ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/user/assignrole'))
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: TextButton(
                onPressed: () => _showAssignRoleDialog(user),
                style: TextButton.styleFrom(
                  foregroundColor: _DS.accent,
                  backgroundColor: _DS.accentSoft,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_DS.radiusSm)),
                ),
                child: const Text('Assign Role',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz_rounded, color: _DS.textMuted, size: 22),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radius)),
            itemBuilder: (context) => [
              if (ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/user/update') &&
                  currentUserRole != 'teacher')
                _menuItem('edit', Icons.edit_rounded, 'Edit'),
              if (ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/user/assignrole') &&
                  ['correspondent', 'administrator'].contains(currentUserRole))
                _menuItem('role', Icons.admin_panel_settings_rounded, 'Change Role'),
              if (ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/user/delete'))
                _menuItem('delete', Icons.delete_rounded, 'Delete', danger: true),
            ],
            onSelected: (value) {
              if (value == 'edit') _showEditUserDialog(user);
              else if (value == 'role') _showAssignRoleDialog(user);
              else if (value == 'delete') _showDeleteUserDialog(user);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherAssignmentTab() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.selectedSchool.value != null) {
        print('🏫 Loading teachers for school: ${controller.selectedSchool.value!.name}');
        controller.loadTeachers();
      }
    });
    return TeacherAssignmentView();
  }

  Widget _buildFeeStructureTab() {
    final authController = Get.find<AuthController>();
    final currentUserRole = authController.user.value?.role?.toLowerCase() ?? '';
    final canSetFeeStructure =
        ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/feestructure/set');
    return DefaultTabController(
      length: canSetFeeStructure ? 2 : 1,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            if (canSetFeeStructure)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: _card(
                  padding: const EdgeInsets.all(6),
                  child: TabBar(
                    indicator: BoxDecoration(
                      color: _DS.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: _DS.textSecondary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    tabs: const [
                      Tab(
                          child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('Set Fee'),
                        ],
                      )),
                      Tab(
                          child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.list_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('All Fees'),
                        ],
                      )),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: canSetFeeStructure
                  ? TabBarView(children: [_FeeStructureTab(), AllFeeStructuresTab()])
                  : AllFeeStructuresTab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceTab() => SingleChildScrollView(child: _AttendanceTab());

  Widget _readonlySchoolChip({String? name}) {
    return Obx(() {
      final n = name ?? controller.selectedSchool.value?.name ?? 'Loading...';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _DS.surfaceAlt,
          borderRadius: BorderRadius.circular(_DS.radiusSm),
          border: Border.all(color: _DS.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.school_rounded, color: _DS.accent, size: 20),
            const SizedBox(width: 12),
            Expanded(
                child: Text(
              n,
              style: const TextStyle(
                  fontSize: 15, color: _DS.textPrimary, fontWeight: FontWeight.w500),
            )),
            _badge('Your School', bg: _DS.accentSoft, fg: _DS.accent),
          ],
        ),
      );
    });
  }

  Widget _dropdownItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _DS.accentSoft, borderRadius: BorderRadius.circular(6)),
          child: Icon(icon, color: _DS.accent, size: 15),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
                fontWeight: FontWeight.w500, fontSize: 14, color: _DS.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label,
      {bool danger = false}) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: danger ? _DS.danger : _DS.textSecondary,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: danger ? _DS.danger : _DS.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: _DS.primary,
      foregroundColor: Colors.white,
      elevation: 3,
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  void _showDeleteConfirmation(School school) {
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(children: [
        Icon(Icons.warning_rounded, color: _DS.danger),
        SizedBox(width: 8),
        Text('Delete School'),
      ]),
      content: Text('Are you sure you want to delete ${school.name}?'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            controller.deleteSchool(school.id);
            Get.back();
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: _DS.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: const Text('Delete'),
        ),
      ],
    ));
  }

  void _showCreateClassDialog() {
    if (controller.selectedSchool.value == null) {
      Get.snackbar('Error', 'Please select a school first',
          backgroundColor: _DS.danger, colorText: Colors.white, snackPosition: SnackPosition.TOP);
      return;
    }
    final nameController = TextEditingController();
    bool hasSections = false;
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Create Class'),
      content: StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(nameController, 'Class Name'),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: const Text('Has Sections'),
              value: hasSections,
              onChanged: (v) => setState(() => hasSections = v ?? false),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              activeColor: _DS.accent,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            controller.createClass(controller.selectedSchool.value!.id, {
              'name': nameController.text,
              'order': 0,
              'hasSections': hasSections
            });
            Get.back();
            if (controller.selectedSchool.value != null)
              controller.getAllClasses(controller.selectedSchool.value!.id);
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: _DS.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: const Text('Create'),
        ),
      ],
    ));
  }

  void _showEditClassDialog(SchoolClass schoolClass) {
    final nameController = TextEditingController(text: schoolClass.name);
    final orderController = TextEditingController(text: schoolClass.order.toString());
    bool hasSections = schoolClass.hasSections;
    final isLoading = false.obs;
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Edit Class'),
      content: StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(nameController, 'Class Name'),
            const SizedBox(height: 12),
            _field(orderController, 'Order', keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: const Text('Has Sections'),
              value: hasSections,
              onChanged: (v) => setState(() => hasSections = v ?? false),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              activeColor: _DS.accent,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        Obx(() => ElevatedButton(
              onPressed: isLoading.value
                  ? null
                  : () async {
                      isLoading.value = true;
                      try {
                        await controller.updateClass(schoolClass.id, {
                          'name': nameController.text,
                          'order': int.tryParse(orderController.text) ?? 0,
                          'hasSections': hasSections,
                        });
                        Get.back();
                        if (controller.selectedSchool.value != null)
                          controller.getAllClasses(controller.selectedSchool.value!.id);
                      } finally {
                        isLoading.value = false;
                      }
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: _DS.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: isLoading.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Update'),
            )),
      ],
    ));
  }

  void _showCreateSectionDialog() {
    if (controller.selectedSchool.value == null) {
      Get.snackbar('Error', 'Please select a school first');
      return;
    }
    final nameController = TextEditingController();
    final roomController = TextEditingController();
    final capacityController = TextEditingController();
    SchoolClass? selectedClass;
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Create Section'),
      content: StatefulBuilder(
        builder: (context, setState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<SchoolClass>(
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Class'),
                value: selectedClass,
                items:
                    controller.classes.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                onChanged: (v) {
                  setState(() => selectedClass = v);
                  if (v != null)
                    controller.getAllSections(
                        classId: v.id, schoolId: controller.selectedSchool.value!.id);
                },
              ),
              const SizedBox(height: 12),
              _field(nameController, 'Section Name'),
              const SizedBox(height: 12),
              _field(roomController, 'Room Number'),
              const SizedBox(height: 12),
              _field(capacityController, 'Capacity', keyboardType: TextInputType.number),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (selectedClass != null) {
              controller.createSection({
                'schoolId': controller.selectedSchool.value!.id,
                'classId': selectedClass!.id,
                'name': nameController.text,
                'roomNumber': roomController.text,
                'capacity': int.tryParse(capacityController.text),
              });
              Get.back();
              controller.getAllSections(schoolId: controller.selectedSchool.value!.id);
            }
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: _DS.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: const Text('Create'),
        ),
      ],
    ));
  }

  void _showEditSectionDialog(Section section) {
    final nameController = TextEditingController(text: section.name);
    final roomController = TextEditingController(text: section.roomNumber);
    final capacityController = TextEditingController(text: section.capacity?.toString());
    final isLoading = false.obs;
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Edit Section'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _field(nameController, 'Section Name'),
          const SizedBox(height: 12),
          _field(roomController, 'Room Number'),
          const SizedBox(height: 12),
          _field(capacityController, 'Capacity', keyboardType: TextInputType.number),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        Obx(() => ElevatedButton(
              onPressed: isLoading.value
                  ? null
                  : () async {
                      isLoading.value = true;
                      try {
                        await controller.updateSection(section.id, {
                          'name': nameController.text,
                          'roomNumber': roomController.text,
                          'capacity': int.tryParse(capacityController.text),
                        });
                        Get.back();
                        if (controller.selectedSchool.value != null)
                          controller.getAllSections(schoolId: controller.selectedSchool.value!.id);
                      } finally {
                        isLoading.value = false;
                      }
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: _DS.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: isLoading.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Update'),
            )),
      ],
    ));
  }

  void _showCreateStudentDialog() {
    if (controller.selectedSchool.value == null) {
      Get.snackbar('Error', 'Please select a school first');
      return;
    }
    Get.to(() =>
        StudentFormPage(schoolId: controller.selectedSchool.value!.id, isEdit: false));
  }

  void _showEditStudentDialog(Student student) {
    Get.to(() => StudentFormPage(
        student: student,
        schoolId: student.schoolId ?? controller.selectedSchool.value!.id,
        isEdit: true));
  }

  void _showDeleteStudentConfirmation(Student student) {
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete Student'),
      content: Text('Delete ${student.name ?? 'this student'}?'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            controller.deleteStudent(student.id);
            Get.back();
            if (controller.selectedSchool.value != null)
              controller.getAllStudents(schoolId: controller.selectedSchool.value!.id);
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: _DS.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: const Text('Delete'),
        ),
      ],
    ));
  }

  void _showCreateUserDialog() {
    final authController = Get.find<AuthController>();
    final currentUserRole = authController.user.value?.role?.toLowerCase() ?? '';
    final isCorrespondent = currentUserRole == 'correspondent';
    final emailController = TextEditingController();
    final userNameController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    String? selectedSchoolCode;
    controller.getAllSchools();
    if (!isCorrespondent) {
      controller.getAllSchools();
    }
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Create User'),
        content: StatefulBuilder(
          builder: (context, setState) {
            if (!isCorrespondent &&
                selectedSchoolCode == null &&
                controller.schools.isNotEmpty) {
              final userSchoolId = authController.user.value?.schoolId;
              final userSchool = controller.schools.firstWhereOrNull(
                (school) => school.id == userSchoolId,
              );
              if (userSchool != null && userSchool.schoolCode != null) {
                selectedSchoolCode = userSchool.schoolCode;
              }
            }
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: userNameController,
                    decoration: InputDecoration(
                      labelText: 'User Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isCorrespondent)
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      isDense: true,
                      value: selectedSchoolCode,
                      decoration: InputDecoration(
                        hintText: 'Choose School',
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        prefixIcon: Icon(
                          Icons.school,
                          color: Colors.blue[700],
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.blue[700],
                      ),
                      dropdownColor: Colors.white,
                      menuMaxHeight: 300,
                      selectedItemBuilder: (context) {
                        return controller.schools.map((school) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${school.name} (${school.schoolCode})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList();
                      },
                      items: controller.schools.map((school) {
                        return DropdownMenuItem<String>(
                          value: school.schoolCode,
                          child: Row(
                            children: [
                              Icon(
                                Icons.school,
                                size: 16,
                                color: Colors.blue[700],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${school.name} (${school.schoolCode})',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedSchoolCode = value);
                      },
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade50,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.school,
                            color: Colors.blue[700],
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              controller.schools
                                      .firstWhereOrNull(
                                        (school) =>
                                            school.schoolCode ==
                                            selectedSchoolCode,
                                      )
                                      ?.name ??
                                  'Loading...',
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          Obx(
            () => ElevatedButton(
              onPressed: userController.isLoading.value
                  ? null
                  : () async {
                      if (selectedSchoolCode == null) {
                        Get.snackbar(
                          'Error',
                          'Please select a school',
                        );
                        return;
                      }
                      await userController.createUser(
                        email: emailController.text,
                        userName: userNameController.text,
                        password: passwordController.text,
                        phoneNo: phoneController.text,
                        schoolCode: selectedSchoolCode!,
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: userController.isLoading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create'),
            ),
          ),
        ],
      ),
    );
  }

  void _showAssignRoleDialog(Map<String, dynamic> user) {
    final validRoles = [
      'correspondent',
      'teacher',
      'principal',
      'viceprincipal',
      'administrator',
      'parent',
      'accountant'
    ];
    String selectedRole =
        validRoles.contains(user['role']) ? user['role'] : 'correspondent';
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Assign Role — ${user['userName']}'),
      content: StatefulBuilder(
        builder: (context, setState) => DropdownButtonFormField<String>(
          isExpanded: true,
          value: selectedRole,
          decoration: const InputDecoration(labelText: 'Role'),
          items: validRoles
              .map((r) => DropdownMenuItem(
                  value: r, child: Text(r.toUpperCase())))
              .toList(),
          onChanged: (r) {
            if (r != null) setState(() => selectedRole = r);
          },
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            userController.assignRole(user['_id'], selectedRole);
            Get.back();
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: _DS.accent,
              foregroundColor: Colors.white,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: const Text('Assign'),
        ),
      ],
    ));
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    final emailCtrl = TextEditingController(text: user['email']);
    final userNameCtrl = TextEditingController(text: user['userName']);
    final phoneCtrl = TextEditingController(text: user['phoneNo']);
    final isLoading = false.obs;
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Edit — ${user['userName']}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(emailCtrl, 'Email'),
            const SizedBox(height: 12),
            _field(userNameCtrl, 'User Name'),
            const SizedBox(height: 12),
            _field(phoneCtrl, 'Phone'),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Get.back(), child: const Text('Cancel')),
        Obx(() => ElevatedButton(
              onPressed: isLoading.value
                  ? null
                  : () async {
                      isLoading.value = true;
                      try {
                        await userController.updateUser(
                            userId: user['_id'],
                            email: emailCtrl.text,
                            userName: userNameCtrl.text,
                            phoneNo: phoneCtrl.text);
                        Get.back();
                        Get.snackbar('Success', 'User updated',
                            backgroundColor: _DS.success,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.TOP);
                        final schoolId =
                            controller.selectedSchool.value?.id ??
                                Get.find<AuthController>().user.value?.schoolId;
                        if (schoolId != null)
                          await userController.loadUsers(
                              schoolId: schoolId,
                              role: userController.selectedRole.value);
                        final currentUserId =
                            Get.find<AuthController>().user.value?.id;
                        if (currentUserId == user['_id'])
                          await Get.find<AuthController>()
                              .handleUserUpdateSuccess();
                      } catch (e) {
                        Get.back();
                        Get.snackbar('Error', 'Failed to update user',
                            backgroundColor: _DS.danger,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.TOP);
                      } finally {
                        isLoading.value = false;
                      }
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: _DS.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              child: isLoading.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Update'),
            )),
      ],
    ));
  }

  void _showDeleteUserDialog(Map<String, dynamic> user) {
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete User'),
      content: Text('Delete ${user['userName']}?'),
      actions: [
        TextButton(
            onPressed: () => Get.back(), child: const Text('Cancel')),
        Obx(() => ElevatedButton(
              onPressed: userController.isLoading.value
                  ? null
                  : () async {
                      await userController.deleteUser(user['_id']);
                      Get.back();
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: _DS.danger,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              child: userController.isLoading.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Delete'),
            )),
      ],
    ));
  }

  void _showSectionDetailsDialog(BuildContext context, Section section) {
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Section — ${section.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Name', section.name),
            _detailRow('Class', section.className ?? 'N/A'),
            _detailRow('Room', section.roomNumber ?? 'N/A'),
            _detailRow('Capacity', section.capacity?.toString() ?? 'N/A'),
            if (section.classTeachers?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              const Text('Teachers',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _DS.textPrimary)),
              const SizedBox(height: 8),
              ...section.classTeachers!.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.person_rounded,
                            size: 15, color: _DS.accent),
                        const SizedBox(width: 8),
                        Text(t['userName'] ?? 'Unknown',
                            style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Get.back(), child: const Text('Close'))
      ],
    ));
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text('$label:',
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: _DS.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, color: _DS.textPrimary)),
          ),
        ],
      ),
    );
  }

  void _showClassSelectionForBulkClub(Map<String, List<Student>> studentsByClass) {
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Select Class'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: studentsByClass.entries.map((entry) {
          final classObj =
              controller.classes.firstWhereOrNull((c) => c.id == entry.key);
          return ListTile(
            leading: _iconBox(Icons.class_rounded),
            title: Text(classObj?.name ?? 'Unknown Class'),
            subtitle: Text('${entry.value.length} students'),
            onTap: () {
              Get.back();
              if (classObj != null) _showBulkClubDialog(entry.value, classObj);
            },
          );
        }).toList(),
      ),
      actions: [
        TextButton(
            onPressed: () => Get.back(), child: const Text('Cancel'))
      ],
    ));
  }

  void _showStudentClubDialog(Student student, SchoolClass? selectedClass) {
    if (selectedClass == null) {
      Get.snackbar('Error', 'Please select a class first');
      return;
    }
    final clubController = Get.find<ClubController>();
    final clubsController = Get.put(ClubsController());
    final availableClubs = <Club>[].obs;
    final dialogLoading = false.obs;
    availableClubs.value = clubsController.getClubsByClass(selectedClass.id);
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: GradientDialog(
          header: dialogHeader(
            title: 'Club Management',
            subtitle:
                '${student.name ?? 'N/A'} • ${selectedClass.name}',
            icon: Icons.sports_soccer,
          ),
          body: Obx(() {
            if (availableClubs.isEmpty)
              return const Center(
                  child: Text('No clubs available',
                      style: TextStyle(color: Colors.grey)));
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: availableClubs.length,
              itemBuilder: (_, index) {
                final club = availableClubs[index];
                final isSelected =
                    student.clubs?.contains(club.id) ?? false;
                return clubTile(
                  name: club.name,
                  description: club.description,
                  selected: isSelected,
                  onTap: dialogLoading.value
                      ? () {}
                      : () async {
                          try {
                            dialogLoading.value = true;
                            if (!isSelected) {
                              await clubController.addStudentToClub(
                                  club.id, student.id);
                              student.clubs ??= [];
                              student.clubs!.add(club.id);
                            } else {
                              await clubController.removeStudentFromClub(
                                  club.id, student.id);
                              student.clubs?.remove(club.id);
                            }
                            availableClubs.refresh();
                          } catch (e) {
                            Get.snackbar(
                              'Error',
                              'Failed to update club',
                              backgroundColor: Colors.red.shade400,
                              colorText: Colors.white,
                            );
                          } finally {
                            dialogLoading.value = false;
                          }
                        },
                );
              },
            );
          }),
          footer: Obx(() => dialogFooter(
                loading: dialogLoading.value,
                onCancel: () => Get.back(),
                onSave: () async {
                  Get.back();
                  Get.snackbar(
                    'Success',
                    'Club assignments updated',
                    backgroundColor: const Color(0xFF38EF7D),
                    colorText: Colors.white,
                  );
                  if (controller.selectedSchool.value != null)
                    await controller.getAllStudents(
                        schoolId: controller.selectedSchool.value!.id);
                },
              )),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _showBulkClubDialog(List<Student> students, SchoolClass selectedClass) {
    final clubController = Get.find<ClubController>();
    final availableClubs = <Map<String, dynamic>>[].obs;
    final isLoading = true.obs;
    final dialogLoading = false.obs;
    clubController.getClubsByClass(selectedClass.id).then((_) {
      availableClubs.assignAll(clubController.clubs);
      isLoading.value = false;
    }).catchError((_) => isLoading.value = false);
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: GradientDialog(
          header: dialogHeader(
            title: 'Bulk Club Assignment',
            subtitle:
                '${selectedClass.name} • ${students.length} students',
            icon: Icons.group_add,
          ),
          body: Obx(() {
            if (isLoading.value)
              return const Center(child: CircularProgressIndicator());
            if (availableClubs.isEmpty)
              return const Center(
                  child: Text('No clubs available',
                      style: TextStyle(color: Colors.grey)));
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: availableClubs.length,
              itemBuilder: (_, index) {
                final club = availableClubs[index];
                final clubId = club['_id'];
                final allInClub = students.every((s) => s.clubs?.contains(clubId) ?? false);
                return clubTile(
                  name: club['name'],
                  description: club['description'] ?? '',
                  selected: allInClub,
                  onTap: dialogLoading.value
                      ? () {}
                      : () async {
                          try {
                            dialogLoading.value = true;
                            final studentIds =
                                students.map((s) => s.id).toList();
                            await clubController.toggleStudentsInClub(
                                clubId, studentIds, !allInClub,
                                classId: selectedClass.id);
                            for (final s in students) {
                              s.clubs ??= [];
                              if (!allInClub) s.clubs!.add(clubId);
                              else s.clubs!.remove(clubId);
                            }
                            availableClubs.refresh();
                          } catch (e) {
                            Get.snackbar(
                              'Error',
                              'Failed to update clubs',
                              backgroundColor: Colors.red.shade400,
                              colorText: Colors.white,
                            );
                          } finally {
                            dialogLoading.value = false;
                          }
                        },
                );
              },
            );
          }),
          footer: Obx(() => dialogFooter(
                loading: dialogLoading.value,
                onCancel: () => Get.back(),
                onSave: () async {
                  Navigator.pop(Get.context!);
                  Get.snackbar(
                    'Success',
                    'Bulk club assignment completed',
                    backgroundColor: const Color(0xFF38EF7D),
                    colorText: Colors.white,
                  );
                  if (controller.selectedSchool.value != null)
                    await controller.getAllStudents(
                        schoolId: controller.selectedSchool.value!.id);
                },
              )),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _showAssignClubToStudentDialog(Student student) {
    final clubController = Get.put(ClubController());
    final selectedClubs = <String>[].obs;
    final availableClubs = <Map<String, dynamic>>[].obs;
    final alreadyInClubs = <String>[].obs;
    final isLoading = false.obs;
    void loadClubs() async {
      isLoading.value = true;
      try {
        await clubController.getClubsByClass(student.classId ?? '');
        availableClubs.value = clubController.clubs;
        alreadyInClubs.value = List<String>.from(student.clubs ?? []);
        selectedClubs.value = List<String>.from(student.clubs ?? []);
      } catch (e) {
        Get.snackbar('Error', 'Failed to load clubs');
      } finally {
        isLoading.value = false;
      }
    }
    loadClubs();
    Get.dialog(Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        decoration: BoxDecoration(
          color: _DS.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _DS.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _DS.primary,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_circle_outline,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Assign to Club',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        Text(
                          student.name ?? '',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (isLoading.value)
                  return const Center(
                      child: CircularProgressIndicator(color: _DS.accent));
                if (availableClubs.isEmpty)
                  return _emptyState(
                      icon: Icons.groups_outlined,
                      title: 'No Clubs',
                      subtitle: 'No clubs found for this class');
                return ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: availableClubs.length,
                  itemBuilder: (_, i) {
                    final club = availableClubs[i];
                    final clubId = club['_id'] as String;
                    final isAlreadyMember = alreadyInClubs.contains(clubId);
                    return Obx(() {
                      final isSelected = selectedClubs.contains(clubId);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isAlreadyMember
                              ? _DS.successSoft
                              : (isSelected
                                  ? _DS.accentSoft
                                  : _DS.surfaceAlt),
                          borderRadius:
                              BorderRadius.circular(_DS.radiusSm),
                          border: Border.all(
                            color: isAlreadyMember
                                ? _DS.success
                                : (isSelected ? _DS.accent : _DS.border),
                            width: isAlreadyMember || isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: CheckboxListTile(
                          title: Text(
                            club['name'] ?? 'Unknown Club',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isAlreadyMember
                                    ? _DS.success
                                    : _DS.textPrimary),
                          ),
                          subtitle: club['description'] != null
                              ? Text(club['description'],
                                  style: const TextStyle(
                                      color: _DS.textMuted, fontSize: 12))
                              : null,
                          value: isSelected,
                          activeColor: _DS.accent,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(_DS.radiusSm)),
                          secondary: isAlreadyMember
                              ? _badge('Member',
                                  bg: _DS.successSoft, fg: _DS.success)
                              : null,
                          onChanged: (v) {
                            if (v == true) selectedClubs.add(clubId);
                            else selectedClubs.remove(clubId);
                          },
                        ),
                      );
                    });
                  },
                );
              }),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: _DS.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _DS.textSecondary,
                        side: const BorderSide(color: _DS.border),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_DS.radius),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          final clubsToAdd = selectedClubs
                              .where((id) => !alreadyInClubs.contains(id))
                              .toList();
                          for (final id in clubsToAdd)
                            await clubController.toggleStudentClub(
                                student.id, id, true);
                          Get.back();
                          controller.getAllStudents(
                              schoolId: controller.selectedSchool.value!.id);
                          Get.snackbar('Success', 'Clubs assigned',
                              backgroundColor: _DS.success,
                              colorText: Colors.white);
                        } catch (e) {
                          Get.snackbar('Error', 'Failed to assign clubs',
                              backgroundColor: _DS.danger,
                              colorText: Colors.white);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _DS.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_DS.radius),
                        ),
                      ),
                      child: const Text('Assign Clubs',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  void _showRemoveClubFromStudentDialog(Student student) {
    final clubController = Get.put(ClubController());
    final selectedClubs = <String>[].obs;
    final studentClubs = <Club>[].obs;
    final isLoading = false.obs;
    void loadStudentClubs() async {
      isLoading.value = true;
      try {
        await clubController.getAllClubs(schoolId: controller.selectedSchool.value!.id);
        final allClubs = clubController.clubs;
        final studentClubIds = student.clubs ?? [];
        studentClubs.value = allClubs
            .where((c) => studentClubIds.contains(c['_id']))
            .map((c) => Club.fromJson(c))
            .toList();
      } catch (e) {
        Get.snackbar('Error', 'Failed to load clubs');
      } finally {
        isLoading.value = false;
      }
    }
    loadStudentClubs();
    Get.dialog(Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        decoration: BoxDecoration(
          color: _DS.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _DS.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _DS.danger,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.remove_circle_outline,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Remove from Club',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        Text(
                          student.name ?? '',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (isLoading.value)
                  return const Center(
                      child: CircularProgressIndicator(color: _DS.accent));
                if (studentClubs.isEmpty)
                  return _emptyState(
                      icon: Icons.groups_outlined,
                      title: 'No Clubs',
                      subtitle: 'Student is not in any clubs');
                return ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: studentClubs.length,
                  itemBuilder: (_, i) {
                    final club = studentClubs[i];
                    return Obx(() {
                      final isSelected = selectedClubs.contains(club.id);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFFF1F2)
                              : _DS.surfaceAlt,
                          borderRadius: BorderRadius.circular(_DS.radiusSm),
                          border: Border.all(
                            color: isSelected ? _DS.danger : _DS.border,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: CheckboxListTile(
                          title: Text(club.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _DS.textPrimary)),
                          subtitle: club.description.isNotEmpty
                              ? Text(club.description,
                                  style: const TextStyle(
                                      color: _DS.textMuted, fontSize: 12))
                              : null,
                          value: isSelected,
                          activeColor: _DS.danger,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(_DS.radiusSm)),
                          onChanged: (v) {
                            if (v == true) selectedClubs.add(club.id);
                            else selectedClubs.remove(club.id);
                          },
                        ),
                      );
                    });
                  },
                );
              }),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: _DS.border))),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _DS.textSecondary,
                        side: const BorderSide(color: _DS.border),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_DS.radius),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          for (final id in selectedClubs)
                            await clubController.toggleStudentClub(
                                student.id, id, false);
                          Get.back();
                          controller.getAllStudents(
                              schoolId: controller.selectedSchool.value!.id);
                          Get.snackbar('Success', 'Clubs removed',
                              backgroundColor: _DS.success,
                              colorText: Colors.white);
                        } catch (e) {
                          Get.snackbar('Error', 'Failed to remove clubs',
                              backgroundColor: _DS.danger,
                              colorText: Colors.white);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _DS.danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_DS.radius),
                        ),
                      ),
                      child: const Text('Remove Clubs',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  void _showFeeStructureDialog(SchoolClass schoolClass) {
    final feeController = Get.put(FeeStructureController());
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Fee Structure — ${schoolClass.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _field(amountController, 'Fee Amount',
              keyboardType: TextInputType.number, prefix: '₹ '),
          const SizedBox(height: 12),
          _field(descriptionController, 'Description'),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (amountController.text.isNotEmpty) {
              await feeController.setFeeStructure(
                schoolId: controller.selectedSchool.value!.id,
                classId: schoolClass.id,
                feeHead: {
                  'amount': double.tryParse(amountController.text) ?? 0,
                  'description': descriptionController.text,
                },
              );
              Get.back();
            }
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: _DS.accent,
              foregroundColor: Colors.white,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: const Text('Save'),
        ),
      ],
    ));
  }
}

// ─── Attendance Tab (StatefulWidget — kept structurally identical) ────────────
class _AttendanceTab extends StatefulWidget {
  @override
  State<_AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<_AttendanceTab> {
  final attendanceController = Get.put(old_attendance.AttendanceController());
  final schoolController = Get.find<SchoolController>();
  final authController = Get.find<AuthController>();
  bool get canMarkAttendance =>
      ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/attendance/mark');
  bool get canViewAttendance =>
      ApiPermissions.hasApiAccess(currentUserRole, 'GET /api/attendance/sheet');
  String get currentUserRole =>
      authController.user.value?.role?.toLowerCase() ?? '';
  bool isHistoryMode = false;
  bool _isFiltersExpanded = true;
  DateTime selectedDate = DateTime.now();
  DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime endDate = DateTime.now();
  final TextEditingController _startYearController =
      TextEditingController(text: "2025");
  final TextEditingController _endYearController =
      TextEditingController(text: "2026");
  List<Map<String, dynamic>> attendanceRecords = [];
  List<Map<String, dynamic>> historyRecords = [];
  SchoolClass? selectedClass;
  String get academicYear =>
      "${_startYearController.text}-${_endYearController.text}";

  @override
  void initState() {
    super.initState();
    isHistoryMode = !canMarkAttendance;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final school = schoolController.selectedSchool.value;
      if (school != null) _onSchoolChanged(school);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLandscape = screenSize.width > screenSize.height;
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.blue.shade100],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isTablet ? 24 : 16),
          child: Column(
            children: [
              _buildHeader(isTablet),
              const SizedBox(height: 16),
              _buildModeToggle(),
              const SizedBox(height: 16),
              _buildAttendanceSelectors(isLandscape, isTablet),
              const SizedBox(height: 16),
              if (!isHistoryMode && attendanceRecords.isNotEmpty)
                _buildCollapsibleSummary(isLandscape, isTablet),
              const SizedBox(height: 16),
              SizedBox(
                height: 400,
                child: _buildContentArea(isTablet),
              ),
              const SizedBox(height: 16),
              if (!isHistoryMode &&
                  attendanceRecords.isNotEmpty &&
                  canMarkAttendance)
                _buildSaveButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isTablet) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blue, Colors.blue],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.how_to_reg,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendance Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Track and manage student attendance',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    if (!canMarkAttendance && canViewAttendance) {
      return _card(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _iconBox(Icons.history_rounded),
            const SizedBox(width: 12),
            const Text('History',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: _DS.textPrimary)),
            const Spacer(),
            _badge('View Only'),
          ],
        ),
      );
    }
    return _card(
      padding: const EdgeInsets.all(6),
      child: SegmentedButton<bool>(
        segments: const [
          ButtonSegment(
              value: false,
              label: Text('Mark Daily', style: TextStyle(fontSize: 13)),
              icon: Icon(Icons.today_rounded, size: 16)),
          ButtonSegment(
              value: true,
              label: Text('History', style: TextStyle(fontSize: 13)),
              icon: Icon(Icons.history_rounded, size: 16)),
        ],
        selected: {isHistoryMode},
        onSelectionChanged: (v) {
          if (mounted) {
            setState(() => isHistoryMode = v.first);
            _onFilterChanged();
          }
        },
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: _DS.accent,
          selectedForegroundColor: Colors.white,
          foregroundColor: _DS.textSecondary,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Widget _buildAttendanceSelectors(bool isLandscape, bool isTablet) {
    return Obx(() {
      final hasSelections =
          schoolController.selectedSchool.value != null &&
              selectedClass != null;
      final isExpanded = !hasSelections || _isFiltersExpanded;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        child: _card(
          padding: const EdgeInsets.all(16),
          child: isExpanded
              ? _buildFullAttendanceSelectors(isLandscape, isTablet)
              : _buildCompactAttendanceSelectors(),
        ),
      );
    });
  }

  Widget _buildCompactAttendanceSelectors() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.school, color: Colors.blue.shade600, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              schoolController.selectedSchool.value?.name ?? '',
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.class_, color: Colors.blue.shade600, size: 18),
          const SizedBox(width: 6),
          Text(
            selectedClass?.name ?? '',
            style:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              if (mounted) {
                setState(() {
                  _isFiltersExpanded = true;
                });
              }
            },
            icon: const Icon(Icons.expand_more, size: 18),
            tooltip: 'Expand Filters',
          ),
        ],
      ),
    );
  }

  Widget _buildFullAttendanceSelectors(bool isLandscape, bool isTablet) {
    return Padding(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.filter_list,
                  color: Colors.blue.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'Filters',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 18 : 16,
                  color: Colors.blue.shade600,
                ),
              ),
              const Spacer(),
              if (schoolController.selectedSchool.value != null &&
                  selectedClass != null)
                IconButton(
                  onPressed: () {
                    if (mounted) {
                      setState(() {
                        _isFiltersExpanded = false;
                      });
                    }
                  },
                  icon: const Icon(Icons.expand_less, size: 20),
                  tooltip: 'Collapse Filters',
                ),
            ],
          ),
          const SizedBox(height: 16),
          isLandscape && isTablet
              ? Row(
                  children: [
                    Expanded(child: _buildSchoolSelector()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildClassSelector()),
                  ],
                )
              : Column(
                  children: [
                    _buildSchoolSelector(),
                    const SizedBox(height: 12),
                    _buildClassSelector(),
                  ],
                ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _startYearController,
                  decoration: InputDecoration(
                    labelText: 'Start Year',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 16 : 12,
                      vertical: isTablet ? 16 : 12,
                    ),
                  ),
                  onChanged: (_) => _onFilterChanged(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '-',
                  style: TextStyle(
                      fontSize: isTablet ? 20 : 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: _endYearController,
                  decoration: InputDecoration(
                    labelText: 'End Year',
                    prefixIcon: const Icon(Icons.event),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 16 : 12,
                      vertical: isTablet ? 16 : 12,
                    ),
                  ),
                  onChanged: (_) => _onFilterChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          isHistoryMode
              ? _buildDateRangeSelector()
              : _buildSingleDateSelector(),
        ],
      ),
    );
  }

  Widget _buildSchoolSelector() {
    return Obx(() {
      final schools = schoolController.schools;
      final selectedId = schoolController.selectedSchool.value?.id;
      return _dropdown<School>(
        value: selectedId == null
            ? null
            : schools.firstWhereOrNull((s) => s.id == selectedId),
        hint: 'Select School',
        icon: Icons.school_rounded,
        selectedItemBuilder: schools
            .map((s) => Text(s.name,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(color: _DS.textPrimary, fontSize: 15)))
            .toList(),
        items: schools
            .map((s) => DropdownMenuItem<School>(
                  value: s,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.school_rounded,
                          color: _DS.accent, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
        onChanged: _onSchoolChanged,
      );
    });
  }

  Widget _buildClassSelector() {
    return Obx(() {
      final classes = schoolController.classes;
      final selectedId = selectedClass?.id;
      return _dropdown<SchoolClass>(
        value: selectedId == null
            ? null
            : classes.firstWhereOrNull((c) => c.id == selectedId),
        hint: 'Select Class',
        icon: Icons.class_rounded,
        selectedItemBuilder: classes
            .map((c) => Text(c.name,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(color: _DS.textPrimary, fontSize: 15)))
            .toList(),
        items: classes
            .map((c) => DropdownMenuItem<SchoolClass>(
                  value: c,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.class_rounded,
                          color: _DS.accent, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          c.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
        onChanged: (c) {
          if (mounted) {
            setState(() => selectedClass = c);
            _onFilterChanged();
          }
        },
      );
    });
  }

  Widget _buildSingleDateSelector() {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
            context: context,
            initialDate: selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030));
        if (d != null && mounted) {
          setState(() => selectedDate = d);
          _onFilterChanged();
        }
      },
      borderRadius: BorderRadius.circular(_DS.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: _DS.surfaceAlt,
          borderRadius: BorderRadius.circular(_DS.radiusSm),
          border: Border.all(color: _DS.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                color: _DS.accent, size: 18),
            const SizedBox(width: 12),
            Text(
              'Date: ${selectedDate.toString().split(' ')[0]}',
              style: const TextStyle(fontSize: 14, color: _DS.textPrimary),
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down_rounded,
                color: _DS.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              final d = await showDatePicker(
                  context: context,
                  initialDate: startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now());
              if (d != null && mounted) {
                setState(() => startDate = d);
                _onFilterChanged();
              }
            },
            borderRadius: BorderRadius.circular(_DS.radiusSm),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _DS.surfaceAlt,
                borderRadius: BorderRadius.circular(_DS.radiusSm),
                border: Border.all(color: _DS.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('From',
                      style: TextStyle(
                          color: _DS.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    startDate.toString().split(' ')[0],
                    style: const TextStyle(
                        fontSize: 14,
                        color: _DS.textPrimary,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            onTap: () async {
              final d = await showDatePicker(
                  context: context,
                  initialDate: endDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now());
              if (d != null && mounted) {
                setState(() => endDate = d);
                _onFilterChanged();
              }
            },
            borderRadius: BorderRadius.circular(_DS.radiusSm),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _DS.surfaceAlt,
                borderRadius: BorderRadius.circular(_DS.radiusSm),
                border: Border.all(color: _DS.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('To',
                      style: TextStyle(
                          color: _DS.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    endDate.toString().split(' ')[0],
                    style: const TextStyle(
                        fontSize: 14,
                        color: _DS.textPrimary,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsibleSummary(bool isLandscape, bool isTablet) {
    final screenSize = MediaQuery.of(context).size;
    final total = attendanceRecords.length;
    final present =
        attendanceRecords.where((r) => r['status'] == 'present').length;
    final absent = total - present;
    final isExpanded = total > 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isExpanded ? null : 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 16 : 12),
        child: isExpanded
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics,
                          color: Colors.blue.shade600,
                          size: isTablet ? 20 : 18),
                      SizedBox(width: isTablet ? 8 : 6),
                      Text('Summary',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isTablet ? 16 : 14)),
                      const Spacer(),
                      Text('$present/$total Present',
                          style: TextStyle(
                              fontSize: isTablet ? 14 : 12,
                              color: Colors.green)),
                    ],
                  ),
                  SizedBox(height: isTablet ? 12 : 8),
                  isLandscape && isTablet
                      ? Row(
                          children: [
                            Expanded(
                                child: _buildSummaryCard('Total',
                                    total.toString(), Colors.blue, isTablet)),
                            SizedBox(width: isTablet ? 8 : 6),
                            Expanded(
                                child: _buildSummaryCard('Present',
                                    present.toString(), Colors.green, isTablet)),
                            SizedBox(width: isTablet ? 8 : 6),
                            Expanded(
                                child: _buildSummaryCard('Absent',
                                    absent.toString(), Colors.red, isTablet)),
                          ],
                        )
                      : Wrap(
                          spacing: isTablet ? 8 : 6,
                          runSpacing: isTablet ? 8 : 6,
                          children: [
                            SizedBox(
                              width: (screenSize.width - (isTablet ? 80 : 60)) / 3,
                              child: _buildSummaryCard('Total',
                                  total.toString(), Colors.blue, isTablet),
                            ),
                            SizedBox(
                              width: (screenSize.width - (isTablet ? 80 : 60)) / 3,
                              child: _buildSummaryCard('Present',
                                  present.toString(), Colors.green, isTablet),
                            ),
                            SizedBox(
                              width: (screenSize.width - (isTablet ? 80 : 60)) / 3,
                              child: _buildSummaryCard('Absent',
                                  absent.toString(), Colors.red, isTablet),
                            ),
                          ],
                        ),
                  SizedBox(height: isTablet ? 12 : 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _bulkUpdateStatus('present'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade100,
                            foregroundColor: Colors.green.shade700,
                            padding: EdgeInsets.symmetric(
                                vertical: isTablet ? 12 : 8),
                          ),
                          child: Text('All Present',
                              style: TextStyle(
                                  fontSize: isTablet ? 14 : 12)),
                        ),
                      ),
                      SizedBox(width: isTablet ? 8 : 6),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _bulkUpdateStatus('absent'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade100,
                            foregroundColor: Colors.red.shade700,
                            padding: EdgeInsets.symmetric(
                                vertical: isTablet ? 12 : 8),
                          ),
                          child: Text('All Absent',
                              style: TextStyle(
                                  fontSize: isTablet ? 14 : 12)),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  Icon(Icons.analytics,
                      color: Colors.blue.shade600, size: 18),
                  const SizedBox(width: 8),
                  Text('Summary: $present/$total Present',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, Color color, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 12 : 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: isTablet ? 20 : 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: isTablet ? 12 : 10,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentArea(bool isTablet) {
    return _card(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_DS.radius),
        child: isHistoryMode ? _buildHistoryList() : _buildDailyList(),
      ),
    );
  }

  Widget _buildDailyList() {
    if (attendanceRecords.isEmpty) {
      return const Center(
        child: Text(
          'No students found',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: attendanceRecords.length,
      itemBuilder: (_, i) {
        final r = attendanceRecords[i];
        final isPresent = _normalizeStatus(r['status']) == 'present';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isPresent ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPresent ? Colors.green.shade200 : Colors.red.shade200,
            ),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isPresent ? Colors.green : Colors.red,
              child: Text(
                r['rollNumber']?.toString() ?? '?',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              r['studentName'] ?? 'Unknown Student',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<String>(
                  value: 'present',
                  groupValue: _normalizeStatus(r['status']),
                  onChanged: canMarkAttendance
                      ? (v) {
                          if (mounted && v != null) {
                            setState(() {
                              attendanceRecords[i]['status'] = v;
                            });
                          }
                        }
                      : null,
                  activeColor: Colors.green,
                ),
                const Text('P', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                Radio<String>(
                  value: 'absent',
                  groupValue: _normalizeStatus(r['status']),
                  onChanged: canMarkAttendance
                      ? (v) {
                          if (mounted && v != null) {
                            setState(() {
                              attendanceRecords[i]['status'] = v;
                            });
                          }
                        }
                      : null,
                  activeColor: Colors.red,
                ),
                const Text('A', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryList() {
    if (historyRecords.isEmpty) {
      return const Center(
        child: Text(
          'No history found',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: historyRecords.length,
      itemBuilder: (_, i) {
        final item = historyRecords[i];
        final records = item['records'] ?? [];
        final present =
            records.where((r) => r['status'] == 'present').length;
        final absent =
            records.where((r) => r['status'] == 'absent').length;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ExpansionTile(
            title: Text(
              item['date']?.toString().split('T')[0] ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
                'By: ${item['takenBy']?['userName'] ?? 'Unknown'}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _statusChip('Present', present, Colors.green),
                        _statusChip('Absent', absent, Colors.red),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...records.map<Widget>((s) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: s['status'] == 'present'
                                ? Colors.green
                                : Colors.red,
                            child: Text(
                              s['rollNumber']?.toString() ?? '',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ),
                          title: Text(s['studentName'] ?? ''),
                          dense: true,
                        )),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _saveAttendance,
        icon: const Icon(Icons.save),
        label: const Text('Save Attendance'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _normalizeStatus(String? status) {
    final v = status?.toLowerCase();
    return (v == 'present' || v == 'absent') ? v! : 'present';
  }

  void _onSchoolChanged(School? school) {
    schoolController.selectedSchool.value = school;
    if (mounted)
      setState(() {
        selectedClass = null;
        attendanceRecords.clear();
        historyRecords.clear();
      });
    if (school != null) {
      schoolController.getAllClasses(school.id).then((_) {
        if (schoolController.classes.isNotEmpty && mounted) {
          setState(() => selectedClass = schoolController.classes.first);
          _onFilterChanged();
        }
      });
    }
  }

  void _onFilterChanged() {
    if (schoolController.selectedSchool.value == null ||
        selectedClass == null) return;
    if (isHistoryMode) _loadAttendanceHistory();
    else _loadAttendanceSheet();
  }

  Future<void> _loadAttendanceSheet() async {
    final sheet = await attendanceController.getAttendanceSheet(
      schoolId: schoolController.selectedSchool.value!.id,
      classId: selectedClass!.id,
      date: selectedDate.toString().split(' ')[0],
      academicYear: academicYear,
    );
    if (sheet != null && mounted) {
      setState(() {
        attendanceRecords =
            List<Map<String, dynamic>>.from(sheet).map((r) {
          r['status'] = _normalizeStatus(r['status']);
          return r;
        }).toList();
      });
    } else {
      final students =
          await attendanceController.getStudentsForAttendance(
        schoolId: schoolController.selectedSchool.value!.id,
        classId: selectedClass!.id,
      );
      if (students != null && mounted) {
        setState(() {
          attendanceRecords =
              List<Map<String, dynamic>>.from(students).map((s) => {
                    'studentId': s['_id'] ?? s['id'],
                    'studentName': s['name'] ?? 'Unknown',
                    'rollNumber': s['rollNumber'] ?? '',
                    'status': 'present',
                  }).toList();
        });
      }
    }
  }

  Future<void> _loadAttendanceHistory() async {
    final response = await attendanceController.getAttendanceHistory(
      schoolId: schoolController.selectedSchool.value!.id,
      classId: selectedClass!.id,
      academicYear: academicYear,
      startDate: startDate.toString().split(' ')[0],
      endDate: endDate.toString().split(' ')[0],
    );
    if (response != null && response is List && mounted)
      setState(() =>
          historyRecords = List<Map<String, dynamic>>.from(response));
  }

  void _saveAttendance() {
    attendanceController.markAttendance(
      schoolId: schoolController.selectedSchool.value!.id,
      classId: selectedClass!.id,
      date: selectedDate.toString().split(' ')[0],
      academicYear: academicYear,
      records: attendanceRecords,
    );
  }

  void _bulkUpdateStatus(String status) {
    if (mounted)
      setState(() {
        for (final r in attendanceRecords) r['status'] = status;
      });
  }
}

// ─── Fee Structure Tab (unchanged API, improved UI) ───────────────────────────
class _FeeStructureTab extends StatefulWidget {
  @override
  State<_FeeStructureTab> createState() => _FeeStructureTabState();
}

class _FeeStructureTabState extends State<_FeeStructureTab> {
  final feeController = Get.put(FeeStructureController());
  final schoolController = Get.find<SchoolController>();
  final admissionFeeController = TextEditingController();
  final firstTermController = TextEditingController();
  final secondTermController = TextEditingController();
  final busFirstTermController = TextEditingController();
  final busSecondTermController = TextEditingController();
  final selectedClass = ValueNotifier<SchoolClass?>(null);
  final selectedStudentType = ValueNotifier<String>('old');
  final isStudentTypeExpanded = ValueNotifier<bool>(true);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLandscape = screenSize.width > screenSize.height;
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.blue.shade100],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 24 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.blue, Colors.blue],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.payment,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fee Structure Management',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isTablet ? 24 : 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Configure fees for different classes',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: isTablet ? 16 : 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildCollapsibleSelectors(),
                const SizedBox(height: 16),
                _buildExpandedStudentTypeSelector(isTablet),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.receipt_long,
                              color: Colors.blue[700],
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Fee Details',
                              style: TextStyle(
                                fontSize: isTablet ? 20 : 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(isTablet ? 24 : 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            isLandscape && isTablet
                                ? _buildLandscapeForm()
                                : _buildPortraitForm(),
                            const SizedBox(height: 20),
                            _buildSaveButton(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _feeField(String label, TextEditingController ctrl, IconData icon,
      Color fg, Color bg) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(_DS.radiusSm),
        border: Border.all(color: fg.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: fg, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: fg, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 15, color: _DS.textPrimary),
              decoration: InputDecoration(
                prefixText: '₹ ',
                hintText: '0',
                filled: true,
                fillColor: _DS.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: fg.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: fg.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: fg, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedStudentTypeSelector(bool isTablet) {
    return ValueListenableBuilder<String>(
      valueListenable: selectedStudentType,
      builder: (context, studentType, child) {
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
                      color: Colors.blue[700]!.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      studentType == 'old' ? Icons.school : Icons.person_add,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Student Type',
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => isStudentTypeExpanded.value = false,
                    icon: const Icon(Icons.expand_less, size: 20),
                    tooltip: 'Collapse',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.blue[700]!.withOpacity(0.3)),
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.blue.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: InputDecoration(
                    hintText: 'Select student type',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[700]!.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.category,
                          color: Colors.blue[700], size: 20),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                  dropdownColor: Colors.white,
                  menuMaxHeight: 200,
                  borderRadius: BorderRadius.circular(12),
                  icon: Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: Icon(Icons.keyboard_arrow_down,
                        color: Colors.blue[700]),
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
                          Icon(Icons.school,
                              color: Colors.blue, size: 20),
                          SizedBox(width: 12),
                          Text('Old Students',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    DropdownMenuItem<String>(
                      value: 'new',
                      child: Row(
                        children: [
                          Icon(Icons.person_add,
                              color: Colors.green, size: 20),
                          SizedBox(width: 12),
                          Text('New Students',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      selectedStudentType.value = value;
                      if (schoolController.selectedSchool.value != null &&
                          selectedClass.value != null) {
                        _loadFeeStructure(
                            schoolController.selectedSchool.value!.id,
                            selectedClass.value!.id);
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCollapsibleSelectors() {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLandscape = screenSize.width > screenSize.height;
    return Obx(() {
      final hasSelections = schoolController.selectedSchool.value != null &&
          selectedClass.value != null;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: hasSelections ? 60 : null,
        child: Container(
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
          child: hasSelections
              ? _buildCompactSelectors()
              : _buildFullSelectors(isLandscape, isTablet),
        ),
      );
    });
  }

  Widget _buildCompactSelectors() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.school, color: Colors.blue[700], size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              schoolController.selectedSchool.value?.name ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          Icon(Icons.class_, color: Colors.blue[700], size: 20),
          const SizedBox(width: 8),
          Text(
            selectedClass.value?.name ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              setState(() {
                schoolController.selectedSchool.value = null;
                selectedClass.value = null;
                _clearForm();
              });
            },
            icon: const Icon(Icons.edit, size: 20),
            tooltip: 'Change Selection',
          ),
        ],
      ),
    );
  }

  Widget _buildFullSelectors(bool isLandscape, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: isLandscape && isTablet
          ? Row(
              children: [
                Expanded(child: _buildSchoolDropdown()),
                const SizedBox(width: 16),
                Expanded(child: _buildClassDropdown()),
              ],
            )
          : Column(
              children: [
                _buildSchoolDropdown(),
                const SizedBox(height: 16),
                _buildClassDropdown(),
              ],
            ),
    );
  }

  Widget _buildSchoolDropdown() {
    return Obx(() => _dropdown<School>(
          value: schoolController.selectedSchool.value,
          hint: 'Select School',
          icon: Icons.school_rounded,
          selectedItemBuilder: schoolController.schools
              .map((s) => Text(s.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: _DS.textPrimary, fontSize: 15)))
              .toList(),
          items: schoolController.schools
              .map((s) => DropdownMenuItem<School>(
                    value: s,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.school_rounded,
                            color: _DS.accent, size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            s.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (s) {
            setState(() {
              schoolController.selectedSchool.value = s;
              selectedClass.value = null;
              _clearForm();
            });
            if (s != null) schoolController.getAllClasses(s.id);
          },
        ));
  }

  Widget _buildClassDropdown() {
    return ValueListenableBuilder<SchoolClass?>(
      valueListenable: selectedClass,
      builder: (_, val, __) => _dropdown<SchoolClass>(
        value: schoolController.classes.contains(val) ? val : null,
        hint: 'Select Class',
        icon: Icons.class_rounded,
        selectedItemBuilder: schoolController.classes
            .map((c) => Text(c.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: _DS.textPrimary, fontSize: 15)))
            .toList(),
        items: schoolController.classes
            .map((c) => DropdownMenuItem<SchoolClass>(
                  value: c,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.class_rounded,
                          color: _DS.accent, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          c.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
        onChanged: (c) {
          setState(() => selectedClass.value = c);
          if (c != null && schoolController.selectedSchool.value != null)
            _loadFeeStructure(schoolController.selectedSchool.value!.id, c.id);
        },
      ),
    );
  }

  Widget _buildSaveButton() {
    final authController = Get.find<AuthController>();
    final currentUserRole =
        authController.user.value?.role?.toLowerCase() ?? '';
    if (!ApiPermissions.hasApiAccess(
        currentUserRole, 'POST /api/feestructure/set'))
      return const SizedBox.shrink();
    return Obx(() => _primaryBtn(
          label: 'Save Fee Structure',
          icon: Icons.save_rounded,
          loading: feeController.isLoading.value,
          onPressed: feeController.isLoading.value
              ? null
              : _saveFeeStructure,
        ));
  }

  void _clearForm() {
    admissionFeeController.clear();
    firstTermController.clear();
    secondTermController.clear();
    busFirstTermController.clear();
    busSecondTermController.clear();
  }

  void _loadFeeStructure(String schoolId, String classId) async {
    final studentType = selectedStudentType.value;
    final feeStructure = await feeController.getFeeStructureByClass(
        schoolId, classId, type: studentType);
    if (feeStructure != null) {
      final feeHead =
          feeStructure['feeHead'] ?? feeStructure['data']?['feeHead'] ?? {};
      admissionFeeController.text =
          feeHead['admissionFee']?.toString() ?? '';
      firstTermController.text =
          feeHead['firstTermAmt']?.toString() ?? '';
      secondTermController.text =
          feeHead['secondTermAmt']?.toString() ?? '';
      busFirstTermController.text =
          feeHead['busFirstTermAmt']?.toString() ?? '';
      busSecondTermController.text =
          feeHead['busSecondTermAmt']?.toString() ?? '';
    } else {
      _clearForm();
    }
  }

  void _saveFeeStructure() {
    if (schoolController.selectedSchool.value == null) {
      Get.snackbar('Error', 'Please select a school first',
          backgroundColor: _DS.danger,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP);
      return;
    }
    final cls = selectedClass.value;
    if (cls == null) {
      Get.snackbar('Error', 'Please select a class',
          backgroundColor: _DS.danger,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP);
      return;
    }
    feeController.setFeeStructure(
      schoolId: schoolController.selectedSchool.value!.id,
      classId: cls.id,
      type: selectedStudentType.value,
      feeHead: {
        'admissionFee': double.tryParse(admissionFeeController.text) ?? 0,
        'firstTermAmt': double.tryParse(firstTermController.text) ?? 0,
        'secondTermAmt': double.tryParse(secondTermController.text) ?? 0,
        'busFirstTermAmt': double.tryParse(busFirstTermController.text) ?? 0,
        'busSecondTermAmt': double.tryParse(busSecondTermController.text) ?? 0,
      },
    );
  }

  Widget _buildPortraitForm() {
    return Column(
      children: [
        _feeField('Admission Fee', admissionFeeController, Icons.account_balance_wallet, Colors.blue[700]!, Colors.blue[50]!),
        const SizedBox(height: 12),
        _feeField('First Term Fee', firstTermController, Icons.calendar_today, Colors.blue[700]!, Colors.blue[50]!),
        const SizedBox(height: 12),
        _feeField('Second Term Fee', secondTermController, Icons.calendar_month, Colors.blue[700]!, Colors.blue[50]!),
        const SizedBox(height: 12),
        _feeField('Bus First Term', busFirstTermController, Icons.directions_bus, Colors.orange[700]!, Colors.orange[50]!),
        const SizedBox(height: 12),
        _feeField('Bus Second Term', busSecondTermController, Icons.directions_bus, Colors.orange[700]!, Colors.orange[50]!),
      ],
    );
  }

  Widget _buildLandscapeForm() {
    return Row(
      children: [
        Expanded(child: _buildPortraitForm()),
      ],
    );
  }
}