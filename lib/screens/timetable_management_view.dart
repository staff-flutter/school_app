import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/controllers/timetable_controller.dart';
import 'package:school_app/controllers/teacher_controller.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/core/rbac/api_rbac.dart';
import 'package:school_app/models/school_models.dart';

// ─── Design System: Light Blue Professional Theme ─────────────────────────────
class _DS {
  // Primary palette — professional light blue
  static const primary = Color(0xFF0EA5E9);
  static const primaryDark = Color(0xFF0284C7);
  static const primaryLight = Color(0xFF7DD3FC);
  static const primarySoft = Color(0xFFE0F2FE);
  static const primaryMuted = Color(0xFFBAE6FD);

  // Surfaces
  static const bg = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF1F5F9);

  // Text
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const textMuted = Color(0xFF94A3B8);

  // Status
  static const success = Color(0xFF10B981);
  static const successSoft = Color(0xFFD1FAE5);
  static const warning = Color(0xFFF59E0B);
  static const warningSoft = Color(0xFFFEF3C7);
  static const danger = Color(0xFFEF4444);
  static const dangerSoft = Color(0xFFFEE2E2);

  // Borders & shadows
  static const border = Color(0xFFE2E8F0);
  static const borderFocus = Color(0xFF7DD3FC);
  static const shadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const shadowMd = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 8)),
  ];

  // Radii
  static const radius = 16.0;
  static const radiusSm = 10.0;
  static const radiusLg = 24.0;
  static const radiusXl = 32.0;

  // Spacing
  static const spacingXs = 4.0;
  static const spacingSm = 8.0;
  static const spacingMd = 12.0;
  static const spacingLg = 16.0;
  static const spacingXl = 24.0;
  static const spacingXxl = 32.0;

  // Responsive breakpoints
  static double get mobile => 600;
  static double get tablet => 900;
  static double get desktop => 1200;
}

// ─── Responsive Helpers ───────────────────────────────────────────────────────
class _Responsive {
  static double padding(BuildContext context) =>
      MediaQuery.of(context).size.width < _DS.tablet ? _DS.spacingLg : _DS.spacingXl;

  static double fontSize(BuildContext context, {double mobile = 14, double tablet = 16}) =>
      MediaQuery.of(context).size.width < _DS.tablet ? mobile : tablet;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= _DS.tablet;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

  static EdgeInsets pagePadding(BuildContext context) =>
      EdgeInsets.symmetric(horizontal: padding(context), vertical: _DS.spacingLg);

  static double cardRadius(BuildContext context) =>
      isTablet(context) ? _DS.radiusLg : _DS.radius;

  static double timetableCellWidth(BuildContext context) =>
      isTablet(context) ? 140 : 100;

  static double timetableCellHeight(BuildContext context) =>
      isTablet(context) ? 75 : 60;
}

// ─── Reusable Components ──────────────────────────────────────────────────────
Widget _card({required Widget child, EdgeInsets? padding, Color? color, BuildContext? context}) {
  return Container(
    margin: EdgeInsets.only(bottom: _DS.spacingMd),
    padding: padding ?? EdgeInsets.all(_DS.spacingLg),
    decoration: BoxDecoration(
      color: color ?? _DS.surface,
      borderRadius: BorderRadius.circular(context != null ? _Responsive.cardRadius(context) : _DS.radius),
      border: Border.all(color: _DS.border),
      boxShadow: _DS.shadow,
    ),
    child: child,
  );
}

Widget _badge(String label, {Color? bg, Color? fg, double fontSize = 11}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: bg ?? _DS.primarySoft,
      borderRadius: BorderRadius.circular(100),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: fg ?? _DS.primary,
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
      color: bg ?? _DS.primarySoft,
      borderRadius: BorderRadius.circular(_DS.radiusSm),
    ),
    child: Icon(icon, color: fg ?? _DS.primary, size: size),
  );
}

Widget _sectionHeader(BuildContext context, String title, {Widget? action, IconData? icon}) {
  return Padding(
    padding: EdgeInsets.fromLTRB(0, _DS.spacingSm, 0, _DS.spacingMd),
    child: Row(
      children: [
        if (icon != null) _iconBox(icon, size: 16),
        if (icon != null) const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: _Responsive.fontSize(context, mobile: 15, tablet: 16),
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
  required BuildContext context,
  required String label,
  required VoidCallback? onPressed,
  IconData? icon,
  bool loading = false,
  Color? color,
  bool fullWidth = true,
  double? height,
}) {
  return SizedBox(
    width: fullWidth ? double.infinity : null,
    height: height,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? _DS.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: _DS.primaryMuted,
        padding: EdgeInsets.symmetric(vertical: _DS.spacingLg),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radius)),
      ),
      child: loading
          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: _Responsive.fontSize(context, mobile: 14, tablet: 15),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
    ),
  );
}

Widget _secondaryBtn({
  required BuildContext context,
  required String label,
  required VoidCallback? onPressed,
  IconData? icon,
  Color? color,
  bool fullWidth = false,
}) {
  return SizedBox(
    width: fullWidth ? double.infinity : null,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color ?? _DS.primary,
        side: BorderSide(color: color ?? _DS.primary),
        padding: EdgeInsets.symmetric(vertical: _DS.spacingLg),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radius)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
          Text(
            label,
            style: TextStyle(
              fontSize: _Responsive.fontSize(context, mobile: 14, tablet: 15),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _field(TextEditingController ctrl, String label, BuildContext context,
    {TextInputType? keyboardType, bool obscure = false, String? prefix, Widget? suffixIcon}) {
  return TextField(
    controller: ctrl,
    obscureText: obscure,
    keyboardType: keyboardType,
    style: TextStyle(fontSize: _Responsive.fontSize(context), color: _DS.textPrimary),
    decoration: InputDecoration(
      labelText: label,
      prefixText: prefix,
      suffixIcon: suffixIcon,
      labelStyle: TextStyle(color: _DS.textSecondary, fontSize: _Responsive.fontSize(context, mobile: 13, tablet: 14)),
      filled: true,
      fillColor: _DS.surfaceAlt,
      contentPadding: EdgeInsets.symmetric(horizontal: _DS.spacingLg, vertical: _DS.spacingMd),
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
        borderSide: const BorderSide(color: _DS.primary, width: 1.5),
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
  required BuildContext context,
  List<Widget>? selectedItemBuilder,
  bool isExpanded = true,
}) {
  return Container(
    decoration: BoxDecoration(
      color: _DS.surfaceAlt,
      borderRadius: BorderRadius.circular(_DS.radiusSm),
      border: Border.all(color: _DS.border),
    ),
    child: DropdownButtonFormField<T>(
      isExpanded: isExpanded,
      value: value,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _DS.textMuted, fontSize: _Responsive.fontSize(context, mobile: 13, tablet: 14)),
        prefixIcon: Icon(icon, color: _DS.primary, size: 20),
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: _DS.spacingMd, vertical: _DS.spacingMd),
      ),
      dropdownColor: _DS.surface,
      menuMaxHeight: 300,
      borderRadius: BorderRadius.circular(_DS.radius),
      icon: const Icon(Icons.unfold_more_rounded, color: _DS.textMuted, size: 20),
      style: TextStyle(color: _DS.textPrimary, fontSize: _Responsive.fontSize(context)),
      selectedItemBuilder: selectedItemBuilder != null ? (_) => selectedItemBuilder : null,
      items: items,
      onChanged: onChanged,
    ),
  );
}

Widget _emptyState(BuildContext context, {required IconData icon, required String title, required String subtitle, Widget? action}) {
  return Center(
    child: Padding(
      padding: EdgeInsets.all(_DS.spacingXxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(color: _DS.primarySoft, shape: BoxShape.circle),
            child: Icon(icon, size: 36, color: _DS.primary),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: _Responsive.fontSize(context, mobile: 17, tablet: 18),
              fontWeight: FontWeight.w700,
              color: _DS.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: _Responsive.fontSize(context, mobile: 12, tablet: 13), color: _DS.textMuted),
          ),
          if (action != null) ...[const SizedBox(height: 20), action],
        ],
      ),
    ),
  );
}

