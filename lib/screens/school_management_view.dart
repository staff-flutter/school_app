import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:collection/collection.dart';
import 'package:school_app/controllers/clubs_controller.dart';
import 'package:school_app/controllers/student_controller.dart' show StudentController;
import 'package:school_app/core/utils/academic_year_utils.dart';
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
import '../routes/app_routes.dart';
import 'create_student_profile_page.dart';

// ─── Design System ────────────────────────────────────────────────────────────
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

// ─── Reusable Design Components ───────────────────────────────────────────────

/// Standard card wrapper
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

/// Pill badge
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

/// Icon container
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

/// Section header
Widget _sectionHeader(String title, {Widget? action}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
    child: Row(
      children: [
        Container(width: 3, height: 18, decoration: BoxDecoration(
          color: _DS.accent,
          borderRadius: BorderRadius.circular(2),
        )),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: _DS.textPrimary,
          letterSpacing: -0.2,
        )),
        if (action != null) ...[const Spacer(), action],
      ],
    ),
  );
}

/// Gradient primary button
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_DS.radius)),
      ),
      child: loading
          ? const SizedBox(width: 20, height: 20,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
          Text(label, style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.1)),
        ],
      ),
    ),
  );
}

/// Styled text field
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

/// Styled dropdown
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
      selectedItemBuilder: selectedItemBuilder != null
          ? (_) => selectedItemBuilder
          : null,
      items: items,
      onChanged: onChanged,
    ),
  );
}