// ─── Timetable Cell Widget ────────────────────────────────────────────────────
Widget _timetableCell({
  required String subject,
  required String teacher,
  required BuildContext context,
  bool isInteractive = false,
  VoidCallback? onTap,
  bool isBreak = false,
  bool isAssigned = false,
  bool isHighlight = false,
}) {
  final cellWidth = _Responsive.timetableCellWidth(context);
  final cellHeight = _Responsive.timetableCellHeight(context);
  
  Color bgColor;
  Color textColor;
  Color borderColor;
  
  if (isBreak) {
    bgColor = _DS.warningSoft;
    textColor = _DS.warning;
    borderColor = _DS.warning;
  } else if (isHighlight) {
    bgColor = _DS.successSoft;
    textColor = _DS.success;
    borderColor = _DS.success;
  } else if (isAssigned) {
    bgColor = _DS.primarySoft;
    textColor = _DS.primaryDark;
    borderColor = _DS.primary;
  } else {
    bgColor = _DS.surfaceAlt;
    textColor = _DS.textMuted;
    borderColor = _DS.border;
  }

  return InkWell(
    onTap: isInteractive ? onTap : null,
    borderRadius: BorderRadius.circular(_DS.radiusSm),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: cellWidth,
      height: cellHeight,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(_DS.radiusSm),
        border: Border.all(color: borderColor, width: isHighlight ? 2 : 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subject,
            style: TextStyle(
              fontSize: _Responsive.fontSize(context, mobile: 11, tablet: 12),
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              teacher,
              style: TextStyle(
                fontSize: _Responsive.fontSize(context, mobile: 9, tablet: 10),
                color: _DS.textMuted,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    ),
  );
}

// ─── Collapsible Selector Widget ──────────────────────────────────────────────
class _CollapsibleSelector extends StatefulWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final bool initiallyExpanded;

  const _CollapsibleSelector({
    required this.title,
    required this.icon,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  State<_CollapsibleSelector> createState() => _CollapsibleSelectorState();
}

class _CollapsibleSelectorState extends State<_CollapsibleSelector> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return _card(
      context: context,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.vertical(top: Radius.circular(_Responsive.cardRadius(context))),
            child: Padding(
              padding: EdgeInsets.all(_DS.spacingLg),
              child: Row(
                children: [
                  _iconBox(widget.icon, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: _Responsive.fontSize(context, mobile: 14, tablet: 15),
                        fontWeight: FontWeight.w700,
                        color: _DS.textPrimary,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _isExpanded ? 0.5 : 0,
                    child: Icon(Icons.expand_more_rounded, color: _DS.textMuted, size: 20),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: EdgeInsets.symmetric(horizontal: _DS.spacingLg, vertical: _DS.spacingSm),
              child: widget.child,
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          ),
        ],
      ),
    );
  }
}

// ─── MAIN VIEW ────────────────────────────────────────────────────────────────
class TimetableManagementView extends StatefulWidget {
  @override
  State<TimetableManagementView> createState() => _TimetableManagementViewState();
}

class _TimetableManagementViewState extends State<TimetableManagementView> with TickerProviderStateMixin {
  final schoolController = Get.find<SchoolController>();
  final timetableController = Get.put(TimetableController());
  final teacherController = Get.put(TeacherController());
  final authController = Get.find<AuthController>();

  late TabController _tabController;
  SchoolClass? selectedClass;
  Section? selectedSection;
  String? selectedTeacherId;

  final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  bool _selectorsExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _getAvailableTabsCount(), vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ApiPermissions.isSchoolReadOnly(currentUserRole)) {
        final userSchoolId = authController.user.value?.schoolId;
        if (userSchoolId != null) {
          final userSchool = schoolController.schools.firstWhereOrNull((s) => s.id == userSchoolId);
          if (userSchool != null) {
            schoolController.selectedSchool.value = userSchool;
            schoolController.getAllClasses(userSchool.id);
            schoolController.loadTeachers();
          }
        }
      }
    });
  }

  int _getAvailableTabsCount() {
    int count = 0;
    if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/timetable/addday') ||
        ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/timetable/updateperiod') ||
        ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/timetable/assignteacher') ||
        ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/timetable/delete/:id')) count++;
    if (ApiPermissions.hasApiAccess(currentUserRole, 'GET /api/timetable/getall')) count++;
    if (ApiPermissions.hasApiAccess(currentUserRole, 'GET /api/timetable/teacherschedule')) count++;
    return count > 0 ? count : 1;
  }

  List<Widget> _buildTabs(BuildContext context) {
    List<Widget> tabs = [];
    final isTablet = _Responsive.isTablet(context);

    if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/timetable/addday') ||
        ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/timetable/updateperiod') ||
        ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/timetable/assignteacher') ||
        ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/timetable/delete/:id')) {
      tabs.add(Tab(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_calendar_rounded, size: isTablet ? 14 : 12),
              const SizedBox(width: 6),
              Text('Manage', style: TextStyle(fontSize: _Responsive.fontSize(context, mobile: 12, tablet: 13))),
            ],
          ),
        ),
      ));
    }

    if (ApiPermissions.hasApiAccess(currentUserRole, 'GET /api/timetable/getall')) {
      tabs.add(Tab(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.view_list_rounded, size: isTablet ? 14 : 12),
              const SizedBox(width: 6),
              Text('View', style: TextStyle(fontSize: _Responsive.fontSize(context, mobile: 12, tablet: 13))),
            ],
          ),
        ),
      ));
    }

    if (ApiPermissions.hasApiAccess(currentUserRole, 'GET /api/timetable/teacherschedule')) {
      tabs.add(Tab(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_outline_rounded, size: isTablet ? 14 : 12),
              const SizedBox(width: 6),
              Text('Teacher', style: TextStyle(fontSize: _Responsive.fontSize(context, mobile: 12, tablet: 13))),
            ],
          ),
        ),
      ));
    }

    return tabs.isNotEmpty ? tabs : [const Tab(text: 'No Access')];
  }

  List<Widget> _buildTabViews(BuildContext context) {
    List<Widget> views = [];
    final isTablet = _Responsive.isTablet(context);
    final isLandscape = _Responsive.isLandscape(context);

    if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/timetable/addday') ||
        ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/timetable/updateperiod') ||
        ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/timetable/assignteacher') ||
        ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/timetable/delete/:id')) {
      views.add(_buildManageTab(context, isTablet, isLandscape));
    }

    if (ApiPermissions.hasApiAccess(currentUserRole, 'GET /api/timetable/getall')) {
      views.add(_buildViewTab(context, isTablet, isLandscape));
    }

    if (ApiPermissions.hasApiAccess(currentUserRole, 'GET /api/timetable/teacherschedule')) {
      views.add(_buildTeacherTab(context, isTablet, isLandscape));
    }

    return views.isNotEmpty ? views : [_buildNoAccessView(context)];
  }

  Widget _buildNoAccessView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline_rounded, size: _Responsive.isTablet(context) ? 80 : 64, color: _DS.textMuted),
          const SizedBox(height: 24),
          Text(
            'No Access',
            style: TextStyle(
              fontSize: _Responsive.fontSize(context, mobile: 20, tablet: 24),
              fontWeight: FontWeight.bold,
              color: _DS.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You don\'t have permission to access timetable management',
            style: TextStyle(fontSize: _Responsive.fontSize(context, mobile: 13, tablet: 14), color: _DS.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _compareClassNames(String a, String b) {
    final aLower = a.toLowerCase().trim();
    final bLower = b.toLowerCase().trim();

    int _getClassPriority(String className) {
      if (className == 'lkg') return 1;
      if (className == 'ukg') return 2;
      if (className.startsWith('grade ')) {
        final match = RegExp(r'grade (\d+)', caseSensitive: false).firstMatch(className);
        if (match != null) {
          final num = int.tryParse(match.group(1)!);
          if (num != null) return 2 + num;
        }
      }
      if (className.startsWith('class ')) {
        final match = RegExp(r'class (\d+)', caseSensitive: false).firstMatch(className);
        if (match != null) {
          final num = int.tryParse(match.group(1)!);
          if (num != null) return 20 + num;
        }
      }
      return 999;
    }

    return _getClassPriority(aLower).compareTo(_getClassPriority(bLower));
  }

  IconData _getClassIcon(String className) {
    final lower = className.toLowerCase();
    if (lower == 'lkg' || lower == 'ukg') return Icons.child_care_rounded;
    if (lower.contains('grade 1') || lower.contains('grade 2') || lower.contains('grade 3')) return Icons.looks_one_rounded;
    if (lower.contains('grade 4') || lower.contains('grade 5') || lower.contains('grade 6')) return Icons.looks_two_rounded;
    if (lower.contains('grade 7') || lower.contains('grade 8') || lower.contains('grade 9')) return Icons.looks_3_rounded;
    return Icons.looks_4_rounded;
  }

  String get currentUserRole => authController.user.value?.role?.toLowerCase() ?? '';

  @override
  Widget build(BuildContext context) {
    final isTablet = _Responsive.isTablet(context);
    final isLandscape = _Responsive.isLandscape(context);

    return Scaffold(
      backgroundColor: _DS.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_DS.primary, _DS.primaryDark]),
                boxShadow: _DS.shadowMd,
              ),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(_Responsive.padding(context), isTablet ? 24 : 16, _Responsive.padding(context), isTablet ? 16 : 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(_DS.radiusSm),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Icon(Icons.grid_view_rounded, color: Colors.white, size: isTablet ? 18 : 14),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Academic Schedule',
                                style: TextStyle(color: Colors.white, fontSize: isTablet ? 22 : 16, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Management Portal',
                                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: isTablet ? 13 : 11),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.more_vert_rounded, color: Colors.white, size: isTablet ? 22 : 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  // ── Pill TabBar ───────────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: _Responsive.padding(context), vertical: _DS.spacingSm),
                    child: Container(
                      height: isTablet ? 36 : 32,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.15), borderRadius: BorderRadius.circular(100)),
                      child: TabBar(
                        controller: _tabController,
                        dividerColor: Colors.transparent,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(color: _DS.surface, borderRadius: BorderRadius.circular(100), boxShadow: _DS.shadow),
                        labelColor: _DS.primary,
                        unselectedLabelColor: Colors.white.withOpacity(0.7),
                        labelStyle: TextStyle(fontSize: isTablet ? 14 : 12, fontWeight: FontWeight.w700),
                        unselectedLabelStyle: TextStyle(fontSize: isTablet ? 14 : 12, fontWeight: FontWeight.w500),
                        tabs: _buildTabs(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            // ── Content ─────────────────────────────────────────────────────
            Expanded(
              child: Container(
                color: _DS.bg,
                child: TabBarView(controller: _tabController, children: _buildTabViews(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Manage Tab ───────────────────────────────────────────────────────────
  Widget _buildManageTab(BuildContext context, bool isTablet, bool isLandscape) {
    return RefreshIndicator(
      onRefresh: () async {
        if (schoolController.selectedSchool.value != null && selectedClass != null) {
          await timetableController.getAllTimetables(
            schoolId: schoolController.selectedSchool.value!.id,
            classId: selectedClass!.id,
            sectionId: selectedSection?.id,
          );
        }
      },
      color: _DS.primary,
      child: SingleChildScrollView(
        padding: _Responsive.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCollapsibleSelectors(context, isLandscape, isTablet),
            const SizedBox(height: 20),
            _buildTimetableGrid(context, isTablet),
          ],
        ),
      ),
    );
  }

  // ─── View Tab ─────────────────────────────────────────────────────────────
  Widget _buildViewTab(BuildContext context, bool isTablet, bool isLandscape) {
    return RefreshIndicator(
      onRefresh: () async {
        if (schoolController.selectedSchool.value != null && selectedClass != null) {
          await timetableController.getAllTimetables(
            schoolId: schoolController.selectedSchool.value!.id,
            classId: selectedClass!.id,
            sectionId: selectedSection?.id,
          );
        }
      },
      color: _DS.primary,
      child: SingleChildScrollView(
        padding: _Responsive.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCollapsibleSelectors(context, isLandscape, isTablet),
            const SizedBox(height: 20),
            _buildViewOnlyTimetable(context, isTablet),
          ],
        ),
      ),
    );
  }

  // ─── Teacher Tab ──────────────────────────────────────────────────────────
  Widget _buildTeacherTab(BuildContext context, bool isTablet, bool isLandscape) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (schoolController.selectedSchool.value != null) {
        schoolController.loadTeachers();
      }
    });
    return SingleChildScrollView(
      padding: _Responsive.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTeacherSelector(context, isTablet),
          const SizedBox(height: 20),
          _buildTeacherSchedule(context, isTablet),
        ],
      ),
    );
  }

  // ─── Collapsible Selectors ────────────────────────────────────────────────
  Widget _buildCollapsibleSelectors(BuildContext context, bool isLandscape, bool isTablet) {
    return Column(
      children: [
        _CollapsibleSelector(
          title: 'Class & Section',
          icon: Icons.class_rounded,
          initiallyExpanded: _selectorsExpanded,
          child: Column(
            children: [
              _buildClassSelector(context),
              if (ApiPermissions.hasSectionAccess(currentUserRole)) ...[
                const SizedBox(height: 12),
                _buildSectionSelector(context),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _primaryBtn(
                      context: context,
                      label: _selectorsExpanded ? 'Hide Selectors' : 'Apply Filters',
                      icon: _selectorsExpanded ? Icons.expand_less : Icons.check_rounded,
                      onPressed: () => setState(() => _selectorsExpanded = !_selectorsExpanded),
                      fullWidth: true,
                      height: 60,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClassSelector(BuildContext context) {
    return Obx(() {
      if (schoolController.selectedSchool.value != null &&
          schoolController.classes.isEmpty &&
          !schoolController.isLoading.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          schoolController.getAllClasses(schoolController.selectedSchool.value!.id);
        });
      }

      final sortedClasses = List<SchoolClass>.from(schoolController.classes);
      sortedClasses.sort((a, b) => _compareClassNames(a.name, b.name));

      return _dropdown<SchoolClass>(
        value: selectedClass,
        hint: sortedClasses.isEmpty ? 'Select school first' : 'Choose Class',
        icon: Icons.class_rounded,
        context: context,
        selectedItemBuilder: sortedClasses
            .map((c) => Text(c.name, overflow: TextOverflow.ellipsis, style: TextStyle(color: _DS.textPrimary, fontSize: _Responsive.fontSize(context))))
            .toList(),
        items: sortedClasses.isEmpty
            ? []
            : sortedClasses.map((cls) {
                return DropdownMenuItem<SchoolClass>(
                  value: cls,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getClassIcon(cls.name), color: _DS.primary, size: 16),
                      const SizedBox(width: 8),
                      Text(cls.name, style: TextStyle(fontSize: _Responsive.fontSize(context)), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                );
              }).toList(),
        onChanged: (cls) {
          setState(() {
            selectedClass = cls;
            selectedSection = null;
          });
          if (cls != null && schoolController.selectedSchool.value != null) {
            schoolController.getAllSections(classId: cls.id, schoolId: schoolController.selectedSchool.value!.id);
            timetableController.getAllTimetables(
              schoolId: schoolController.selectedSchool.value!.id,
              classId: cls.id,
              sectionId: selectedSection?.id,
            );
          }
        },
      );
    });
  }

  Widget _buildSectionSelector(BuildContext context) {
    final userRole = authController.user.value?.role?.toLowerCase() ?? '';
    if (!ApiPermissions.hasSectionAccess(userRole)) return const SizedBox.shrink();

    return Obx(() => _dropdown<Section>(
          value: selectedSection,
          hint: 'Choose Section (Optional)',
          icon: Icons.group_rounded,
          context: context,
          selectedItemBuilder: [
            Text('All Sections', style: TextStyle(color: _DS.textPrimary, fontSize: _Responsive.fontSize(context))),
            ...schoolController.sections.map((s) => Text(s.name, style: TextStyle(color: _DS.textPrimary, fontSize: _Responsive.fontSize(context)))),
          ],
          items: [
            const DropdownMenuItem<Section>(value: null, child: Text('All Sections')),
            ...schoolController.sections.map((section) => DropdownMenuItem<Section>(value: section, child: Text(section.name))),
          ],
          onChanged: (section) {
            setState(() => selectedSection = section);
          },
        ));
  }

  // ─── Teacher Selector ─────────────────────────────────────────────────────
  Widget _buildTeacherSelector(BuildContext context, bool isTablet) {
    final searchController = TextEditingController();
    final filteredTeachers = <Map<String, dynamic>>[].obs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context, 'Teacher Directory', icon: Icons.person_search_rounded),
        Container(
          decoration: BoxDecoration(color: _DS.surface, borderRadius: BorderRadius.circular(_DS.radius), boxShadow: _DS.shadow),
          child: TextField(
            controller: searchController,
            onChanged: (value) {
              filteredTeachers.value = schoolController.teachers
                  .where((t) => (t['userName'] as String).toLowerCase().contains(value.toLowerCase()))
                  .toList();
            },
            style: TextStyle(fontSize: _Responsive.fontSize(context), color: _DS.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search by name...',
              hintStyle: TextStyle(color: _DS.textMuted, fontSize: _Responsive.fontSize(context)),
              prefixIcon: Icon(Icons.search_rounded, color: _DS.primary),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: _DS.spacingMd, horizontal: _DS.spacingLg),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Obx(() {
          final list = searchController.text.isEmpty ? schoolController.teachers : filteredTeachers;
          if (schoolController.isLoading.value) {
            return Center(child: Padding(padding: EdgeInsets.all(_DS.spacingXl), child: CircularProgressIndicator(color: _DS.primary, strokeWidth: 2)));
          }
          if (list.isEmpty) {
            return _emptyState(context, icon: Icons.person_off_rounded, title: 'No teachers found', subtitle: 'Try adjusting your search');
          }
          return Container(
            constraints: BoxConstraints(maxHeight: isTablet ? 500 : 350),
            child: ListView.builder(
              itemCount: list.length,
              padding: EdgeInsets.only(bottom: _DS.spacingLg),
              itemBuilder: (context, index) {
                final teacher = list[index];
                final isSelected = selectedTeacherId == teacher['_id'];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? _DS.primarySoft : _DS.surface,
                    borderRadius: BorderRadius.circular(_DS.radiusSm),
                    border: Border.all(color: isSelected ? _DS.primary : _DS.border, width: isSelected ? 1.5 : 1),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: _DS.spacingMd, vertical: _DS.spacingSm),
                    leading: Container(
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isSelected ? _DS.primary : _DS.border, width: 2)),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: isSelected ? _DS.primary : _DS.surfaceAlt,
                        child: Text(
                          (teacher['userName'] as String).substring(0, 1).toUpperCase(),
                          style: TextStyle(fontSize: 13, color: isSelected ? Colors.white : _DS.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    title: Text(
                      teacher['userName'] ?? 'Unknown',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: _Responsive.fontSize(context), color: isSelected ? _DS.primaryDark : _DS.textPrimary),
                    ),
                    subtitle: Text("ID: ${teacher['_id'].toString().substring(0, 8)}...", style: TextStyle(fontSize: _Responsive.fontSize(context, mobile: 10, tablet: 11), color: _DS.textMuted)),
                    trailing: isSelected ? Icon(Icons.check_circle_rounded, color: _DS.primary, size: 20) : Icon(Icons.chevron_right_rounded, color: _DS.textMuted, size: 20),
                    onTap: () {
                      setState(() => selectedTeacherId = teacher['_id']);
                      timetableController.getTeacherSchedule(schoolId: schoolController.selectedSchool.value!.id, teacherId: teacher['_id']);
                    },
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  // ─── Timetable Grid (Manage) ──────────────────────────────────────────────
  Widget _buildTimetableGrid(BuildContext context, bool isTablet) {
    if (schoolController.selectedSchool.value == null || selectedClass == null) {
      return _emptyState(
        context,
        icon: Icons.calendar_today_outlined,
        title: 'Select class to manage',
        subtitle: 'Choose a class from the selectors above to view and edit the timetable',
        action: _secondaryBtn(context: context, label: 'Refresh Classes', onPressed: () {
          if (schoolController.selectedSchool.value != null) {
            schoolController.getAllClasses(schoolController.selectedSchool.value!.id);
          }
        }),
      );
    }

    return _card(
      context: context,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? _DS.spacingXl : _DS.spacingLg),
            decoration: BoxDecoration(
              color: _DS.primarySoft,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(_DS.radiusLg), topRight: Radius.circular(_DS.radiusLg)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: _DS.primary, size: isTablet ? 22 : 18),
                    const SizedBox(width: 12),
                    Text(
                      'Weekly Timetable',
                      style: TextStyle(fontSize: isTablet ? 20 : 17, fontWeight: FontWeight.bold, color: _DS.primaryDark),
                    ),
                  ],
                ),
                if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/timetable/addday'))
                  Padding(
                    padding: EdgeInsets.only(top: _DS.spacingMd),
                    child: Row(
                      children: [
                        Expanded(child: _primaryBtn(context: context, label: 'Add Day', icon: Icons.add_rounded, onPressed: _showAddDayDialog, fullWidth: true)),
                        if (ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/timetable/delete/:id')) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showDeleteTimetableDialog,
                              icon: Icon(Icons.delete_rounded, size: isTablet ? 18 : 16),
                              label: Text('Delete', style: TextStyle(fontSize: _Responsive.fontSize(context))),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _DS.danger,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: _DS.spacingLg),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radius)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isTablet ? _DS.spacingXl : _DS.spacingLg),
            child: _buildTimetableContent(context, isTablet),
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableContent(BuildContext context, bool isTablet) {
    return Obx(() {
      if (timetableController.timetables.isEmpty) {
        return _emptyState(
          context,
          icon: Icons.calendar_today_outlined,
          title: 'No Timetable Days Added',
          subtitle: 'Click "Add Day" button above to create your first timetable day',
          action: ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/timetable/addday')
              ? _primaryBtn(context: context, label: 'Add First Day', icon: Icons.add_rounded, onPressed: _showAddDayDialog, fullWidth: false)
              : null,
        );
      }

      final timetable = timetableController.timetables.first;
      final weeklySchedule = timetable['weeklySchedule'] as List? ?? [];
      final addedDays = weeklySchedule.map((ws) => ws['day'] as String).toList();

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: isTablet ? 24 : 12,
          dataRowMinHeight: _Responsive.timetableCellHeight(context) + 10,
          headingRowColor: WidgetStateColor.resolveWith((states) => _DS.primarySoft),
          columns: [
            DataColumn(
              label: Container(
                width: 70,
                padding: EdgeInsets.symmetric(vertical: _DS.spacingSm),
                child: Text('Period', style: TextStyle(fontWeight: FontWeight.bold, fontSize: _Responsive.fontSize(context, mobile: 11, tablet: 12), color: _DS.textPrimary)),
              ),
            ),
            ...addedDays.map((day) => DataColumn(
                  label: Container(
                    width: _Responsive.timetableCellWidth(context),
                    padding: EdgeInsets.symmetric(vertical: _DS.spacingSm),
                    child: Text(day, style: TextStyle(fontWeight: FontWeight.bold, fontSize: _Responsive.fontSize(context, mobile: 11, tablet: 12), color: _DS.textPrimary), textAlign: TextAlign.center),
                  ),
                )),
          ],
          rows: List.generate(8, (periodIndex) {
            return DataRow(
              cells: [
                DataCell(
                  Container(
                    padding: EdgeInsets.symmetric(vertical: _DS.spacingSm, horizontal: _DS.spacingMd),
                    decoration: BoxDecoration(color: _DS.primarySoft, borderRadius: BorderRadius.circular(_DS.radiusSm)),
                    child: Text('Period ${periodIndex + 1}', style: TextStyle(fontWeight: FontWeight.w600, fontSize: _Responsive.fontSize(context, mobile: 11, tablet: 12), color: _DS.primaryDark)),
                  ),
                ),
                ...addedDays.map((day) => DataCell(_buildPeriodCell(day, periodIndex + 1, context))),
              ],
            );
          }),
        ),
      );
    });
  }

  Widget _buildPeriodCell(String day, int period, BuildContext context) {
    if (timetableController.timetables.isEmpty) {
      return _timetableCell(subject: 'Subject', teacher: 'Teacher', context: context, isInteractive: true, onTap: () => _showEditPeriodDialog(day, period));
    }

    final timetable = timetableController.timetables.first;
    final weeklySchedule = timetable['weeklySchedule'] as List? ?? [];
    final daySchedule = weeklySchedule.firstWhere((ws) => ws['day'] == day, orElse: () => null);

    String subject = 'Subject';
    String teacher = 'Teacher';
    bool isBreak = false;

    if (daySchedule != null) {
      final periods = daySchedule['periods'] as List? ?? [];
      final periodData = periods.firstWhere((p) => p['periodNumber'] == period, orElse: () => null);
      if (periodData != null) {
        isBreak = periodData['isBreak'] ?? false;
        subject = isBreak ? 'Break' : (periodData['subjectName'] ?? 'Subject');
        final teacherData = periodData['teacherId'];
        if (teacherData is Map) teacher = teacherData['userName'] ?? 'Teacher';
      }
    }

    return _timetableCell(
      subject: subject,
      teacher: teacher,
      context: context,
      isInteractive: ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/timetable/updateperiod'),
      onTap: () => _showEditPeriodDialog(day, period),
      isBreak: isBreak,
      isAssigned: !isBreak && subject != 'Subject',
    );
  }

  // ─── View-Only Timetable ──────────────────────────────────────────────────
  Widget _buildViewOnlyTimetable(BuildContext context, bool isTablet) {
    if (schoolController.selectedSchool.value == null || selectedClass == null) {
      return _emptyState(context, icon: Icons.visibility_outlined, title: 'Select class to view', subtitle: 'Choose a class from the selectors above to view the timetable');
    }

    return _card(
      context: context,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? _DS.spacingXl : _DS.spacingLg),
            decoration: BoxDecoration(
              color: _DS.primarySoft,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(_DS.radiusLg), topRight: Radius.circular(_DS.radiusLg)),
            ),
            child: Row(
              children: [
                Icon(Icons.visibility_rounded, color: _DS.primary, size: isTablet ? 22 : 18),
                const SizedBox(width: 12),
                Text('Timetable View', style: TextStyle(fontSize: isTablet ? 20 : 17, fontWeight: FontWeight.bold, color: _DS.primaryDark)),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isTablet ? _DS.spacingXl : _DS.spacingLg),
            child: _buildReadOnlyTimetable(context, isTablet),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyTimetable(BuildContext context, bool isTablet) {
    return Obx(() {
      if (timetableController.isLoading.value) {
        return Center(child: Padding(padding: EdgeInsets.all(_DS.spacingXl), child: CircularProgressIndicator(color: _DS.primary, strokeWidth: 2)));
      }

      if (timetableController.timetables.isEmpty) {
        return _emptyState(context, icon: Icons.schedule_rounded, title: 'No timetable data', subtitle: 'Timetable has not been created yet');
      }

      final timetable = timetableController.timetables.first;
      final weeklySchedule = timetable['weeklySchedule'] as List? ?? [];
      final addedDays = weeklySchedule.map((ws) => ws['day'] as String).toList();

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 50),
          child: DataTable(
            columnSpacing: isTablet ? 24 : 12,
            dataRowMinHeight: _Responsive.timetableCellHeight(context) + 10,
            dataRowMaxHeight: _Responsive.timetableCellHeight(context) + 10,
            headingRowColor: WidgetStateColor.resolveWith((states) => _DS.primarySoft),
            columns: [
              DataColumn(label: Container(width: 70, child: Text('Period', style: TextStyle(fontWeight: FontWeight.bold, fontSize: _Responsive.fontSize(context, mobile: 11, tablet: 12), color: _DS.textPrimary)))),
              ...addedDays.map((day) => DataColumn(label: Container(width: _Responsive.timetableCellWidth(context), child: Text(day, style: TextStyle(fontWeight: FontWeight.bold, fontSize: _Responsive.fontSize(context, mobile: 11, tablet: 12), color: _DS.textPrimary), textAlign: TextAlign.center)))),
            ],
            rows: List.generate(8, (periodIndex) {
              final periodNumber = periodIndex + 1;
              return DataRow(
                cells: [
                  DataCell(
                    Container(
                      padding: EdgeInsets.symmetric(vertical: _DS.spacingSm, horizontal: _DS.spacingMd),
                      decoration: BoxDecoration(color: _DS.primarySoft, borderRadius: BorderRadius.circular(_DS.radiusSm)),
                      child: Text('Period $periodNumber', style: TextStyle(fontWeight: FontWeight.w600, fontSize: _Responsive.fontSize(context, mobile: 11, tablet: 12), color: _DS.primaryDark)),
                    ),
                  ),
                  ...weeklySchedule.map((daySchedule) {
                    final periods = daySchedule['periods'] as List? ?? [];
                    final period = periods.firstWhere((p) => p['periodNumber'] == periodNumber, orElse: () => null);
                    String subject = '-';
                    String teacher = '-';
                    bool isBreak = false;
                    if (period != null) {
                      isBreak = period['isBreak'] ?? false;
                      subject = isBreak ? 'Break' : (period['subjectName'] ?? '-');
                      final teacherData = period['teacherId'];
                      if (teacherData is Map) teacher = teacherData['userName'] ?? '-';
                    }
                    return DataCell(
                      _timetableCell(
                        subject: subject,
                        teacher: teacher,
                        context: context,
                        isInteractive: ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/timetable/assignteacher'),
                        onTap: () => _showAssignTeacherDialog(daySchedule['day'], periodNumber),
                        isBreak: isBreak,
                        isAssigned: !isBreak && subject != '-',
                      ),
                    );
                  }),
                ],
              );
            }),
          ),
        ),
      );
    });
  }

  // ─── Teacher Schedule ─────────────────────────────────────────────────────
  Widget _buildTeacherSchedule(BuildContext context, bool isTablet) {
    return Obx(() {
      if (timetableController.teacherSchedule.isEmpty) {
        return _card(
          context: context,
          child: _emptyState(context, icon: Icons.person_outline_rounded, title: 'Select a teacher', subtitle: 'Choose a teacher from the list above to view their schedule'),
        );
      }

      final schedule = timetableController.teacherSchedule.first;
      final weeklySchedule = schedule['weeklySchedule'] as List? ?? [];
      final addedDays = weeklySchedule.map((ws) => ws['day'] as String).toList();

      return _card(
        context: context,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? _DS.spacingXl : _DS.spacingLg),
              decoration: BoxDecoration(
                color: _DS.successSoft,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(_DS.radiusLg), topRight: Radius.circular(_DS.radiusLg)),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_outline_rounded, color: _DS.success, size: isTablet ? 22 : 18),
                  const SizedBox(width: 12),
                  Text('Teacher Schedule', style: TextStyle(fontSize: isTablet ? 20 : 17, fontWeight: FontWeight.bold, color: _DS.success)),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(isTablet ? _DS.spacingXl : _DS.spacingLg),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: isTablet ? 24 : 12,
                  dataRowMinHeight: _Responsive.timetableCellHeight(context) + 10,
                  dataRowMaxHeight: _Responsive.timetableCellHeight(context) + 10,
                  headingRowColor: WidgetStateColor.resolveWith((states) => _DS.successSoft),
                  columns: [
                    DataColumn(label: Container(width: 70, child: Text('Period', style: TextStyle(fontWeight: FontWeight.bold, fontSize: _Responsive.fontSize(context, mobile: 11, tablet: 12), color: _DS.textPrimary)))),
                    ...addedDays.map((day) => DataColumn(label: Container(width: _Responsive.timetableCellWidth(context), child: Text(day, style: TextStyle(fontWeight: FontWeight.bold, fontSize: _Responsive.fontSize(context, mobile: 11, tablet: 12), color: _DS.textPrimary), textAlign: TextAlign.center)))),
                  ],
                  rows: List.generate(8, (periodIndex) {
                    final periodNumber = periodIndex + 1;
                    return DataRow(
                      cells: [
                        DataCell(
                          Container(
                            padding: EdgeInsets.symmetric(vertical: _DS.spacingSm, horizontal: _DS.spacingMd),
                            decoration: BoxDecoration(color: _DS.successSoft, borderRadius: BorderRadius.circular(_DS.radiusSm)),
                            child: Text('Period $periodNumber', style: TextStyle(fontSize: _Responsive.fontSize(context, mobile: 11, tablet: 12), fontWeight: FontWeight.w600, color: _DS.success)),
                          ),
                        ),
                        ...weeklySchedule.map((daySchedule) {
                          final periods = daySchedule['periods'] as List? ?? [];
                          final period = periods.firstWhere((p) => p['periodNumber'] == periodNumber, orElse: () => null);
                          String subject = '-';
                          bool isYourPeriod = false;
                          if (period != null) {
                            subject = period['subjectName'] ?? '-';
                            isYourPeriod = period['isYourPeriod'] ?? false;
                          }
                          return DataCell(
                            Container(
                              margin: EdgeInsets.all(8),
                              width: _Responsive.timetableCellWidth(context),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isYourPeriod ? _DS.successSoft : _DS.surfaceAlt,
                                borderRadius: BorderRadius.circular(_DS.radiusSm),
                                border: Border.all(color: isYourPeriod ? _DS.success : _DS.border, width: isYourPeriod ? 2 : 1),
                              ),
                              child: Center(
                                child: Text(
                                  subject,
                                  style: TextStyle(
                                    fontSize: _Responsive.fontSize(context, mobile: 11, tablet: 12),
                                    fontWeight: isYourPeriod ? FontWeight.bold : FontWeight.w600,
                                    color: isYourPeriod ? _DS.success : _DS.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ─── Dialogs ──────────────────────────────────────────────────────────────
  void _showAddDayDialog() {
    String selectedDay = days.first;
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radiusLg)),
        title: const Text('Add Day to Timetable'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return _dropdown<String>(
              value: selectedDay,
              hint: 'Select Day',
              icon: Icons.calendar_today_rounded,
              context: context,
              selectedItemBuilder: days.map((day) => Text(day)).toList(),
              items: days.map((day) {
                return DropdownMenuItem<String>(
                  value: day,
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 18, color: _DS.primary),
                      const SizedBox(width: 8),
                      Text(day),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (day) {
                if (day != null) setState(() => selectedDay = day);
              },
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (schoolController.selectedSchool.value != null && selectedClass != null) {
                await timetableController.addDay(
                  schoolId: schoolController.selectedSchool.value!.id,
                  classId: selectedClass!.id,
                  sectionId: selectedSection?.id,
                  day: selectedDay,
                );
              }
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: _DS.primary, foregroundColor: Colors.white),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteTimetableDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radiusLg)),
        title: const Text('Delete Timetable'),
        content: Text('Are you sure you want to delete the entire timetable for ${selectedClass?.name}?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (timetableController.timetables.isNotEmpty) {
                final timetableId = timetableController.timetables.first['_id'];
                Get.back();
                final success = await timetableController.deleteTimetable(timetableId);
                if (success && schoolController.selectedSchool.value != null && selectedClass != null) {
                  await timetableController.getAllTimetables(
                    schoolId: schoolController.selectedSchool.value!.id,
                    classId: selectedClass!.id,
                    sectionId: selectedSection?.id,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _DS.danger, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAssignTeacherDialog(String day, int period) {
    if (schoolController.selectedSchool.value != null) schoolController.loadTeachers();
    final searchController = TextEditingController();
    String? selectedTeacherId;
    final filteredTeachers = <Map<String, dynamic>>[].obs;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          if (filteredTeachers.isEmpty) filteredTeachers.value = schoolController.teachers;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radiusLg)),
            title: Text('Assign Teacher - $day Period $period'),
            content: SizedBox(
              width: 300,
              height: 300,
              child: Column(
                children: [
                  _field(searchController, 'Search Teacher', context, prefix: ''),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Obx(() => Container(
                          decoration: BoxDecoration(border: Border.all(color: _DS.border), borderRadius: BorderRadius.circular(_DS.radiusSm)),
                          child: schoolController.teachers.isEmpty
                              ? const Padding(padding: EdgeInsets.all(8), child: Center(child: Text('Loading...', style: TextStyle(fontSize: 11))))
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: filteredTeachers.length,
                                  itemBuilder: (context, index) {
                                    final teacher = filteredTeachers[index];
                                    final isSelected = selectedTeacherId == teacher['_id'];
                                    return InkWell(
                                      onTap: () => setState(() => selectedTeacherId = teacher['_id']),
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                        decoration: BoxDecoration(color: isSelected ? _DS.primarySoft : Colors.transparent, borderRadius: BorderRadius.circular(6)),
                                        child: Row(
                                          children: [
                                            CircleAvatar(radius: 9, backgroundColor: isSelected ? _DS.primary : _DS.primarySoft, child: Icon(Icons.person, color: isSelected ? Colors.white : _DS.primary, size: 10)),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text(teacher['userName'] ?? 'Unknown', style: TextStyle(fontSize: 11, color: isSelected ? _DS.primaryDark : _DS.textPrimary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal), overflow: TextOverflow.ellipsis)),
                                            if (isSelected) Icon(Icons.check_circle_rounded, color: _DS.primary, size: 12),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        )),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (selectedTeacherId == null) {
                    Get.snackbar('Error', 'Please select a teacher', backgroundColor: _DS.danger, colorText: Colors.white);
                    return;
                  }
                  if (timetableController.timetables.isEmpty) {
                    Get.snackbar('Error', 'No timetable found', backgroundColor: _DS.danger, colorText: Colors.white);
                    return;
                  }
                  final timetable = timetableController.timetables.first;
                  final weeklySchedule = timetable['weeklySchedule'] as List? ?? [];
                  final daySchedule = weeklySchedule.firstWhere((ws) => ws['day'] == day, orElse: () => null);
                  if (daySchedule == null) {
                    Get.snackbar('Error', 'Day not found', backgroundColor: _DS.danger, colorText: Colors.white);
                    return;
                  }
                  final dayId = daySchedule['_id'] as String?;
                  if (dayId == null) {
                    Get.snackbar('Error', 'Invalid timetable data', backgroundColor: _DS.danger, colorText: Colors.white);
                    return;
                  }
                  Get.back();
                  final success = await timetableController.assignTeacher(
                    mode: 'add',
                    schoolId: schoolController.selectedSchool.value!.id,
                    classId: selectedClass!.id,
                    sectionId: selectedSection?.id,
                    weeklyScheduleId: dayId,
                    periodNumber: period,
                    teacherId: selectedTeacherId!,
                  );
                  if (success && schoolController.selectedSchool.value != null && selectedClass != null) {
                    await timetableController.getAllTimetables(
                      schoolId: schoolController.selectedSchool.value!.id,
                      classId: selectedClass!.id,
                      sectionId: selectedSection?.id,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: _DS.primary, foregroundColor: Colors.white),
                child: const Text('Assign'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditPeriodDialog(String day, int period) {
    if (schoolController.selectedSchool.value != null) schoolController.loadTeachers();
    String existingSubject = '';
    String? existingTeacherId;

    if (timetableController.timetables.isNotEmpty) {
      final timetable = timetableController.timetables.first;
      final weeklySchedule = timetable['weeklySchedule'] as List? ?? [];
      final daySchedule = weeklySchedule.firstWhere((ws) => ws['day'] == day, orElse: () => null);
      if (daySchedule != null) {
        final periods = daySchedule['periods'] as List? ?? [];
        final periodData = periods.firstWhere((p) => p['periodNumber'] == period, orElse: () => null);
        if (periodData != null) {
          existingSubject = periodData['subjectName'] ?? '';
          final teacherData = periodData['teacherId'];
          if (teacherData is Map) existingTeacherId = teacherData['_id'];
        }
      }
    }

    final subjectController = TextEditingController(text: existingSubject);
    final searchController = TextEditingController();
    String? selectedTeacherId = existingTeacherId;
    final filteredTeachers = <Map<String, dynamic>>[].obs;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          if (filteredTeachers.isEmpty) filteredTeachers.value = schoolController.teachers;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radiusLg)),
            title: Text('Edit Period - $day Period $period'),
            content: SizedBox(
              width: 300,
              height: 350,
              child: Column(
                children: [
                  _field(subjectController, 'Subject', context),
                  const SizedBox(height: 16),
                  _field(searchController, 'Search Teacher', context, prefix: ''),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Obx(() => Container(
                          decoration: BoxDecoration(border: Border.all(color: _DS.border), borderRadius: BorderRadius.circular(_DS.radiusSm)),
                          child: schoolController.teachers.isEmpty
                              ? Center(child: Text('Loading...', style: TextStyle(fontSize: _Responsive.fontSize(context))))
                              : ListView.builder(
                                  itemCount: filteredTeachers.length,
                                  itemBuilder: (context, index) {
                                    final teacher = filteredTeachers[index];
                                    final isSelected = selectedTeacherId == teacher['_id'];
                                    return ListTile(
                                      selected: isSelected,
                                      leading: CircleAvatar(backgroundColor: isSelected ? _DS.primary : _DS.primarySoft, child: Icon(Icons.person, color: isSelected ? Colors.white : _DS.primary, size: 20)),
                                      title: Text(teacher['userName'] ?? 'Unknown'),
                                      trailing: isSelected ? Icon(Icons.check_circle_rounded, color: _DS.primary) : null,
                                      onTap: () => setState(() => selectedTeacherId = teacher['_id']),
                                    );
                                  },
                                ),
                        )),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
              if (ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/timetable/deleteperiod'))
                TextButton(
                  onPressed: () {
                    Get.back();
                    Get.snackbar('Success', 'Period deleted', backgroundColor: _DS.success, colorText: Colors.white);
                  },
                  child: const Text('Delete', style: TextStyle(color: _DS.danger)),
                ),
              ElevatedButton(
                onPressed: () async {
                  if (subjectController.text.isEmpty) {
                    Get.snackbar('Error', 'Please enter a subject', backgroundColor: _DS.danger, colorText: Colors.white);
                    return;
                  }
                  if (selectedTeacherId == null) {
                    Get.snackbar('Error', 'Please select a teacher', backgroundColor: _DS.danger, colorText: Colors.white);
                    return;
                  }
                  if (schoolController.selectedSchool.value == null || selectedClass == null) {
                    Get.snackbar('Error', 'School and class must be selected', backgroundColor: _DS.danger, colorText: Colors.white);
                    return;
                  }
                  if (timetableController.timetables.isEmpty) {
                    Get.snackbar('Error', 'No timetable found', backgroundColor: _DS.danger, colorText: Colors.white);
                    return;
                  }
                  final timetable = timetableController.timetables.first;
                  final weeklySchedule = timetable['weeklySchedule'] as List? ?? [];
                  final daySchedule = weeklySchedule.firstWhere((ws) => ws['day'] == day, orElse: () => null);
                  if (daySchedule == null) {
                    Get.snackbar('Error', 'Day not found', backgroundColor: _DS.danger, colorText: Colors.white);
                    return;
                  }
                  final dayId = daySchedule['_id'] as String?;
                  if (dayId == null) {
                    Get.snackbar('Error', 'Invalid timetable data', backgroundColor: _DS.danger, colorText: Colors.white);
                    return;
                  }
                  Get.back();
                  final success = await timetableController.updatePeriod(
                    schoolId: schoolController.selectedSchool.value!.id,
                    classId: selectedClass!.id,
                    sectionId: selectedSection?.id,
                    weeklyScheduleId: dayId,
                    day: day,
                    periodData: {'periodNumber': period, 'subjectName': subjectController.text, 'teacherId': selectedTeacherId},
                  );
                  if (success) {
                    await timetableController.getAllTimetables(
                      schoolId: schoolController.selectedSchool.value!.id,
                      classId: selectedClass!.id,
                      sectionId: selectedSection?.id,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: _DS.primary, foregroundColor: Colors.white),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}