/// Empty state
Widget _emptyState({required IconData icon, required String title, required String subtitle}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: _DS.accentSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: _DS.accent),
          ),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700, color: _DS.textPrimary)),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _DS.textMuted)),
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
  // final userController = Get.put(UserManagementController());
  //
  // final marksController = Get.put(MarksController());
  @override
  void initState() {
    super.initState();
    controller = Get.find<SchoolController>();
    userController = Get.put(UserManagementController());
    marksController = Get.put(MarksController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load data for whatever school is already selected in sidebar
      final school = controller.selectedSchool.value;
      if (school != null) {
        controller.getAllClasses(school.id);
        controller.getAllSections(schoolId: school.id);
        controller.getAllStudents(schoolId: school.id);
        userController.loadUsers(
          schoolId: school.id,
          role: userController.selectedRole.value,
        );
      }
      controller.getAllSchools();
    });

    // React to sidebar school changes
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

  // ── Permission helpers (unchanged) ──────────────────────────────────────────
  bool canCreateUser(String role) => role == 'correspondent';

  bool canDeleteUser(String role) => role == 'correspondent';

  bool canEditUser(String role) => ['correspondent','teacher','principal','administrator','viceprincipal'].contains(role);

  bool canAssignRole(String role) => ['correspondent','administrator'].contains(role);

  bool canCreateSchool(String role) => role == 'correspondent';

  bool canEditSchool(String role) => role == 'correspondent';

  bool canDeleteSchool(String role) => role == 'correspondent';

  bool canUpdateSchoolLogo(String role) => role == 'correspondent';

  bool canCreateClass(String role) => ['correspondent','administrator'].contains(role);

  bool canEditClass(String role) => ['correspondent','administrator'].contains(role);

  bool canDeleteClass(String role) => ['correspondent','administrator'].contains(role);

  bool canCreateSection(String role) => ['correspondent','administrator'].contains(role);

  bool canEditSection(String role) => ['correspondent','administrator'].contains(role);

  bool canDeleteSection(String role) => role == 'correspondent';

  bool canCreateStudent(String role) => ['correspondent','administrator','accountant'].contains(role);

  bool canEditStudent(String role) => ['correspondent','administrator','accountant'].contains(role);

  bool canDeleteStudent(String role) => role == 'correspondent';

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'correspondent':  return Icons.admin_panel_settings;
      case 'teacher':        return Icons.school;
      case 'principal':      return Icons.account_balance;
      case 'viceprincipal':  return Icons.supervisor_account;
      case 'administrator':  return Icons.settings;
      case 'accountant':     return Icons.calculate;
      case 'parent':         return Icons.family_restroom;
      default:               return Icons.person;
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
        {'title': 'Schools',    'icon': Icons.school,           'builder': _buildSchoolsTab},
      if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/class/create') ||
          ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/class/update') ||
          ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/class/delete'))
        {'title': 'Classes',    'icon': Icons.class_,           'builder': _buildClassesTab},
      if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/section/create') ||
          ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/section/update') ||
          ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/section/delete'))
        {'title': 'Sections',   'icon': Icons.group,            'builder': _buildSectionsTab},
      if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/student/create') ||
          ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/student/update') ||
          ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/student/delete'))
        {'title': 'Students',   'icon': Icons.people,           'builder': _buildStudentsTab},
      if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/user/create'))
        {'title': 'Users',      'icon': Icons.person,           'builder': _buildUsersTab},
      if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/teacher/assignments/manage'))
        {'title': 'Teachers',   'icon': Icons.assignment_ind,   'builder': _buildTeacherAssignmentTab},
      if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/feestructure/set') ||
          ApiPermissions.hasApiAccess(currentUserRole, 'GET /api/feestructure/getbyclass'))
        {'title': 'Fees',       'icon': Icons.payment,          'builder': _buildFeeStructureTab},
      if (ApiPermissions.hasApiAccess(currentUserRole, 'GET /api/attendance/sheet') ||
          ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/attendance/mark') ||
          ApiPermissions.hasApiAccess(currentUserRole, 'GET /api/attendance/getallclass'))
        {'title': 'Attendance', 'icon': Icons.how_to_reg,       'builder': _buildAttendanceTab},
    ];
  }

  @override
  Widget build(BuildContext context) {
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   controller.getAllSchools();
    //   _initializeSchoolForUser();
    // });
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
// ── Tab Bar ──────────────────────────────────────────────────
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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  indicator: BoxDecoration(
                    color: _DS.surface,                          // white fill — same as bar
                    borderRadius: BorderRadius.circular(10),
                    border: Border(
                      bottom: BorderSide(color: _DS.accent, width: 2.5), // blue underline only
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: _DS.accent,                        // selected = blue text
                  unselectedLabelColor: _DS.textSecondary,       // unselected = grey text
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  tabs: tabs.map((tab) => Tab(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(tab['icon'] as IconData, size: 15),
                          const SizedBox(width: 5),
                          Text(tab['title'] as String),
                        ],
                      ),
                    ),
                  )).toList(),
                ),
              ),         const SizedBox(height: 12),
              // ── Tab Content ───────────────────────────────────────────────
              Expanded(
                child: ResponsiveWrapper(
                  child: TabBarView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    children: tabs.map((tab) =>
                        (tab['builder'] as Widget Function())()).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── App Bar ────────────────────────────────────────────────────────────────
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
                //_buildSchoolLogo(),
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
                        return Text(name, style: const TextStyle(
                          color: _DS.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ), overflow: TextOverflow.ellipsis);
                      }),
                      const Text('Management Portal', style: TextStyle(
                          color: _DS.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
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
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_DS.accent, _DS.primary],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: _DS.accentMid, width: 2),
                      ),
                      child: Center(
                        child: Text(name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.white,
                                fontWeight: FontWeight.w700, fontSize: 15)),
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
            width: 40, height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_DS.radiusSm),
              border: Border.all(color: _DS.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_DS.radiusSm),
              child: Image.network(school['logo']['url'],
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                  const Icon(Icons.school, color: _DS.accent, size: 24)),
            ),
          ),
        );
      }
    } catch (_) {}
    return Container(
      width: 40, height: 40,
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
        Center(child: Container(
          width: 220, height: 220,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_DS.accent, _DS.primary],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            shape: BoxShape.circle,
            boxShadow: _DS.shadowMd,
          ),
          child: Center(child: Text(
            userName.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.w800, fontSize: 90),
          )),
        )),
        Positioned(top: 40, right: 40,
            child: GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle,
                  boxShadow: _DS.shadow,
                ),
                child: const Icon(Icons.close, size: 20, color: _DS.textPrimary),
              ),
            )),
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
            width: double.infinity, height: double.infinity,
            color: Colors.black87,
            child: Center(child: InteractiveViewer(
              minScale: 0.5, maxScale: 4.0,
              child: Image.network(logoUrl, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) { Get.back(); return const SizedBox(); }),
            )),
          ),
        ),
        Positioned(top: 50, right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(100),
              ),
              child: IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.close, color: Colors.white, size: 22),
              ),
            )),
      ]),
    ));
  }

  // ─── Schools Tab ───────────────────────────────────────────────────────────
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
              ? _emptyState(icon: Icons.school_outlined,
              title: 'No Schools Yet',
              subtitle: 'Create your first school to get started')
              : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            itemCount: controller.schools.length+1,


              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                    child: Row(children: [
                      Text('${controller.schools.length} school${controller.schools.length == 1 ? '' : 's'}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                              color: _DS.textMuted)),
                      const Spacer(),
                      GestureDetector(
                        onTap: controller.refreshSchools,
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.refresh_rounded, size: 14, color: _DS.accent),
                          SizedBox(width: 4),
                          Text('Refresh', style: TextStyle(fontSize: 12, color: _DS.accent,
                              fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ]),
                  );
                }
                return _buildSchoolCard(controller.schools[index - 1], currentUserRole);            }
          ),
        );
      }),
      floatingActionButton: ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/school/create')
          ? _buildFAB(onPressed: () => Get.toNamed('/create-school'),
          icon: Icons.add_rounded, label: 'Add School')
          : null,
    );
  }

  Widget _buildSchoolCard(School school, String currentUserRole) {
    final colors = [
      [const Color(0xFFEFF6FF), const Color(0xFF3B82F6)],
      [const Color(0xFFECFDF5), const Color(0xFF059669)],
      [const Color(0xFFFFFBEB), const Color(0xFFD97706)],
      [const Color(0xFFF5F3FF), const Color(0xFF7C3AED)],
    ];
    final colorPair = colors[school.name.hashCode % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _DS.border),
        boxShadow: _DS.shadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header band ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),  // was (16,16,12,16)
          decoration: BoxDecoration(
            color: colorPair[0],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: // Replace the header Row children (logo + text column + badges)
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            // Logo
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: _DS.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorPair[1].withOpacity(0.2)),
              ),
              child: school.logo?['url'] != null && school.logo!['url']!.isNotEmpty
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(school.logo!['url']!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.school_rounded, color: colorPair[1], size: 26)),
              )
                  : Icon(Icons.school_rounded, color: colorPair[1], size: 26),
            ),
            const SizedBox(width: 12),

            // Name + code — Expanded so it doesn't push badges off screen
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    school.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _DS.textPrimary,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (school.schoolCode != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorPair[1].withOpacity(0.12),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      // ← constrain width so the pill never wraps
                      child: Text(
                        'Code: ${school.schoolCode}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colorPair[1],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Active badge — fixed width column so it never wraps
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _DS.successSoft,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        color: _DS.success, shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('Active',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _DS.success,
                        )),
                  ]),
                ),
                const SizedBox(height: 4),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.more_horiz_rounded, color: colorPair[1], size: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_DS.radius)),
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
          ]),
        ),
        // ── Info grid ────────────────────────────────────────────────
        if (school.email != null || school.phoneNo != null ||
            school.currentAcademicYear != null || school.address != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              if (school.email != null) _infoChip(Icons.email_rounded, school.email!),
              if (school.phoneNo != null) _infoChip(Icons.phone_rounded, school.phoneNo!),
              if (school.currentAcademicYear != null)
                _infoChip(Icons.calendar_today_rounded, school.currentAcademicYear!),
              if (school.address != null)
                _infoChip(Icons.location_on_rounded, school.address!),
            ]),
          ),
      ]),
    );
  }

  Widget _infoChip(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _DS.surfaceAlt,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: _DS.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: _DS.accent),
        const SizedBox(width: 5),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 160),
          child: Text(value, style: const TextStyle(fontSize: 12,
              color: _DS.textSecondary, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }
  // ─── Classes Tab ───────────────────────────────────────────────────────────
  Widget _buildClassesTab() {
    final authController = Get.find<AuthController>();
    final currentUserRole = authController.user.value?.role?.toLowerCase() ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.schools.isEmpty) controller.getAllSchools();
      if (controller.selectedSchool.value != null)
        controller.getAllClasses(controller.selectedSchool.value!.id);
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Obx(() {
        if (controller.isLoading.value)
          return const Center(child: CircularProgressIndicator(color: _DS.accent));
        if (controller.classes.isEmpty)
          return _emptyState(
            icon: Icons.class_outlined,
            title: 'No Classes',
            subtitle: 'Add classes to organize your students',
          );
        final sortedClasses = ClassUtils.sortClasses(controller.classes);
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
          itemCount: sortedClasses.length,
          itemBuilder: (context, i) =>
              _buildClassCard(sortedClasses[i], currentUserRole),
        );
      }),
      floatingActionButton: ApiPermissions.hasApiAccess(
          currentUserRole, 'POST /api/class/create')
          ? _buildFAB(
        onPressed: _showCreateClassDialog,
        icon: Icons.add_rounded,
        label: 'Add Class',
      )
          : null,
    );
  }

  Widget _buildClassCard(SchoolClass schoolClass, String currentUserRole) {
    return _card(
      padding: const EdgeInsets.only(top: 12,bottom: 12,left: 8),
      child: Row(children: [
        _iconBox(Icons.class_rounded,bg: const Color(0xFFE0F7FA), fg: const Color(0xFF006064)),
        const SizedBox(width: 14),
        Expanded(
            child: Text(schoolClass.name,
                style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600,
                    color: _DS.textPrimary,),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )),
        if (schoolClass.hasSections)
          _badge('Has Sections', bg: _DS.successSoft, fg: _DS.success),
        const SizedBox(width: 2),
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
      ]),
    );
  }

  // ─── Sections Tab ──────────────────────────────────────────────────────────
  Widget _buildSectionsTab() {
    final authController = Get.find<AuthController>();
    final currentUserRole = authController.user.value?.role?.toLowerCase() ?? '';
    final isCorrespondent = currentUserRole == 'correspondent';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.schools.isEmpty) controller.getAllSchools();
      if (controller.selectedSchool.value != null)
        controller.getAllSections(schoolId: controller.selectedSchool.value!.id);
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body:
        Obx(() {
          if (controller.isLoading.value)
            return const Center(child: CircularProgressIndicator(color: _DS.accent));
          if (controller.sections.isEmpty)
            return _emptyState(icon: Icons.group_outlined,
                title: 'No Sections', subtitle: 'Add sections to organize classes');
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            itemCount: controller.sections.length,
            itemBuilder: (context, i) =>
                _buildSectionCard(context, controller.sections[i], currentUserRole),
          );
        }),
      floatingActionButton: ApiPermissions.hasApiAccess(
          currentUserRole, 'POST /api/section/create')
          ? _buildFAB(
        onPressed: _showCreateSectionDialog,
        icon: Icons.add_rounded,
        label: 'Add Section',
      )
          : null,
    );
  }

  Widget _buildSectionCard(BuildContext context, Section section, String currentUserRole) {
    return _card(
      padding: const EdgeInsets.all(16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _iconBox(Icons.group_rounded, bg: const Color(0xFFEDE9FE), fg: const Color(0xFF7C3AED)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(section.name, style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, color: _DS.textPrimary)),
          const SizedBox(height: 4),
          _metaRow(Icons.class_rounded, 'Class: ${section.className ?? "N/A"}'),
          _metaRow(Icons.meeting_room_rounded, 'Room: ${section.roomNumber ?? "N/A"}'),
          if (section.classTeachers?.isNotEmpty == true)
            _metaRow(Icons.person_rounded,
                'Teachers: ${section.classTeachers!.map((t) => t['userName'] ?? 'Unknown').join(', ')}'),
        ])),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_horiz_rounded, color: _DS.textMuted, size: 22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radius)),
          itemBuilder: (context) => [
            _menuItem('view', Icons.visibility_rounded, 'View Details'),
            if (ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/section/update'))
              _menuItem('edit', Icons.edit_rounded, 'Edit'),
            if (ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/section/delete'))
              _menuItem('delete', Icons.delete_rounded, 'Delete', danger: true),
          ],
          onSelected: (value) {
            if (value == 'view') _showSectionDetailsDialog(context, section);
            else if (value == 'edit') _showEditSectionDialog(section);
            else if (value == 'delete')
              controller.deleteSection(section.id).then((_) {
                if (controller.selectedSchool.value != null)
                  controller.getAllSections(schoolId: controller.selectedSchool.value!.id);
              });
          },
        ),
      ]),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(children: [
        Icon(icon, size: 13, color: _DS.textMuted),
        const SizedBox(width: 5),
        Expanded(child: Text(text, style: const TextStyle(
            fontSize: 12, color: _DS.textSecondary), overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  // ─── Students Tab ──────────────────────────────────────────────────────────
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
    final canManageClubs = ['correspondent', 'administrator'].contains(currentUserRole);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(children: [
        // ── Filters ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Obx(() {
            final selectedClassVal = selectedClass.value;
            final selectedSectionVal = selectedSection.value;
            return Row(children: [
              // Class chip
              GestureDetector(
                onTap: () => _showClassFilterSheet(selectedClass, selectedSection),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selectedClassVal != null ? _DS.accentSoft : _DS.surface,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: selectedClassVal != null ? _DS.accent : _DS.border,
                      width: selectedClassVal != null ? 1.5 : 1,
                    ),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.class_rounded,
                        size: 14,
                        color: selectedClassVal != null ? _DS.accent : _DS.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      selectedClassVal?.name ?? 'All Classes',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selectedClassVal != null ? _DS.accent : _DS.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded,
                        size: 14,
                        color: selectedClassVal != null ? _DS.accent : _DS.textMuted),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
              // Section chip
              GestureDetector(
                onTap: () => _showSectionFilterSheet(selectedSection),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selectedSectionVal != null ? _DS.accentSoft : _DS.surface,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: selectedSectionVal != null ? _DS.accent : _DS.border,
                      width: selectedSectionVal != null ? 1.5 : 1,
                    ),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.group_rounded,
                        size: 14,
                        color: selectedSectionVal != null ? _DS.accent : _DS.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      selectedSectionVal?.name ?? 'All Sections',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selectedSectionVal != null
                            ? _DS.accent : _DS.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded,
                        size: 14,
                        color: selectedSectionVal != null ? _DS.accent : _DS.textMuted),
                  ]),
                ),
              ),
              const Spacer(),
              // Clear button — only shows when something is selected
              if (selectedClassVal != null || selectedSectionVal != null)
                GestureDetector(
                  onTap: () {
                    selectedClass.value = null;
                    selectedSection.value = null;
                    _loadStudentsByFilters(null, null);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: _DS.dangerSoft,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.close_rounded, size: 13, color: _DS.danger),


                    ]),
                  ),
                ),
            ]);
          }),
        ),

        // ── Student list ───────────────────────────────────────────
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value)
              return const Center(
                  child: CircularProgressIndicator(color: _DS.accent));

            final studentsToShow = controller.students;

            if (studentsToShow.isEmpty)
              return _emptyState(
                icon: Icons.people_outline_rounded,
                title: 'No Students',
                subtitle: controller.selectedSchool.value == null
                    ? 'Select a school to view students'
                    : 'No students found',
              );

            final sorted = List<Student>.from(studentsToShow)
              ..sort((a, b) => (a.name ?? '')
                  .toLowerCase()
                  .compareTo((b.name ?? '').toLowerCase()));

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: sorted.length,
              itemBuilder: (context, i) =>
                  _buildStudentCard(sorted[i], currentUserRole, canManageClubs),
            );
          }),
        ),
      ]),

      // ── FAB — belongs on Scaffold, not inside Column ───────────
      floatingActionButton: ApiPermissions.hasApiAccess(
          currentUserRole, 'POST /api/student/create')
          ? _buildFAB(
        onPressed: _showCreateStudentDialog,
        icon: Icons.person_add_rounded,
        label: 'Add Student',
      )
          : null,
    );
  }

  Widget _buildStudentCard(Student student, String currentUserRole, bool canManageClubs) {
    return _card(
      padding: const EdgeInsets.only(top: 12,bottom: 12,left: 8),
      child: Row(children: [
        // Avatar
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32).withOpacity(0.1),
            // gradient: const LinearGradient(
            //   colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
            //   begin: Alignment.topLeft, end: Alignment.bottomRight,
            // ),
            borderRadius: BorderRadius.circular(_DS.radiusSm),
          ),
          child: Center(child: Text(
            (student.name ?? 'U').substring(0, 1).toUpperCase(),
            style: const TextStyle(color: const Color(0xFF2E7D32),
                fontWeight: FontWeight.w700, fontSize: 18),
          )),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal, // <-- Crucial step
            physics: const BouncingScrollPhysics(),
            child: Text(student.name ?? 'N/A', style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, color: _DS.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,

            ),
          ),
          const SizedBox(height: 2),
          Text(
              (student.rollNumber == null || student.rollNumber!.trim().isEmpty)
                  ? 'No roll number' : 'Roll: ${student.rollNumber}',
              style: const TextStyle(fontSize: 12, color: _DS.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,

          ),
        ])),
        if (canManageClubs) ...[
          SizedBox(
            width: 72,
            height: 32,
            child: ElevatedButton(
              onPressed: () {
                final studentClassId = student.classId;
                if (studentClassId == null || studentClassId.isEmpty) {
                  Get.snackbar('Error', 'Student has no class assigned'); return;
                }
                final studentClass = controller.classes.firstWhereOrNull(
                        (c) => c.id == studentClassId);
                if (studentClass == null) {
                  Get.snackbar('Error', 'Student class not found'); return;
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
              child: const Text('+ Club', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 2),
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
                  student: student, schoolId: controller.selectedSchool.value!.id))
                  ?.then((_) {
                if (controller.selectedSchool.value != null)
                  controller.getAllStudents(schoolId: controller.selectedSchool.value!.id);
              });
            else if (value == 'assignClub') _showAssignClubToStudentDialog(student);
            else if (value == 'removeClub') _showRemoveClubFromStudentDialog(student);
            else if (value == 'edit')

              _showEditStudentDialog(student);
            else if (value == 'delete') _showDeleteStudentConfirmation(student);
          },
        ),
      ]),
    );
  }

  Widget _buildCompactStudentFilters(Rxn<SchoolClass> selectedClass,
      Rxn<Section> selectedSection, RxBool isFiltersExpanded) {
    return Row(children: [
      const Icon(Icons.school_rounded, color: _DS.accent, size: 18),
      const SizedBox(width: 6),
      Flexible(child: Text(controller.selectedSchool.value?.name ?? '',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13,
              color: _DS.textPrimary),
          overflow: TextOverflow.ellipsis)),
      if (selectedClass.value != null) ...[
        const SizedBox(width: 10),
        const Icon(Icons.class_rounded, color: _DS.accent, size: 16),
        const SizedBox(width: 4),
        Text(selectedClass.value!.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12,
                color: _DS.textSecondary)),
      ],
      const Spacer(),
      GestureDetector(
        onTap: () => isFiltersExpanded.value = true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _DS.accentSoft,
            borderRadius: BorderRadius.circular(100),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.tune_rounded, size: 14, color: _DS.accent),
            SizedBox(width: 4),
            Text('Filters', style: TextStyle(fontSize: 12, color: _DS.accent,
                fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildFullStudentFilters(Rxn<SchoolClass> selectedClass,
      Rxn<Section> selectedSection, RxBool isFiltersExpanded) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.tune_rounded, color: _DS.accent, size: 18),
        const SizedBox(width: 8),
        const Text('Filters', style: TextStyle(fontWeight: FontWeight.w700,
            fontSize: 15, color: _DS.textPrimary)),
        const Spacer(),
        if (controller.selectedSchool.value != null)
          GestureDetector(
            onTap: () => isFiltersExpanded.value = false,
            child: const Icon(Icons.expand_less_rounded, color: _DS.textMuted),
          ),
      ]),
      // const SizedBox(height: 14),
      // Obx(() {
      //   final authController = Get.find<AuthController>();
      //   final isCorrespondent =
      //       authController.user.value?.role?.toLowerCase() == 'correspondent';
      //   if (isCorrespondent) {
      //     return _dropdown<School>(
      //       value: controller.selectedSchool.value,
      //       hint: 'Select School',
      //       icon: Icons.school_rounded,
      //       selectedItemBuilder: controller.schools.map((s) =>
      //           Text(s.name, overflow: TextOverflow.ellipsis,
      //               style: const TextStyle(color: _DS.textPrimary, fontSize: 15))).toList(),
      //       items: controller.schools.map((s) => DropdownMenuItem(
      //         value: s, child: _dropdownItem(Icons.school_rounded, s.name),
      //       )).toList(),
      //       onChanged: (School? s) {
      //         controller.selectedSchool.value = s;
      //         selectedClass.value = null;
      //         selectedSection.value = null;
      //         if (s != null) controller.getAllClasses(s.id);
      //       },
      //     );
      //   } else {
      //     if (controller.selectedSchool.value != null && controller.sections.isEmpty)
      //       WidgetsBinding.instance.addPostFrameCallback((_) =>
      //           controller.getAllSections(schoolId: controller.selectedSchool.value!.id));
      //     return _readonlySchoolChip();
      //   }
      // }),
      const SizedBox(height: 10),
      Obx(() {
        final sortedClasses = ClassUtils.sortClasses(controller.classes);
        final uniqueClasses = <SchoolClass>[];
        final seen = <String>{};
        for (final c in sortedClasses) {
          if (seen.add(c.id)) uniqueClasses.add(c);
        }
        return _dropdown<SchoolClass>(
          value: selectedClass.value,
          hint: 'All Classes (Optional)',
          icon: Icons.class_rounded,
          items: [
            DropdownMenuItem<SchoolClass>(
                value: null, child: _dropdownItem(Icons.all_inclusive_rounded, 'All Classes')),
            ...uniqueClasses.map((c) => DropdownMenuItem(
                value: c, child: _dropdownItem(ClassUtils.getClassIcon(c.name), c.name))),
          ],
          selectedItemBuilder: [
            const Text('All Classes', style: TextStyle(color: _DS.textPrimary, fontSize: 15)),
            ...uniqueClasses.map((c) => Text(c.name, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _DS.textPrimary, fontSize: 15))),
          ],
          onChanged: (SchoolClass? c) {
            selectedClass.value = c;
            selectedSection.value = null;
            if (c != null && controller.selectedSchool.value != null)
              controller.getAllSections(classId: c.id, schoolId: controller.selectedSchool.value!.id);
            _loadStudentsByFilters(selectedClass.value, selectedSection.value);
          },
        );
      }),
      const SizedBox(height: 10),
      Obx(() => _dropdown<Section>(
        value: selectedSection.value,
        hint: 'All Sections (Optional)',
        icon: Icons.group_rounded,
        items: [
          DropdownMenuItem<Section>(
              value: null, child: _dropdownItem(Icons.all_inclusive_rounded, 'All Sections')),
          ...controller.sections.map((s) => DropdownMenuItem(
              value: s, child: _dropdownItem(Icons.group_rounded, s.name))),
        ],
        selectedItemBuilder: [
          const Text('All Sections', style: TextStyle(color: _DS.textPrimary, fontSize: 15)),
          ...controller.sections.map((s) => Text(s.name, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _DS.textPrimary, fontSize: 15))),
        ],
        onChanged: (Section? s) {
          selectedSection.value = s;
          _loadStudentsByFilters(selectedClass.value, selectedSection.value);
        },
      )),
    ]);
  }

  void _loadStudentsByFilters(SchoolClass? selectedClass, Section? selectedSection) {
    if (controller.selectedSchool.value == null) return;
    controller.getAllStudents(
      schoolId: controller.selectedSchool.value!.id,
      classId: selectedClass?.id,
      sectionId: selectedSection?.id,
    ).then((_) => print('📋 Students loaded: ${controller.students.length}'));
  }

  // ─── Users Tab ─────────────────────────────────────────────────────────────
  Widget _buildUsersTab() {
    final authController = Get.find<AuthController>();
    final currentUserRole = authController.user.value?.role?.toLowerCase() ?? '';

    const roles = [
      'all', 'correspondent', 'teacher', 'principal',
      'viceprincipal', 'administrator', 'accountant', 'parent'
    ];

    void loadWithRole(String role) {
      userController.selectedRole.value = role;
      final schoolId = controller.selectedSchool.value?.id ??
          authController.user.value?.schoolId;
      if (schoolId != null) {
        userController.loadUsers(schoolId: schoolId, role: role);
      }
    }

    void showRoleSheet() {
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
                const Text('Filter by Role',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
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
              constraints: const BoxConstraints(maxHeight: 420),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: roles.length,
                itemBuilder: (_, i) {
                  final role = roles[i];
                  return Obx(() {
                    final isSelected = userController.selectedRole.value == role;
                    return ListTile(
                      leading: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: isSelected ? _DS.accentSoft : _DS.surfaceAlt,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          role == 'all'
                              ? Icons.all_inclusive_rounded
                              : _getRoleIcon(role),
                          size: 18,
                          color: isSelected ? _DS.accent : _DS.textMuted,
                        ),
                      ),
                      title: Text(
                        role == 'all' ? 'All Roles' : _capitalize(role),
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 14,
                          color: isSelected ? _DS.accent : _DS.textPrimary,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded,
                          color: _DS.accent, size: 20)
                          : null,
                      onTap: () {
                        loadWithRole(role);
                        Get.back();
                      },
                    );
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
          ]),
        ),
        isScrollControlled: true,
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(children: [
        // ── Role chip + count ───────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(children: [
            Obx(() {
              final role = userController.selectedRole.value;
              final isFiltered = role != 'all';
              return GestureDetector(
                onTap: showRoleSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isFiltered ? _DS.accentSoft : _DS.surface,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isFiltered ? _DS.accent : _DS.border,
                      width: isFiltered ? 1.5 : 1,
                    ),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.people_rounded,
                        size: 14,
                        color: isFiltered ? _DS.accent : _DS.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      isFiltered ? _capitalize(role) : 'All Roles',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isFiltered
                            ? _DS.accent : _DS.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded,
                        size: 14,
                        color: isFiltered ? _DS.accent : _DS.textMuted),
                  ]),
                ),
              );
            }),
            const Spacer(),
            Obx(() => Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _DS.surfaceAlt,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: _DS.border),
              ),
              child: Text(
                '${userController.users.length} users',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _DS.textSecondary,
                ),
              ),
            )),
          ]),
        ),

        // ── User list ───────────────────────────────────────────────
        Expanded(
          child: Obx(() {
            if (userController.isLoading.value)
              return const Center(
                  child: CircularProgressIndicator(color: _DS.accent));

            if (userController.users.isEmpty)
              return _emptyState(
                icon: Icons.person_outline_rounded,
                title: 'No Users Found',
                subtitle: 'Add users to manage your school',
              );

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              itemCount: userController.users.length,
              itemBuilder: (context, index) {
                final user = userController.users[index];
                return _buildUserCard(user, currentUserRole);
              },
            );
          }),
        ),
      ]),

      floatingActionButton: ApiPermissions.hasApiAccess(
          currentUserRole, 'POST /api/user/create')
          ? _buildFAB(
        onPressed: _showCreateUserDialog,
        icon: Icons.person_add_rounded,
        label: 'Add User',
      )
          : null,
    );
  }  Widget _buildEmptyState({
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
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_DS.primaryLight, _DS.primary],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(_DS.radiusSm),
          ),
          child: Icon(_getRoleIcon(role), color: Colors.white, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(user['userName'] ?? 'Unknown', style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, color: _DS.textPrimary)),
          const SizedBox(height: 2),
          if (role.isNotEmpty)
            _badge(role.toUpperCase(), bg: _DS.accentSoft, fg: _DS.accent),
          const SizedBox(height: 2),
          Text(user['email'] ?? 'N/A',
              style: const TextStyle(fontSize: 12, color: _DS.textMuted)),
        ])),
        if (user['role'] == null &&
            ['correspondent','administrator'].contains(currentUserRole) &&
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
              child: const Text('Assign Role', style: TextStyle(fontSize: 11,
                  fontWeight: FontWeight.w600)),
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
                ['correspondent','administrator'].contains(currentUserRole))
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
      ]),
    );
  }

  // ─── Teacher Tab ───────────────────────────────────────────────────────────
  Widget _buildTeacherAssignmentTab() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.selectedSchool.value != null) {
        print('🏫 Loading teachers for school: ${controller.selectedSchool.value!.name}');
        controller.loadTeachers();
      }
    });
    return TeacherAssignmentView();
  }

  // ─── Fee Structure Tab ─────────────────────────────────────────────────────
  Widget _buildFeeStructureTab() {
    final authController = Get.find<AuthController>();
    final currentUserRole = authController.user.value?.role?.toLowerCase() ?? '';
    final canSetFeeStructure =
    ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/feestructure/set');

    return DefaultTabController(
      length: canSetFeeStructure ? 2 : 1,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(children: [
          // ── Compact pill tab bar ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 16, 6),
            child: canSetFeeStructure
                ? Container(
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
                    fontWeight: FontWeight.w600, fontSize: 13),
                unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 13),
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, size: 15),
                        SizedBox(width: 5),
                        Text('Set Fee'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.list_alt_rounded, size: 15),
                        SizedBox(width: 5),
                        Text('All Fees'),
                      ],
                    ),
                  ),
                ],
              ),
            )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: canSetFeeStructure
                ? TabBarView(children: [_FeeStructureTab(), AllFeeStructuresTab()])
                : AllFeeStructuresTab(),
          ),
        ]),
      ),
    );
  }
  // ─── Attendance Tab ────────────────────────────────────────────────────────
  Widget _buildAttendanceTab() => SingleChildScrollView(child: _AttendanceTab());

  // ─── Shared helpers ────────────────────────────────────────────────────────
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
        child: Row(children: [
          const Icon(Icons.school_rounded, color: _DS.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(n, style: const TextStyle(
              fontSize: 15, color: _DS.textPrimary, fontWeight: FontWeight.w500))),
          _badge('Your School', bg: _DS.accentSoft, fg: _DS.accent),
        ]),
      );
    });
  }

  Widget _dropdownItem(IconData icon, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
            color: _DS.accentSoft, borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, color: _DS.accent, size: 15),
      ),
      const SizedBox(width: 12),
      Expanded(child: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14,
              color: _DS.textPrimary),
          overflow: TextOverflow.ellipsis)),
    ]);
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label,
      {bool danger = false}) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(children: [
        Icon(icon, size: 18,
            color: danger ? _DS.danger : _DS.textSecondary),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(
            color: danger ? _DS.danger : _DS.textPrimary,
            fontWeight: FontWeight.w500, fontSize: 14)),
      ]),
    );
  }

  Widget _buildFAB({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1E3A5F)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: _DS.accent.withOpacity(0.35),
              blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
  // ── All dialog methods below are unchanged from original ───────────────────
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
          onPressed: () { controller.deleteSchool(school.id); Get.back(); },
          style: ElevatedButton.styleFrom(backgroundColor: _DS.danger, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: const Text('Delete'),
        ),
      ],
    ));
  }

  void _showCreateClassDialog() {
    if (controller.selectedSchool.value == null) {
      Get.snackbar('Error', 'Please select a school first',
          backgroundColor: _DS.danger, colorText: Colors.white,
          snackPosition: SnackPosition.TOP);
      return;
    }
    final nameController = TextEditingController();
    bool hasSections = false;

    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Create Class'),
      content: StatefulBuilder(
        builder: (context, setState) => Column(mainAxisSize: MainAxisSize.min, children: [
          _field(nameController, 'Class Name'),
          const SizedBox(height: 12),
          CheckboxListTile(
            title: const Text('Has Sections'),
            value: hasSections,
            onChanged: (v) => setState(() => hasSections = v ?? false),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            activeColor: _DS.accent,
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            controller.createClass(controller.selectedSchool.value!.id,
                {'name': nameController.text, 'order': 0, 'hasSections': hasSections});
            Get.back();
            if (controller.selectedSchool.value != null)
              controller.getAllClasses(controller.selectedSchool.value!.id);
          },
          style: ElevatedButton.styleFrom(backgroundColor: _DS.accent, foregroundColor: Colors.white,
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
        builder: (context, setState) => Column(mainAxisSize: MainAxisSize.min, children: [
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
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        Obx(() => ElevatedButton(
          onPressed: isLoading.value ? null : () async {
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
            } finally { isLoading.value = false; }
          },
          style: ElevatedButton.styleFrom(backgroundColor: _DS.accent, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: isLoading.value
              ? const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Update'),
        )),
      ],
    ));
  }

  void _showCreateSectionDialog() {
    if (controller.selectedSchool.value == null) {
      Get.snackbar('Error', 'Please select a school first'); return;
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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<SchoolClass>(
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Class'),
              value: selectedClass,
              items: controller.classes.map((c) => DropdownMenuItem(
                  value: c, child: Text(c.name))).toList(),
              onChanged: (v) {
                setState(() => selectedClass = v);
                if (v != null) controller.getAllSections(
                    classId: v.id, schoolId: controller.selectedSchool.value!.id);
              },
            ),
            const SizedBox(height: 12),
            _field(nameController, 'Section Name'),
            const SizedBox(height: 12),
            _field(roomController, 'Room Number'),
            const SizedBox(height: 12),
            _field(capacityController, 'Capacity', keyboardType: TextInputType.number),
          ]),
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
          style: ElevatedButton.styleFrom(backgroundColor: _DS.accent, foregroundColor: Colors.white,
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
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _field(nameController, 'Section Name'),
        const SizedBox(height: 12),
        _field(roomController, 'Room Number'),
        const SizedBox(height: 12),
        _field(capacityController, 'Capacity', keyboardType: TextInputType.number),
      ]),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        Obx(() => ElevatedButton(
          onPressed: isLoading.value ? null : () async {
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
            } finally { isLoading.value = false; }
          },
          style: ElevatedButton.styleFrom(backgroundColor: _DS.accent, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: isLoading.value
              ? const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Update'),
        )),
      ],
    ));
  }

  void _showCreateStudentDialog() {
    final authController = Get.find<AuthController>();
    String? targetSchoolId;

    if (authController.user.value?.role.toLowerCase() == 'correspondent') {
      if (controller.selectedSchool.value == null) {
        Get.snackbar('Error', 'Please select a school first');
        return;
      }
      targetSchoolId = controller.selectedSchool.value!.id;
    } else {
      targetSchoolId = authController.user.value?.schoolId;
      if (targetSchoolId == null || targetSchoolId.isEmpty) {
        Get.snackbar('Error', 'Associated school profile not found');
        return;
      }
    }

    Get.toNamed(
      AppRoutes.STUDENT_PROFILE_CREATION,
      arguments: {
        'schoolId': targetSchoolId,
        'isEdit': false,
      },
    )?.then((_) {
      if (controller.selectedSchool.value != null)
        controller.getAllStudents(schoolId: controller.selectedSchool.value!.id);
    });
  }
  void _showEditStudentDialog(Student student) {
    final authController = Get.find<AuthController>();
    String? targetSchoolId;

    if (authController.user.value?.role.toLowerCase() == 'correspondent') {
      if (controller.selectedSchool.value == null) {
        Get.snackbar('Error', 'Please select a school first');
        return;
      }
      targetSchoolId = controller.selectedSchool.value!.id;
    } else {
      targetSchoolId = authController.user.value?.schoolId;
      if (targetSchoolId == null || targetSchoolId.isEmpty) {
        Get.snackbar('Error', 'Associated school profile not found');
        return;
      }
    }

    // ✅ Pass student object via Get.arguments
    Get.toNamed(
      AppRoutes.STUDENT_PROFILE_CREATION,
      arguments: {
        'schoolId': targetSchoolId,
        'student': student,   // ← Student object passed here
        'isEdit': true,
        'existingImageUrl': student.studentImage,
      },
    )?.then((_) {
      if (controller.selectedSchool.value != null)
        controller.getAllStudents(schoolId: controller.selectedSchool.value!.id);
    });
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
          style: ElevatedButton.styleFrom(backgroundColor: _DS.danger, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: const Text('Delete'),
        ),
      ],
    ));
  }
  /// Styled text field
  Widget _field(TextEditingController ctrl, String label,
      {TextInputType? keyboardType, bool obscure = false, String? prefix,
        Widget? suffixIcon}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, color: _DS.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
        suffixIcon: suffixIcon,
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
  void _showCreateUserDialog() {
    final authController = Get.find<AuthController>();
    final currentUserRole = authController.user.value?.role?.toLowerCase() ?? '';
    final isCorrespondent = currentUserRole == 'correspondent';
    final emailCtrl = TextEditingController();
    final userNameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    bool obscurePassword = true;

    const validRoles = [
      'correspondent', 'teacher', 'principal', 'viceprincipal',
      'administrator', 'accountant', 'parent'
    ];
    String? selectedRole;

    // Track BOTH — the dropdown displays the human-readable code, but the
    // actual API call needs the school's real id.
    String? selectedSchoolCode;
    String? selectedSchoolId;

    controller.getAllSchools();

    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Create User'),
      content: StatefulBuilder(
        builder: (context, setState) {
          return Obx(() {
            if (!isCorrespondent && selectedSchoolId == null && controller.schools.isNotEmpty) {
              final userSchoolId = authController.user.value?.schoolId;
              final userSchool = controller.schools.firstWhereOrNull((s) => s.id == userSchoolId);
              if (userSchool != null) {
                selectedSchoolId = userSchool.id;
                selectedSchoolCode = userSchool.schoolCode;
              }
            }
            return SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _field(emailCtrl, 'Email'),
                const SizedBox(height: 12),
                _field(userNameCtrl, 'User Name'),
                const SizedBox(height: 12),
                _field(
                  passwordCtrl,
                  'Password',
                  obscure: obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: _DS.textMuted,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => obscurePassword = !obscurePassword),
                  ),
                ),
                const SizedBox(height: 12),
                _field(phoneCtrl, 'Phone'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: selectedRole,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: validRoles.map((r) => DropdownMenuItem(
                    value: r,
                    child: Text(r.toUpperCase()),
                  )).toList(),
                  onChanged: (v) => setState(() => selectedRole = v),
                ),
                const SizedBox(height: 12),
                if (isCorrespondent)
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedSchoolId,
                    decoration: const InputDecoration(labelText: 'School'),
                    items: controller.schools.map((s) => DropdownMenuItem(
                      value: s.id,
                      child: Text('${s.name} (${s.schoolCode})'),
                    )).toList(),
                    onChanged: (v) => setState(() {
                      selectedSchoolId = v;
                      selectedSchoolCode = controller.schools
                          .firstWhereOrNull((s) => s.id == v)?.schoolCode;
                    }),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _DS.surfaceAlt,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _DS.border),
                    ),
                    child: Row(children: [
                      const Icon(Icons.school_rounded, color: _DS.accent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                          controller.schools.firstWhereOrNull(
                                  (s) => s.id == selectedSchoolId)?.name ?? 'Loading...',
                          style: const TextStyle(fontSize: 14))),
                    ]),
                  ),
              ]),
            );
          });
        },
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        Obx(() => ElevatedButton(
          onPressed: userController.isLoading.value ? null : () async {
            if (selectedSchoolId == null) {
              Get.snackbar('Error', 'Please select a school'); return;
            }
            if (selectedRole == null) {
              Get.snackbar('Error', 'Please select a role'); return;
            }
            await userController.createUser(
              email: emailCtrl.text, userName: userNameCtrl.text,
              password: passwordCtrl.text, phoneNo: phoneCtrl.text,
              schoolId: selectedSchoolId!,
              schoolCode: selectedSchoolCode,
              role: selectedRole!,
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: _DS.accent, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: userController.isLoading.value
              ? const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Create'),
        )),
      ],
    ));
  }
  void _showAssignRoleDialog(Map<String, dynamic> user) {
    final validRoles = ['correspondent','teacher','principal','viceprincipal',
      'administrator','parent','accountant'];
    String selectedRole = validRoles.contains(user['role']) ? user['role'] : 'correspondent';

    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Assign Role — ${user['userName']}'),
      content: StatefulBuilder(
        builder: (context, setState) => DropdownButtonFormField<String>(
          isExpanded: true,
          value: selectedRole,
          decoration: const InputDecoration(labelText: 'Role'),
          items: validRoles.map((r) => DropdownMenuItem(
              value: r, child: Text(r.toUpperCase()))).toList(),
          onChanged: (r) { if (r != null) setState(() => selectedRole = r); },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () { userController.assignRole(user['_id'], selectedRole); Get.back(); },
          style: ElevatedButton.styleFrom(backgroundColor: _DS.accent, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _field(emailCtrl, 'Email'),
          const SizedBox(height: 12),
          _field(userNameCtrl, 'User Name'),
          const SizedBox(height: 12),
          _field(phoneCtrl, 'Phone'),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        Obx(() => ElevatedButton(
          onPressed: isLoading.value ? null : () async {
            isLoading.value = true;
            try {
              await userController.updateUser(userId: user['_id'], email: emailCtrl.text,
                  userName: userNameCtrl.text, phoneNo: phoneCtrl.text);
              Get.back();
              Get.snackbar('Success', 'User updated',
                  backgroundColor: _DS.success, colorText: Colors.white,
                  snackPosition: SnackPosition.TOP);
              final schoolId = controller.selectedSchool.value?.id ??
                  Get.find<AuthController>().user.value?.schoolId;
              if (schoolId != null)
                await userController.loadUsers(schoolId: schoolId,
                    role: userController.selectedRole.value);
              final currentUserId = Get.find<AuthController>().user.value?.id;
              if (currentUserId == user['_id'])
                await Get.find<AuthController>().handleUserUpdateSuccess();
            } catch (e) {
              Get.back();
              Get.snackbar('Error', 'Failed to update user',
                  backgroundColor: _DS.danger, colorText: Colors.white,
                  snackPosition: SnackPosition.TOP);
            } finally { isLoading.value = false; }
          },
          style: ElevatedButton.styleFrom(backgroundColor: _DS.accent, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: isLoading.value
              ? const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        Obx(() => ElevatedButton(
          onPressed: userController.isLoading.value ? null :
              () async { await userController.deleteUser(user['_id']); Get.back(); },
          style: ElevatedButton.styleFrom(backgroundColor: _DS.danger, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: userController.isLoading.value
              ? const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              _detailRow('Name', section.name),
              _detailRow('Class', section.className ?? 'N/A'),
              _detailRow('Room', section.roomNumber ?? 'N/A'),
              _detailRow('Capacity', section.capacity?.toString() ?? 'N/A'),
              if (section.classTeachers?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                const Text('Teachers', style: TextStyle(fontWeight: FontWeight.w700,
                    fontSize: 14, color: _DS.textPrimary)),
                const SizedBox(height: 8),
                ...section.classTeachers!.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    const Icon(Icons.person_rounded, size: 15, color: _DS.accent),
                    const SizedBox(width: 8),
                    Text(t['userName'] ?? 'Unknown', style: const TextStyle(fontSize: 14)),
                  ]),
                )),
              ],
            ]),
      ),
      actions: [TextButton(onPressed: () => Get.back(), child: const Text('Close'))],
    ));
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 80, child: Text('$label:', style: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 13, color: _DS.textSecondary))),
        Expanded(child: Text(value, style: const TextStyle(
            fontSize: 13, color: _DS.textPrimary))),
      ]),
    );
  }

  // Club dialogs — all logic identical, only styling updated
  void _showClassSelectionForBulkClub(Map<String, List<Student>> studentsByClass) {
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Select Class'),
      content: Column(mainAxisSize: MainAxisSize.min,
        children: studentsByClass.entries.map((entry) {
          final classObj = controller.classes.firstWhereOrNull((c) => c.id == entry.key);
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
      actions: [TextButton(onPressed: () => Get.back(), child: const Text('Cancel'))],
    ));
  }

  void _showStudentClubDialog(Student student, SchoolClass? selectedClass) {
    if (selectedClass == null) { Get.snackbar('Error', 'Please select a class first'); return; }
    final clubController = Get.find<ClubController>();
    final clubsController = Get.put(ClubsController());
    final availableClubs = <Club>[].obs;
    final dialogLoading = false.obs;
    availableClubs.value = clubsController.getClubsByClass(selectedClass.id);

    Get.dialog(
      Dialog(backgroundColor: Colors.transparent, insetPadding: const EdgeInsets.all(16),
        child: GradientDialog(
          header: dialogHeader(title: 'Club Management',
              subtitle: '${student.name ?? 'N/A'} • ${selectedClass.name}',
              icon: Icons.sports_soccer),
          body: Obx(() {
            if (availableClubs.isEmpty)
              return const Center(child: Text('No clubs available', style: TextStyle(color: Colors.grey)));
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: availableClubs.length,
              itemBuilder: (_, index) {
                final club = availableClubs[index];
                final isSelected = student.clubs?.contains(club.id) ?? false;
                return clubTile(
                  name: club.name, description: club.description, selected: isSelected,
                  onTap: dialogLoading.value ? () {} : () async {
                    try {
                      dialogLoading.value = true;
                      if (!isSelected) {
                        await clubController.addStudentToClub(club.id, student.id);
                        student.clubs ??= [];
                        student.clubs!.add(club.id);
                      } else {
                        await clubController.removeStudentFromClub(club.id, student.id);
                        student.clubs?.remove(club.id);
                      }
                      availableClubs.refresh();
                    } catch (e) {
                      Get.snackbar('Error', 'Failed to update club',
                          backgroundColor: Colors.red.shade400, colorText: Colors.white);
                    } finally { dialogLoading.value = false; }
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
              Get.snackbar('Success', 'Club assignments updated',
                  backgroundColor: const Color(0xFF38EF7D), colorText: Colors.white);
              if (controller.selectedSchool.value != null)
                await controller.getAllStudents(schoolId: controller.selectedSchool.value!.id);
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
      Dialog(backgroundColor: Colors.transparent, insetPadding: const EdgeInsets.all(16),
        child: GradientDialog(
          header: dialogHeader(title: 'Bulk Club Assignment',
              subtitle: '${selectedClass.name} • ${students.length} students',
              icon: Icons.group_add),
          body: Obx(() {
            if (isLoading.value) return const Center(child: CircularProgressIndicator());
            if (availableClubs.isEmpty)
              return const Center(child: Text('No clubs available',
                  style: TextStyle(color: Colors.grey)));
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: availableClubs.length,
              itemBuilder: (_, index) {
                final club = availableClubs[index];
                final clubId = club['_id'];
                final allInClub = students.every((s) => s.clubs?.contains(clubId) ?? false);
                return clubTile(
                  name: club['name'], description: club['description'] ?? '',
                  selected: allInClub,
                  onTap: dialogLoading.value ? () {} : () async {
                    try {
                      dialogLoading.value = true;
                      final studentIds = students.map((s) => s.id).toList();
                      await clubController.toggleStudentsInClub(clubId, studentIds,
                          !allInClub, classId: selectedClass.id);
                      for (final s in students) {
                        s.clubs ??= [];
                        if (!allInClub) s.clubs!.add(clubId);
                        else s.clubs!.remove(clubId);
                      }
                      availableClubs.refresh();
                    } catch (e) {
                      Get.snackbar('Error', 'Failed to update clubs',
                          backgroundColor: Colors.red.shade400, colorText: Colors.white);
                    } finally { dialogLoading.value = false; }
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
              Get.snackbar('Success', 'Bulk club assignment completed',
                  backgroundColor: const Color(0xFF38EF7D), colorText: Colors.white);
              if (controller.selectedSchool.value != null)
                await controller.getAllStudents(schoolId: controller.selectedSchool.value!.id);
            },
          )),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _showAssignClubToStudentDialog(Student student) {
    // Identical to original — all API calls preserved
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
      } catch (e) { Get.snackbar('Error', 'Failed to load clubs'); }
      finally { isLoading.value = false; }
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _DS.primary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.add_circle_outline, color: Colors.white, size: 24)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Assign to Club', style: TextStyle(color: Colors.white,
                    fontSize: 18, fontWeight: FontWeight.w700)),
                Text(student.name ?? '', style: TextStyle(
                    color: Colors.white.withOpacity(0.75), fontSize: 13)),
              ])),
            ]),
          ),
          // Body
          Expanded(child: Obx(() {
            if (isLoading.value) return const Center(child: CircularProgressIndicator(color: _DS.accent));
            if (availableClubs.isEmpty)
              return _emptyState(icon: Icons.groups_outlined, title: 'No Clubs',
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
                      color: isAlreadyMember ? _DS.successSoft : (isSelected ? _DS.accentSoft : _DS.surfaceAlt),
                      borderRadius: BorderRadius.circular(_DS.radiusSm),
                      border: Border.all(
                        color: isAlreadyMember ? _DS.success : (isSelected ? _DS.accent : _DS.border),
                        width: isAlreadyMember || isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: CheckboxListTile(
                      title: Text(club['name'] ?? 'Unknown Club',
                          style: TextStyle(fontWeight: FontWeight.w600,
                              color: isAlreadyMember ? _DS.success : _DS.textPrimary)),
                      subtitle: club['description'] != null
                          ? Text(club['description'], style: const TextStyle(
                          color: _DS.textMuted, fontSize: 12))
                          : null,
                      value: isSelected,
                      activeColor: _DS.accent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radiusSm)),
                      secondary: isAlreadyMember ? _badge('Member', bg: _DS.successSoft, fg: _DS.success) : null,
                      onChanged: (v) {
                        if (v == true) selectedClubs.add(clubId);
                        else selectedClubs.remove(clubId);
                      },
                    ),
                  );
                });
              },
            );
          })),
          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _DS.border)),
            ),
            child: Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Get.back(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _DS.textSecondary,
                  side: const BorderSide(color: _DS.border),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radius)),
                ),
                child: const Text('Cancel'),
              )),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: ElevatedButton(
                onPressed: () async {
                  try {
                    final clubsToAdd = selectedClubs.where((id) => !alreadyInClubs.contains(id)).toList();
                    for (final id in clubsToAdd)
                      await clubController.toggleStudentClub(student.id, id, true);
                    Get.back();
                    controller.getAllStudents(schoolId: controller.selectedSchool.value!.id);
                    Get.snackbar('Success', 'Clubs assigned',
                        backgroundColor: _DS.success, colorText: Colors.white);
                  } catch (e) {
                    Get.snackbar('Error', 'Failed to assign clubs',
                        backgroundColor: _DS.danger, colorText: Colors.white);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _DS.accent, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13), elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radius)),
                ),
                child: const Text('Assign Clubs', style: TextStyle(fontWeight: FontWeight.w600)),
              )),
            ]),
          ),
        ]),
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
        studentClubs.value = allClubs.where((c) => studentClubIds.contains(c['_id']))
            .map((c) => Club.fromJson(c)).toList();
      } catch (e) { Get.snackbar('Error', 'Failed to load clubs'); }
      finally { isLoading.value = false; }
    }
    loadStudentClubs();

    Get.dialog(Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        decoration: BoxDecoration(
          color: _DS.surface, borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _DS.border),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _DS.danger,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.remove_circle_outline, color: Colors.white, size: 24)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Remove from Club', style: TextStyle(color: Colors.white,
                    fontSize: 18, fontWeight: FontWeight.w700)),
                Text(student.name ?? '', style: TextStyle(
                    color: Colors.white.withOpacity(0.75), fontSize: 13)),
              ])),
            ]),
          ),
          Expanded(child: Obx(() {
            if (isLoading.value) return const Center(child: CircularProgressIndicator(color: _DS.accent));
            if (studentClubs.isEmpty)
              return _emptyState(icon: Icons.groups_outlined, title: 'No Clubs',
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
                      color: isSelected ? const Color(0xFFFFF1F2) : _DS.surfaceAlt,
                      borderRadius: BorderRadius.circular(_DS.radiusSm),
                      border: Border.all(
                        color: isSelected ? _DS.danger : _DS.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: CheckboxListTile(
                      title: Text(club.name, style: const TextStyle(
                          fontWeight: FontWeight.w600, color: _DS.textPrimary)),
                      subtitle: club.description.isNotEmpty
                          ? Text(club.description, style: const TextStyle(
                          color: _DS.textMuted, fontSize: 12))
                          : null,
                      value: isSelected,
                      activeColor: _DS.danger,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radiusSm)),
                      onChanged: (v) {
                        if (v == true) selectedClubs.add(club.id);
                        else selectedClubs.remove(club.id);
                      },
                    ),
                  );
                });
              },
            );
          })),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: _DS.border))),
            child: Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Get.back(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _DS.textSecondary,
                  side: const BorderSide(color: _DS.border),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radius)),
                ),
                child: const Text('Cancel'),
              )),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: ElevatedButton(
                onPressed: () async {
                  try {
                    for (final id in selectedClubs)
                      await clubController.toggleStudentClub(student.id, id, false);
                    Get.back();
                    controller.getAllStudents(schoolId: controller.selectedSchool.value!.id);
                    Get.snackbar('Success', 'Clubs removed',
                        backgroundColor: _DS.success, colorText: Colors.white);
                  } catch (e) {
                    Get.snackbar('Error', 'Failed to remove clubs',
                        backgroundColor: _DS.danger, colorText: Colors.white);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _DS.danger, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13), elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radius)),
                ),
                child: const Text('Remove Clubs', style: TextStyle(fontWeight: FontWeight.w600)),
              )),
            ]),
          ),
        ]),
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
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _field(amountController, 'Fee Amount', keyboardType: TextInputType.number, prefix: '₹ '),
        const SizedBox(height: 12),
        _field(descriptionController, 'Description'),
      ]),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
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
          style: ElevatedButton.styleFrom(backgroundColor: _DS.accent, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: const Text('Save'),
        ),
      ],
    ));
  }

  void _showClassFilterSheet(Rxn<SchoolClass> selectedClass,
      Rxn<Section> selectedSection) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: _DS.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
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
              const Text('Select Class',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
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
          // All Classes option
          ListTile(
            leading: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: selectedClass.value == null
                    ? _DS.accentSoft : _DS.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.all_inclusive_rounded,
                  size: 18,
                  color: selectedClass.value == null
                      ? _DS.accent : _DS.textMuted),
            ),
            title: const Text('All Classes',
                style: TextStyle(fontWeight: FontWeight.w600,
                    fontSize: 14, color: _DS.textPrimary)),
            trailing: selectedClass.value == null
                ? Icon(Icons.check_circle_rounded,
                color: _DS.accent, size: 20)
                : null,
            onTap: () {
              selectedClass.value = null;
              selectedSection.value = null;
              _loadStudentsByFilters(null, null);
              Get.back();
            },
          ),
          // Class list
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: Obx(() {
              final sorted = ClassUtils.sortClasses(controller.classes);
              return ListView.builder(
                shrinkWrap: true,
                itemCount: sorted.length,
                itemBuilder: (_, i) {
                  final c = sorted[i];
                  final isSelected = selectedClass.value?.id == c.id;
                  return ListTile(
                    leading: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: isSelected ? _DS.accentSoft : _DS.surfaceAlt,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        ClassUtils.getClassIcon(c.name),
                        size: 18,
                        color: isSelected ? _DS.accent : _DS.textMuted,
                      ),
                    ),
                    title: Text(c.name,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 14,
                          color: isSelected ? _DS.accent : _DS.textPrimary,
                        )),
                    trailing: isSelected
                        ? Icon(Icons.check_circle_rounded,
                        color: _DS.accent, size: 20)
                        : null,
                    onTap: () {
                      selectedClass.value = c;
                      selectedSection.value = null;
                      if (controller.selectedSchool.value != null)
                        controller.getAllSections(
                            classId: c.id,
                            schoolId: controller.selectedSchool.value!.id);
                      _loadStudentsByFilters(c, null);
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

  void _showSectionFilterSheet(Rxn<Section> selectedSection) {
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
              const Text('Select Section',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
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
          ListTile(
            leading: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: selectedSection.value == null
                    ? _DS.accentSoft : _DS.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.all_inclusive_rounded,
                  size: 18,
                  color: selectedSection.value == null
                      ? _DS.accent : _DS.textMuted),
            ),
            title: const Text('All Sections',
                style: TextStyle(fontWeight: FontWeight.w600,
                    fontSize: 14, color: _DS.textPrimary)),
            trailing: selectedSection.value == null
                ? Icon(Icons.check_circle_rounded, color: _DS.accent, size: 20)
                : null,
            onTap: () {
              selectedSection.value = null;
              _loadStudentsByFilters(null, null);
              Get.back();
            },
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: Obx(() {
              if (controller.sections.isEmpty)
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Select a class first',
                      style: TextStyle(color: _DS.textMuted, fontSize: 13)),
                );
              return ListView.builder(
                shrinkWrap: true,
                itemCount: controller.sections.length,
                itemBuilder: (_, i) {
                  final s = controller.sections[i];
                  final isSelected = selectedSection.value?.id == s.id;
                  return ListTile(
                    leading: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: isSelected ? _DS.accentSoft : _DS.surfaceAlt,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.group_rounded,
                          size: 18,
                          color: isSelected ? _DS.accent : _DS.textMuted),
                    ),
                    title: Text(s.name,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 14,
                          color: isSelected ? _DS.accent : _DS.textPrimary,
                        )),
                    trailing: isSelected
                        ? Icon(Icons.check_circle_rounded,
                        color: _DS.accent, size: 20)
                        : null,
                    onTap: () {
                      selectedSection.value = s;
                      _loadStudentsByFilters(selectedSection.value as SchoolClass?, s);
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

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ─── Attendance Tab (StatefulWidget — kept structurally identical) ────────────

class _AttendanceTab extends StatefulWidget {
  @override
  State<_AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<_AttendanceTab> {
  // All original fields preserved
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
  final TextEditingController _startYearController = TextEditingController(text: "2025");
  final TextEditingController _endYearController = TextEditingController(text: "2026");
  List<Map<String, dynamic>> attendanceRecords = [];
  List<Map<String, dynamic>> historyRecords = [];
  SchoolClass? selectedClass;
  //String get academicYear => "${_startYearController.text}-${_endYearController.text}";
  String get academicYear => AcademicYearUtils.getCurrentAcademicYear();


  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<StudentController>()) {
      Get.lazyPut<StudentController>(() => StudentController(), fenix: true);
    }
    isHistoryMode = !canMarkAttendance;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final school = schoolController.selectedSchool.value;
      if (school != null) _onSchoolChanged(school);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _DS.bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(children: [
          // ── Mode toggle ─────────────────────────────────────────
          _buildModeToggle(),
          const SizedBox(height: 12),

          // ── Chips row ───────────────────────────────────────────
          _buildChipsRow(),
          const SizedBox(height: 12),

          // ── Date / year selectors ───────────────────────────────
          _buildDateSelectors(),
          const SizedBox(height: 12),

          // ── Summary ─────────────────────────────────────────────
          if (!isHistoryMode && attendanceRecords.isNotEmpty) ...[
            _buildCollapsibleSummary(false, false),
            const SizedBox(height: 12),
          ],

          // ── List ────────────────────────────────────────────────
          SizedBox(height: 420, child: _buildContentArea(false)),
          const SizedBox(height: 12),

          // ── Save ────────────────────────────────────────────────
          if (!isHistoryMode &&
              attendanceRecords.isNotEmpty &&
              canMarkAttendance)
            _primaryBtn(
              label: 'Save Attendance',
              onPressed: _saveAttendance,
              icon: Icons.save_rounded,
            ),
        ]),
      ),
    );
  }

// ── Chips row: class + date/range indicator ──────────────────────
  Widget _buildChipsRow() {
    return Row(children: [
      // Class chip
      GestureDetector(
        onTap: _showClassSheet,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selectedClass != null ? _DS.accentSoft : _DS.surface,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: selectedClass != null ? _DS.accent : _DS.border,
              width: selectedClass != null ? 1.5 : 1,
            ),
            boxShadow: _DS.shadow,
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.class_rounded,
                size: 14,
                color: selectedClass != null ? _DS.accent : _DS.textMuted),
            const SizedBox(width: 6),
            Text(
              selectedClass?.name ?? 'Select Class',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selectedClass != null
                    ? _DS.accent
                    : _DS.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 14,
                color: selectedClass != null ? _DS.accent : _DS.textMuted),
          ]),
        ),
      ),
      const Spacer(),
      // Academic year badge
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _DS.surfaceAlt,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: _DS.border),
        ),
        child: Text(
          academicYear,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _DS.textSecondary,
          ),
        ),
      ),
    ]);
  }

// ── Class bottom sheet ───────────────────────────────────────────
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
              color: _DS.border,
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
                        style: TextStyle(
                            color: _DS.textMuted, fontSize: 14)),
                  ),
                );
              return ListView.builder(
                shrinkWrap: true,
                itemCount: classes.length,
                itemBuilder: (_, i) {
                  final c = classes[i];
                  final isSelected = selectedClass?.id == c.id;
                  return ListTile(
                    leading: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _DS.accentSoft
                            : _DS.surfaceAlt,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.class_rounded,
                          size: 18,
                          color:
                          isSelected ? _DS.accent : _DS.textMuted),
                    ),
                    title: Text(c.name,
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
                    onTap: () {
                      if (mounted) setState(() => selectedClass = c);
                      _onFilterChanged();
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

// ── Date / year row ──────────────────────────────────────────────
  Widget _buildDateSelectors() {
    return _card(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Year range
        Row(children: [
          Expanded(
            child: _field(_startYearController, 'Start Year',
                keyboardType: TextInputType.number),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('—',
                style: TextStyle(fontSize: 18, color: _DS.textMuted)),
          ),
          Expanded(
            child: _field(_endYearController, 'End Year',
                keyboardType: TextInputType.number),
          ),
        ]),
        const SizedBox(height: 12),
        // Date selector
        isHistoryMode
            ? _buildDateRangeSelector()
            : _buildSingleDateSelector(),
      ]),
    );
  }

// ── keep _buildModeToggle exactly as before ──────────────────────
// ── keep _buildCollapsibleSummary exactly as before ─────────────
// ── keep _buildContentArea exactly as before ────────────────────
// ── keep _buildDailyList exactly as before ──────────────────────
// ── keep _buildHistoryList exactly as before ────────────────────
// ── keep all API methods exactly as before ──────────────────────
  Widget _buildModeToggle() {
    if (!canMarkAttendance && canViewAttendance) {
      return _card(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          _iconBox(Icons.history_rounded),
          const SizedBox(width: 12),
          const Text('History', style: TextStyle(fontWeight: FontWeight.w600,fontSize: 12,
              color: _DS.textPrimary)),
          const Spacer(),
          _badge('View Only'),
        ]),
      );
    }
    return _card(
      padding: const EdgeInsets.all(6),
      child: SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: false,
              label: Text('Mark Daily', style: TextStyle(fontSize: 13)),
              icon: Icon(Icons.today_rounded, size: 16)),
          ButtonSegment(value: true,
              label: Text('History', style: TextStyle(fontSize: 13)),
              icon: Icon(Icons.history_rounded, size: 16)),
        ],
        selected: {isHistoryMode},
        onSelectionChanged: (v) {
          if (mounted) { setState(() => isHistoryMode = v.first); _onFilterChanged(); }
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
      final hasSelections = schoolController.selectedSchool.value != null && selectedClass != null;
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
    return Row(children: [
      const Icon(Icons.school_rounded, color: _DS.accent, size: 18),
      const SizedBox(width: 6),
      Flexible(child: Text(schoolController.selectedSchool.value?.name ?? '',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13,
              color: _DS.textPrimary),
          overflow: TextOverflow.ellipsis)),
      const SizedBox(width: 12),
      const Icon(Icons.class_rounded, color: _DS.accent, size: 16),
      const SizedBox(width: 4),
      Text(selectedClass?.name ?? '',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12,
              color: _DS.textSecondary)),
      const Spacer(),
      GestureDetector(
        onTap: () { if (mounted) setState(() => _isFiltersExpanded = true); },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: _DS.accentSoft,
              borderRadius: BorderRadius.circular(100)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.tune_rounded, size: 13, color: _DS.accent),
            SizedBox(width: 4),
            Text('Edit', style: TextStyle(fontSize: 12, color: _DS.accent,
                fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildFullAttendanceSelectors(bool isLandscape, bool isTablet) {
    return Column(children: [
      Row(children: [
        const Icon(Icons.tune_rounded, color: _DS.accent, size: 18),
        const SizedBox(width: 8),
        const Text('Filters', style: TextStyle(fontWeight: FontWeight.w700,
            fontSize: 15, color: _DS.textPrimary)),
        const Spacer(),
        if (schoolController.selectedSchool.value != null && selectedClass != null)
          GestureDetector(
            onTap: () { if (mounted) setState(() => _isFiltersExpanded = false); },
            child: const Icon(Icons.expand_less_rounded, color: _DS.textMuted),
          ),
      ]),
      const SizedBox(height: 14),
      isLandscape && isTablet
          ? Row(children: [
       //  Expanded(child:
       // // _buildSchoolSelector()),
        const SizedBox(width: 12),
        Expanded(child: _buildClassSelector()),
      ])
          : Column(children: [
        //_buildSchoolSelector(),
        const SizedBox(height: 10),
        _buildClassSelector(),
      ]),
      const SizedBox(height: 12),
      // Year range
      Row(children: [
        Expanded(child: _field(_startYearController, 'Start Year',
            keyboardType: TextInputType.number)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('—', style: TextStyle(fontSize: 18, color: _DS.textMuted)),
        ),
        Expanded(child: _field(_endYearController, 'End Year',
            keyboardType: TextInputType.number)),
      ]),
      const SizedBox(height: 12),
      isHistoryMode ? _buildDateRangeSelector() : _buildSingleDateSelector(),
    ]);
  }

  Widget _buildSchoolSelector() {
    return Obx(() {
      final schools = schoolController.schools;
      final selectedId = schoolController.selectedSchool.value?.id;
      return _dropdown<School>(
        value: selectedId == null ? null : schools.firstWhereOrNull((s) => s.id == selectedId),
        hint: 'Select School',
        icon: Icons.school_rounded,
        selectedItemBuilder: schools.map((s) => Text(s.name, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _DS.textPrimary, fontSize: 15))).toList(),
        items: schools.map((s) => DropdownMenuItem<School>(
          value: s,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.school_rounded, color: _DS.accent, size: 16),
            const SizedBox(width: 10),
            Expanded(child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis)),
          ]),
        )).toList(),
        onChanged: _onSchoolChanged,
      );
    });
  }

  Widget _buildClassSelector() {
    return Obx(() {
      final classes = schoolController.classes;
      final selectedId = selectedClass?.id;
      return _dropdown<SchoolClass>(
        value: selectedId == null ? null : classes.firstWhereOrNull((c) => c.id == selectedId),
        hint: 'Select Class',
        icon: Icons.class_rounded,
        selectedItemBuilder: classes.map((c) => Text(c.name, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _DS.textPrimary, fontSize: 15))).toList(),
        items: classes.map((c) => DropdownMenuItem<SchoolClass>(
          value: c,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.class_rounded, color: _DS.accent, size: 16),
            const SizedBox(width: 10),
            Expanded(child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis)),
          ]),
        )).toList(),
        onChanged: (c) {
          if (mounted) { setState(() => selectedClass = c); _onFilterChanged(); }
        },
      );
    });
  }

  Widget _buildSingleDateSelector() {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(context: context, initialDate: selectedDate,
            firstDate: DateTime(2020), lastDate: DateTime(2030));
        if (d != null && mounted) { setState(() => selectedDate = d); _onFilterChanged(); }
      },
      borderRadius: BorderRadius.circular(_DS.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: _DS.surfaceAlt, borderRadius: BorderRadius.circular(_DS.radiusSm),
          border: Border.all(color: _DS.border),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today_rounded, color: _DS.accent, size: 18),
          const SizedBox(width: 12),
          Text('Date: ${selectedDate.toString().split(' ')[0]}',
              style: const TextStyle(fontSize: 14, color: _DS.textPrimary)),
          const Spacer(),
          const Icon(Icons.arrow_drop_down_rounded, color: _DS.textMuted),
        ]),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Row(children: [
      Expanded(child: InkWell(
        onTap: () async {
          final d = await showDatePicker(context: context, initialDate: startDate,
              firstDate: DateTime(2020), lastDate: DateTime.now());
          if (d != null && mounted) { setState(() => startDate = d); _onFilterChanged(); }
        },
        borderRadius: BorderRadius.circular(_DS.radiusSm),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _DS.surfaceAlt,
              borderRadius: BorderRadius.circular(_DS.radiusSm),
              border: Border.all(color: _DS.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('From', style: TextStyle(color: _DS.textMuted, fontSize: 11,
                fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(startDate.toString().split(' ')[0],
                style: const TextStyle(fontSize: 14, color: _DS.textPrimary,
                    fontWeight: FontWeight.w500)),
          ]),
        ),
      )),
      const SizedBox(width: 10),
      Expanded(child: InkWell(
        onTap: () async {
          final d = await showDatePicker(context: context, initialDate: endDate,
              firstDate: DateTime(2020), lastDate: DateTime.now());
          if (d != null && mounted) { setState(() => endDate = d); _onFilterChanged(); }
        },
        borderRadius: BorderRadius.circular(_DS.radiusSm),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _DS.surfaceAlt,
              borderRadius: BorderRadius.circular(_DS.radiusSm),
              border: Border.all(color: _DS.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('To', style: TextStyle(color: _DS.textMuted, fontSize: 11,
                fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(endDate.toString().split(' ')[0],
                style: const TextStyle(fontSize: 14, color: _DS.textPrimary,
                    fontWeight: FontWeight.w500)),
          ]),
        ),
      )),
    ]);
  }

  Widget _buildCollapsibleSummary(bool isLandscape, bool isTablet) {
    final total = attendanceRecords.length;
    final present = attendanceRecords.where((r) => r['status'] == 'present').length;
    final absent = total - present;

    return _card(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          _iconBox(Icons.analytics_rounded),
          const SizedBox(width: 12),
          const Text('Summary', style: TextStyle(fontWeight: FontWeight.w700,
              fontSize: 15, color: _DS.textPrimary)),
          const Spacer(),
          _badge('$present/$total Present', bg: _DS.successSoft, fg: _DS.success),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _summaryTile('Total', total, _DS.accent, _DS.accentSoft)),
          const SizedBox(width: 10),
          Expanded(child: _summaryTile('Present', present, _DS.success, _DS.successSoft)),
          const SizedBox(width: 10),
          Expanded(child: _summaryTile('Absent', absent, _DS.danger, _DS.dangerSoft)),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: ElevatedButton(
            onPressed: () => _bulkUpdateStatus('present'),
            style: ElevatedButton.styleFrom(backgroundColor: _DS.successSoft,
                foregroundColor: _DS.success, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radiusSm))),
            child: const Text('All Present', style: TextStyle(fontWeight: FontWeight.w600)),
          )),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton(
            onPressed: () => _bulkUpdateStatus('absent'),
            style: ElevatedButton.styleFrom(backgroundColor: _DS.dangerSoft,
                foregroundColor: _DS.danger, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radiusSm))),
            child: const Text('All Absent', style: TextStyle(fontWeight: FontWeight.w600)),
          )),
        ]),
      ]),
    );
  }

  Widget _summaryTile(String label, int value, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(_DS.radiusSm)),
      child: Column(children: [
        Text(value.toString(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: fg)),
        Text(label, style: TextStyle(fontSize: 11, color: fg.withOpacity(0.8),
            fontWeight: FontWeight.w600)),
      ]),
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
    if (attendanceRecords.isEmpty)
      return const Center(child: Text('No students found',
          style: TextStyle(fontSize: 14, color: _DS.textMuted)));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: attendanceRecords.length,
      itemBuilder: (_, i) {
        final r = attendanceRecords[i];
        final isPresent = _normalizeStatus(r['status']) == 'present';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isPresent ? _DS.successSoft : _DS.dangerSoft,
            borderRadius: BorderRadius.circular(_DS.radiusSm),
            border: Border.all(color: isPresent ? _DS.success.withOpacity(0.3)
                : _DS.danger.withOpacity(0.3)),
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: isPresent ? _DS.success : _DS.danger,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Text(r['rollNumber']?.toString() ?? '?',
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w700, fontSize: 12))),
            ),
            const SizedBox(width: 12),
            Expanded(child: SingleChildScrollView(
              scrollDirection: Axis.horizontal, // <-- Crucial step
              physics: const BouncingScrollPhysics(),
              child: Text(r['studentName'] ?? 'Unknown',maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600,
                      color: _DS.textPrimary, fontSize: 14)),
            )),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Radio<String>(
                value: 'present', groupValue: _normalizeStatus(r['status']),
                onChanged: canMarkAttendance ? (v) {
                  if (mounted && v != null) setState(() => attendanceRecords[i]['status'] = v);
                } : null,
                activeColor: _DS.success,
              ),
              const Text('P', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: _DS.success)),
              const SizedBox(width: 4),
              Radio<String>(
                value: 'absent', groupValue: _normalizeStatus(r['status']),
                onChanged: canMarkAttendance ? (v) {
                  if (mounted && v != null) setState(() => attendanceRecords[i]['status'] = v);
                } : null,
                activeColor: _DS.danger,
              ),
              const Text('A', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: _DS.danger)),
            ]),
          ]),
        );
      },
    );
  }

  Widget _buildHistoryList() {
    if (historyRecords.isEmpty)
      return const Center(child: Text('No history found',
          style: TextStyle(fontSize: 14, color: _DS.textMuted)));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: historyRecords.length,
      itemBuilder: (_, i) {
        final item = historyRecords[i];
        final records = item['records'] ?? [];
        final present = records.where((r) => r['status'] == 'present').length;
        final absent = records.where((r) => r['status'] == 'absent').length;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: _DS.surfaceAlt,
              borderRadius: BorderRadius.circular(_DS.radiusSm),
              border: Border.all(color: _DS.border)),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            title: Text(item['date']?.toString().split('T')[0] ?? '',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
                    color: _DS.textPrimary)),
            subtitle: Text('By: ${item['takenBy']?['userName'] ?? 'Unknown'}',
                style: const TextStyle(fontSize: 12, color: _DS.textMuted)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              _badge('$present P', bg: _DS.successSoft, fg: _DS.success),
              const SizedBox(width: 6),
              _badge('$absent A', bg: _DS.dangerSoft, fg: _DS.danger),
              const SizedBox(width: 4),
              const Icon(Icons.expand_more_rounded, color: _DS.textMuted),
            ]),
            children: records.map<Widget>((s) => ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: s['status'] == 'present' ? _DS.success : _DS.danger,
                child: Text(s['rollNumber']?.toString() ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 11)),
              ),
              title: Text(s['studentName'] ?? '',
                  style: const TextStyle(fontSize: 13, color: _DS.textPrimary)),
            )).toList(),
          ),
        );
      },
    );
  }

  // All API methods — completely unchanged
  String _normalizeStatus(String? status) {
    final v = status?.toLowerCase();
    return (v == 'present' || v == 'absent') ? v! : 'present';
  }

  void _onSchoolChanged(School? school) {
    schoolController.selectedSchool.value = school;
    if (mounted) setState(() { selectedClass = null; attendanceRecords.clear(); historyRecords.clear(); });
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
    if (schoolController.selectedSchool.value == null || selectedClass == null) return;
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
        attendanceRecords = List<Map<String, dynamic>>.from(sheet).map((r) {
          r['status'] = _normalizeStatus(r['status']); return r;
        }).toList();
      });
    } else {
      final students = await attendanceController.getStudentsForAttendance(
        schoolId: schoolController.selectedSchool.value!.id,
        classId: selectedClass!.id,
      );
      if (students != null && mounted) {
        setState(() {
          attendanceRecords = List<Map<String, dynamic>>.from(students).map((s) => {
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
      setState(() => historyRecords = List<Map<String, dynamic>>.from(response));
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
    if (mounted) setState(() { for (final r in attendanceRecords) r['status'] = status; });
  }
}

// ─── Fee Structure Tab (unchanged API, improved UI) ───────────────────────────

class _FeeStructureTab extends StatefulWidget {
  @override
  State<_FeeStructureTab> createState() => _FeeStructureTabState();
}

class _FeeStructureTabState extends State<_FeeStructureTab> {
  final feeController    = Get.put(FeeStructureController());
  final schoolController = Get.find<SchoolController>();
  final authController   = Get.find<AuthController>();

  SchoolClass? selectedClass;
  String selectedStudentType = 'old';

  // ✅ Correct controller names matching _calculateAndSetAnnualFee
  final _admissionFeeCtrl    = TextEditingController();
  final _firstTermCtrl       = TextEditingController();
  final _secondTermCtrl      = TextEditingController();
  final _annualFeeCtrl       = TextEditingController();
  final _busFirstTermCtrl    = TextEditingController();
  final _busSecondTermCtrl   = TextEditingController();

  String get currentUserRole =>
      authController.user.value?.role?.toLowerCase() ?? '';

  bool get canSetFee =>
      ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/feestructure/set');

  @override
  void initState() {
    super.initState();
    // ✅ Auto-calculate annual fee when any term changes
    _admissionFeeCtrl.addListener(_calculateAndSetAnnualFee);
    _firstTermCtrl.addListener(_calculateAndSetAnnualFee);
    _secondTermCtrl.addListener(_calculateAndSetAnnualFee);
    _busFirstTermCtrl.addListener(_calculateAndSetAnnualFee);
    _busSecondTermCtrl.addListener(_calculateAndSetAnnualFee);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final school = schoolController.selectedSchool.value;
      if (school != null) schoolController.getAllClasses(school.id);
    });
  }

  @override
  void dispose() {
    _admissionFeeCtrl.dispose();
    _firstTermCtrl.dispose();
    _secondTermCtrl.dispose();
    _annualFeeCtrl.dispose();
    _busFirstTermCtrl.dispose();
    _busSecondTermCtrl.dispose();
    super.dispose();
  }

  void _calculateAndSetAnnualFee() {
    final double admission  = double.tryParse(_admissionFeeCtrl.text)  ?? 0.0;
    final double firstTerm  = double.tryParse(_firstTermCtrl.text)  ?? 0.0;
    final double secondTerm = double.tryParse(_secondTermCtrl.text) ?? 0.0;
    final double busFirst   = double.tryParse(_busFirstTermCtrl.text) ?? 0.0;
    final double busSecond  = double.tryParse(_busSecondTermCtrl.text) ?? 0.0;
    final double total = admission + firstTerm + secondTerm + busFirst + busSecond;
    _annualFeeCtrl.text = total % 1 == 0
        ? total.toInt().toString()
        : total.toStringAsFixed(2);
  }

  void _clearForm() {
    _admissionFeeCtrl.clear();
    _firstTermCtrl.clear();
    _secondTermCtrl.clear();
    _annualFeeCtrl.clear();
    _busFirstTermCtrl.clear();
    _busSecondTermCtrl.clear();
  }

  // ✅ Fixed: single consistent signature
  Future<void> _loadFeeStructure(String schoolId, String classId) async {
    final data = await feeController.getFeeStructureByClass(
      schoolId, classId,
      type: selectedStudentType,
    );
    final feeHead = data?['feeHead'] ?? data?['data']?['feeHead'] ?? {};
    if (mounted) {
      setState(() {
        _admissionFeeCtrl.text  = feeHead['admissionFee']?.toString()    ?? '';
        _firstTermCtrl.text     = feeHead['firstTermAmt']?.toString()     ?? '';
        _secondTermCtrl.text    = feeHead['secondTermAmt']?.toString()    ?? '';
        _busFirstTermCtrl.text  = feeHead['busFirstTermAmt']?.toString()  ?? '';
        _busSecondTermCtrl.text = feeHead['busSecondTermAmt']?.toString() ?? '';
        _calculateAndSetAnnualFee();
      });
    }
  }

  void _onClassSelected(SchoolClass cls) {
    setState(() => selectedClass = cls);
    final schoolId = schoolController.selectedSchool.value?.id;
    if (schoolId != null) _loadFeeStructure(schoolId, cls.id);
  }

  void _onStudentTypeSelected(String type) {
    setState(() => selectedStudentType = type);
    final schoolId = schoolController.selectedSchool.value?.id;
    if (schoolId != null && selectedClass != null)
      _loadFeeStructure(schoolId, selectedClass!.id);
  }

  void _saveFeeStructure() {
    final schoolId = schoolController.selectedSchool.value?.id
        ?? authController.user.value?.schoolId;
    if (schoolId == null) {
      Get.snackbar('Error', 'School not found',
          backgroundColor: _DS.danger, colorText: Colors.white);
      return;
    }
    if (selectedClass == null) {
      Get.snackbar('Error', 'Please select a class',
          backgroundColor: _DS.danger, colorText: Colors.white);
      return;
    }
    feeController.setFeeStructure(
      schoolId: schoolId,
      classId:  selectedClass!.id,
      type:     selectedStudentType,
      feeHead: {
        'admissionFee':     double.tryParse(_admissionFeeCtrl.text)  ?? 0,
        'firstTermAmt':     double.tryParse(_firstTermCtrl.text)     ?? 0,
        'secondTermAmt':    double.tryParse(_secondTermCtrl.text)    ?? 0,
        'annualFee':        double.tryParse(_annualFeeCtrl.text)     ?? 0,
        'busFirstTermAmt':  double.tryParse(_busFirstTermCtrl.text)  ?? 0,
        'busSecondTermAmt': double.tryParse(_busSecondTermCtrl.text) ?? 0,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _DS.bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 8, 0, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Filter chips ──────────────────────────────────────────
          Row(children: [
            GestureDetector(
              onTap: _showClassSheet,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: selectedClass != null ? _DS.accentSoft : _DS.surface,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: selectedClass != null ? _DS.accent : _DS.border,
                    width: selectedClass != null ? 1.5 : 1,
                  ),
                  boxShadow: _DS.shadow,
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.class_rounded, size: 14,
                      color: selectedClass != null ? _DS.accent : _DS.textMuted),
                  const SizedBox(width: 6),
                  Text(selectedClass?.name ?? 'Select Class',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                          color: selectedClass != null ? _DS.accent : _DS.textSecondary)),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 14,
                      color: selectedClass != null ? _DS.accent : _DS.textMuted),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _showStudentTypeSheet,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
                decoration: BoxDecoration(
                  color: selectedStudentType == 'new' ? _DS.successSoft : _DS.accentSoft,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: selectedStudentType == 'new' ? _DS.success : _DS.accent,
                    width: 1.5,
                  ),
                  boxShadow: _DS.shadow,
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(selectedStudentType == 'new'
                      ? Icons.person_add_rounded : Icons.school_rounded,
                      size: 14,
                      color: selectedStudentType == 'new' ? _DS.success : _DS.accent),
                  const SizedBox(width: 6),
                  Text(selectedStudentType == 'new' ? 'New Students' : 'Old Students',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                          color: selectedStudentType == 'new' ? _DS.success : _DS.accent)),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 14,
                      color: selectedStudentType == 'new' ? _DS.success : _DS.accent),
                ]),
              ),
            ),
          ]),

          const SizedBox(height: 16),

          // ── Fee fields card ───────────────────────────────────────
          _card(
            padding: EdgeInsets.zero,
            child: Column(children: [
              // Card header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: _DS.accentSoft,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(_DS.radius)),
                  border: const Border(bottom: BorderSide(color: _DS.border)),
                ),
                child: Row(children: [
                  _iconBox(Icons.receipt_long_rounded, size: 16),
                  const SizedBox(width: 10),
                  const Text('Fee Configuration',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                          color: _DS.textPrimary)),
                  const Spacer(),
                  if (selectedClass != null)
                    _badge(
                      '${selectedClass!.name} · ${selectedStudentType == 'new' ? 'New' : 'Old'}',
                      bg: _DS.accentSoft, fg: _DS.accent,
                    ),
                ]),
              ),

              // Fee rows
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(children: [
                  _feeFieldRow('Admission Fee', _admissionFeeCtrl,
                      Icons.login_rounded, _DS.success, _DS.successSoft,
                      'One-time admission charge', canSetFee),
                  const SizedBox(height: 10),
                  _feeFieldRow('First Term', _firstTermCtrl,
                      Icons.looks_one_rounded, _DS.accent, _DS.accentSoft,
                      'Tuition fee for first term', canSetFee),
                  const SizedBox(height: 10),
                  _feeFieldRow('Second Term', _secondTermCtrl,
                      Icons.looks_two_rounded,
                      const Color(0xFFD97706), const Color(0xFFFEF3C7),
                      'Tuition fee for second term', canSetFee),
                  const SizedBox(height: 10),
                  // ✅ Annual fee - read only, auto-calculated
                  _feeFieldRow('Annual Fee', _annualFeeCtrl,
                      Icons.calendar_today_rounded,
                      const Color(0xFF7C3AED), const Color(0xFFEDE9FE),
                      'Auto-calculated from all terms', false),
                  const SizedBox(height: 10),
                  _feeFieldRow('Bus First Term', _busFirstTermCtrl,
                      Icons.directions_bus_rounded,
                      const Color(0xFF0891B2), const Color(0xFFCFFAFE),
                      'Transport fee for first term', canSetFee),
                  const SizedBox(height: 10),
                  _feeFieldRow('Bus Second Term', _busSecondTermCtrl,
                      Icons.directions_bus_filled_rounded,
                      const Color(0xFF9333EA), const Color(0xFFF3E8FF),
                      'Transport fee for second term', canSetFee),
                ]),
              ),
            ]),
          ),

          const SizedBox(height: 16),

          // ── Save button ───────────────────────────────────────────
          if (canSetFee)
            Obx(() => SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (selectedClass == null || feeController.isLoading.value)
                    ? null : _saveFeeStructure,
                icon: feeController.isLoading.value
                    ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(feeController.isLoading.value ? 'Saving…' : 'Save Fee Structure',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _DS.accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _DS.accentMid,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_DS.radius)),
                ),
              ),
            )),
        ]),
      ),
    );
  }

  Widget _feeFieldRow(String label, TextEditingController ctrl,
      IconData icon, Color fg, Color bg, String helperText, bool enabled) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(_DS.radiusSm),
        border: Border.all(color: fg.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(children: [
        Icon(icon, color: fg, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
          const SizedBox(height: 5),
          TextFormField(
            controller: ctrl,
            enabled: enabled,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 14, color: _DS.textPrimary),
            decoration: InputDecoration(
              prefixText: '₹ ',
              hintText: '0',
              helperText: helperText,
              helperStyle: TextStyle(fontSize: 10, color: fg.withOpacity(0.6)),
              isDense: true,
              filled: true,
              fillColor: _DS.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: fg.withOpacity(0.3))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: fg.withOpacity(0.3))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: fg, width: 1.5)),
              disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: fg.withOpacity(0.15))),
            ),
          ),
        ])),
      ]),
    );
  }

  void _showClassSheet() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: _DS.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
              decoration: BoxDecoration(color: _DS.border, borderRadius: BorderRadius.circular(100))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(children: [
              const Text('Select Class', style: TextStyle(fontSize: 17,
                  fontWeight: FontWeight.w700, color: _DS.textPrimary)),
              const Spacer(),
              GestureDetector(onTap: () => Get.back(),
                  child: const Icon(Icons.close_rounded, color: _DS.textMuted, size: 22)),
            ]),
          ),
          const Divider(height: 1, color: _DS.border),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 380),
            child: Obx(() {
              final sorted = ClassUtils.sortClasses(schoolController.classes);
              if (sorted.isEmpty)
                return const Padding(padding: EdgeInsets.all(32),
                    child: Center(child: Text('No classes available',
                        style: TextStyle(color: _DS.textMuted))));
              return ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: sorted.length,
                itemBuilder: (_, i) {
                  final c = sorted[i];
                  final isSelected = selectedClass?.id == c.id;
                  return GestureDetector(
                    onTap: () { _onClassSelected(c); Get.back(); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? _DS.accentSoft : _DS.surfaceAlt,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: isSelected ? _DS.accent : _DS.border,
                            width: isSelected ? 1.5 : 1),
                      ),
                      child: Row(children: [
                        Container(width: 34, height: 34,
                          decoration: BoxDecoration(
                              color: isSelected ? _DS.accent : _DS.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isSelected ? _DS.accent : _DS.border)),
                          child: Icon(ClassUtils.getClassIcon(c.name), size: 16,
                              color: isSelected ? Colors.white : _DS.accent),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(c.name, style: TextStyle(fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? _DS.accent : _DS.textPrimary))),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded, color: _DS.accent, size: 18),
                      ]),
                    ),
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

  void _showStudentTypeSheet() {
    final options = [
      ('old', 'Old Students', 'Existing enrolled students',
      Icons.school_rounded, _DS.accent, _DS.accentSoft),
      ('new', 'New Students', 'Newly admitted students',
      Icons.person_add_rounded, _DS.success, _DS.successSoft),
    ];
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: _DS.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
              decoration: BoxDecoration(color: _DS.border, borderRadius: BorderRadius.circular(100))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(children: [
              const Text('Student Type', style: TextStyle(fontSize: 17,
                  fontWeight: FontWeight.w700, color: _DS.textPrimary)),
              const Spacer(),
              GestureDetector(onTap: () => Get.back(),
                  child: const Icon(Icons.close_rounded, color: _DS.textMuted, size: 22)),
            ]),
          ),
          const Divider(height: 1, color: _DS.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
            child: Column(
              children: options.map((o) {
                final isSelected = selectedStudentType == o.$1;
                return GestureDetector(
                  onTap: () { _onStudentTypeSelected(o.$1); Get.back(); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? o.$6 : _DS.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isSelected ? o.$5 : _DS.border,
                          width: isSelected ? 1.5 : 1),
                    ),
                    child: Row(children: [
                      Container(width: 40, height: 40,
                        decoration: BoxDecoration(
                            color: isSelected ? o.$5 : _DS.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSelected ? o.$5 : _DS.border)),
                        child: Icon(o.$4, size: 20,
                            color: isSelected ? Colors.white : _DS.textMuted),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(o.$2, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                            color: isSelected ? o.$5 : _DS.textPrimary)),
                        const SizedBox(height: 2),
                        Text(o.$3, style: const TextStyle(fontSize: 11, color: _DS.textMuted)),
                      ])),
                      if (isSelected) Icon(Icons.check_circle_rounded, color: o.$5, size: 20),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ),
        ]),
      ),
      isScrollControlled: true,
    );
  }
}