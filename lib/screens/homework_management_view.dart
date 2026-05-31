import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/controllers/homework_controller.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/core/rbac/api_rbac.dart';
import 'package:school_app/models/school_models.dart';
import 'package:school_app/screens/homework_detail_view.dart';

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

  static double iconSize(BuildContext context) =>
      isTablet(context) ? 20 : 16;

  static double headerFontSize(BuildContext context) =>
      isTablet(context) ? 20 : 17;

  static double bodyFontSize(BuildContext context) =>
      isTablet(context) ? 14 : 13;
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
    {TextInputType? keyboardType, bool obscure = false, String? prefix, Widget? suffixIcon, int maxLines = 1, String? hint, IconData? icon}) {
  return TextField(
    controller: ctrl,
    obscureText: obscure,
    keyboardType: keyboardType,
    maxLines: maxLines,
    style: TextStyle(fontSize: _Responsive.fontSize(context), color: _DS.textPrimary),
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefix,
      prefixIcon: icon != null ? Icon(icon, color: _DS.primary, size: 20) : null,
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
  required void Function(T?)? onChanged,
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

// ─── File Attachment Preview ──────────────────────────────────────────────────
Widget _filePreview({required PlatformFile file, required VoidCallback onRemove, required BuildContext context}) {
  final isImage = ['jpg', 'jpeg', 'png', 'gif'].contains(file.extension?.toLowerCase());

  return Container(
    decoration: BoxDecoration(
      color: _DS.surface,
      borderRadius: BorderRadius.circular(_DS.radiusSm),
      border: Border.all(color: _DS.border),
    ),
    child: Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(_DS.radiusSm),
          child: isImage && file.bytes != null
              ? Image.memory(file.bytes!, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
              : Container(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_getFileIcon(file.extension ?? ''), color: _DS.primary, size: 24),
                      const SizedBox(height: 6),
                      Text(
                        file.name,
                        style: TextStyle(fontSize: _Responsive.fontSize(context, mobile: 10, tablet: 11), color: _DS.textPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: _DS.danger, shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 12),
            ),
          ),
        ),
      ],
    ),
  );
}

IconData _getFileIcon(String extension) {
  switch (extension.toLowerCase()) {
    case 'pdf': return Icons.picture_as_pdf_rounded;
    case 'doc': case 'docx': return Icons.description_rounded;
    case 'jpg': case 'jpeg': case 'png': case 'gif': return Icons.image_rounded;
    case 'mp4': case 'avi': case 'mov': return Icons.video_file_rounded;
    default: return Icons.insert_drive_file_rounded;
  }
}

// ─── MAIN VIEW ────────────────────────────────────────────────────────────────
class HomeworkManagementView extends StatefulWidget {
  @override
  State<HomeworkManagementView> createState() => _HomeworkManagementViewState();
}

class _HomeworkManagementViewState extends State<HomeworkManagementView> with TickerProviderStateMixin {
  final schoolController = Get.find<SchoolController>();
  final homeworkController = Get.put(HomeworkController());
  final authController = Get.find<AuthController>();

  late TabController _tabController;
  SchoolClass? selectedClass;
  Section? selectedSection;
  DateTime selectedDate = DateTime.now();

  final subjectController = TextEditingController();
  final descriptionController = TextEditingController();
  final academicYearController = TextEditingController(text: '2024-2025');

  List<PlatformFile> selectedFiles = [];
  bool _filtersExpanded = false;

  @override
  void initState() {
    super.initState();
    final initialCount = _getAvailableTabsCount();
    _tabController = TabController(length: initialCount, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (schoolController.selectedSchool.value != null) {
        schoolController.getAllClasses(schoolController.selectedSchool.value!.id);
      } else {
        schoolController.getAllSchools().then((_) {
          if (ApiPermissions.isSchoolReadOnly(currentUserRole)) {
            final userSchoolId = authController.user.value?.schoolId;
            if (userSchoolId != null) {
              final userSchool = schoolController.schools.firstWhereOrNull((s) => s.id == userSchoolId);
              if (userSchool != null) {
                schoolController.selectedSchool.value = userSchool;
                schoolController.getAllClasses(userSchool.id);
              }
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    subjectController.dispose();
    descriptionController.dispose();
    academicYearController.dispose();
    super.dispose();
  }

  String get currentUserRole => authController.user.value?.role?.toLowerCase() ?? '';

  int _getAvailableTabsCount() {
    int count = 0;
    if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/homework/create')) count++;
    if (ApiPermissions.hasApiAccess(currentUserRole, 'GET /api/homework/getall')) count++;
    return count > 0 ? count : 1;
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateShort(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final yr = date.year.toString().substring(2);
    return "${date.day} ${months[date.month - 1]} '$yr";
  }

  String _formatDateString(String? raw) {
    if (raw == null || raw.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return _formatDate(dt);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = _Responsive.isTablet(context);

    return Scaffold(
      backgroundColor: _DS.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isTablet),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _buildTabViews(isTablet),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_DS.primary, _DS.primaryDark]),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
        boxShadow: [BoxShadow(color: _DS.primary.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(_Responsive.padding(context), isTablet ? 24 : 16, _Responsive.padding(context), 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(14)),
                  child: Icon(Icons.assignment_rounded, color: Colors.white, size: _Responsive.iconSize(context)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Homework',
                        style: TextStyle(color: Colors.white, fontSize: _Responsive.headerFontSize(context), fontWeight: FontWeight.w800, letterSpacing: -0.3),
                      ),
                      Text(
                        'Create & manage assignments',
                        style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: _Responsive.fontSize(context, mobile: 11, tablet: 12)),
                      ),
                    ],
                  ),
                ),
                Obx(() {
                  final school = schoolController.selectedSchool.value;
                  if (school == null) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.school_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 5),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 100),
                          child: Text(
                            school.name,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Tab Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: _Responsive.padding(context)),
            child: Container(
              height: isTablet ? 44 : 40,
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
                tabs: _buildTabs(),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  List<Widget> _buildTabs() {
    List<Widget> tabs = [];
    final isTablet = _Responsive.isTablet(context);

    if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/homework/create')) {
      tabs.add(Tab(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_task_rounded, size: isTablet ? 14 : 12),
              const SizedBox(width: 6),
              Text('Create', style: TextStyle(fontSize: _Responsive.fontSize(context, mobile: 12, tablet: 13))),
            ],
          ),
        ),
      ));
    }
    if (ApiPermissions.hasApiAccess(currentUserRole, 'GET /api/homework/getall')) {
      tabs.add(Tab(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.list_alt_rounded, size: isTablet ? 14 : 12),
              const SizedBox(width: 6),
              Text('View', style: TextStyle(fontSize: _Responsive.fontSize(context, mobile: 12, tablet: 13))),
            ],
          ),
        ),
      ));
    }
    return tabs.isNotEmpty ? tabs : [const Tab(text: 'No Access')];
  }

  List<Widget> _buildTabViews(bool isTablet) {
    List<Widget> views = [];
    if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/homework/create')) {
      views.add(_buildCreateTab(isTablet));
    }
    if (ApiPermissions.hasApiAccess(currentUserRole, 'GET /api/homework/getall')) {
      views.add(_buildViewAllTab(isTablet));
    }
    return views.isNotEmpty ? views : [_buildNoAccessView()];
  }

  Widget _buildNoAccessView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline_rounded, size: _Responsive.isTablet(context) ? 80 : 64, color: _DS.textMuted),
          const SizedBox(height: 24),
          Text('No Access', style: TextStyle(fontSize: _Responsive.fontSize(context, mobile: 20, tablet: 24), fontWeight: FontWeight.bold, color: _DS.textSecondary)),
          const SizedBox(height: 16),
          Text('You don\'t have permission to access homework management', style: TextStyle(fontSize: _Responsive.fontSize(context, mobile: 13, tablet: 14), color: _DS.textMuted), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ─── Create Tab ────────────────────────────────────────────────────────────
  Widget _buildCreateTab(bool isTablet) {
    return RefreshIndicator(
      onRefresh: () async {
        if (schoolController.selectedSchool.value != null && selectedClass != null) {
          await homeworkController.getAllHomework(
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
            _buildCollapsibleFilters(context, isTablet),
            const SizedBox(height: 20),
            _buildHomeworkForm(isTablet),
          ],
        ),
      ),
    );
  }

  // ─── View All Tab ──────────────────────────────────────────────────────────
  Widget _buildViewAllTab(bool isTablet) {
    return RefreshIndicator(
      onRefresh: () async {
        if (schoolController.selectedSchool.value != null && selectedClass != null) {
          await homeworkController.getAllHomework(
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
            _buildCollapsibleFilters(context, isTablet),
            const SizedBox(height: 20),
            _buildHomeworkList(isTablet),
          ],
        ),
      ),
    );
  }

  // ─── Collapsible Filters ───────────────────────────────────────────────────
  Widget _buildCollapsibleFilters(BuildContext context, bool isTablet) {
    return _CollapsibleSelector(
      title: 'Filters',
      icon: Icons.tune_rounded,
      initiallyExpanded: _filtersExpanded,
      child: Column(
        children: [
          _buildClassSelector(context),
          if (ApiPermissions.hasSectionAccess(currentUserRole)) ...[
            const SizedBox(height: 12),
            _buildSectionSelector(context),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildDateSelector(context)),
              const SizedBox(width: 12),
              Expanded(child: _buildAcademicYearField(context)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _primaryBtn(
                  context: context,
                  label: _filtersExpanded ? 'Hide Filters' : 'Apply Filters',
                  icon: _filtersExpanded ? Icons.expand_less : Icons.check_rounded,
                  onPressed: () => setState(() => _filtersExpanded = !_filtersExpanded),
                  fullWidth: true,
                  height: 60,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClassSelector(BuildContext context) {
    return Obx(() {
      final sortedClasses = List<SchoolClass>.from(schoolController.classes);
      sortedClasses.sort((a, b) => _compareClassNames(a.name, b.name));

      return _dropdown<SchoolClass>(
        value: selectedClass,
        hint: sortedClasses.isEmpty && schoolController.selectedSchool.value != null ? 'Loading classes...' : 'Select Class',
        icon: Icons.class_rounded,
        context: context,
        selectedItemBuilder: sortedClasses.map((c) => Text(c.name, overflow: TextOverflow.ellipsis, style: TextStyle(color: _DS.textPrimary, fontSize: _Responsive.fontSize(context)))).toList(),
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
        onChanged: sortedClasses.isEmpty
            ? null
            : (cls) {
                setState(() {
                  selectedClass = cls;
                  selectedSection = null;
                });
                if (cls != null && schoolController.selectedSchool.value != null) {
                  schoolController.getAllSections(classId: cls.id, schoolId: schoolController.selectedSchool.value!.id);
                  homeworkController.getAllHomework(
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
          hint: 'All Sections',
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
            if (selectedClass != null && schoolController.selectedSchool.value != null) {
              homeworkController.getAllHomework(
                schoolId: schoolController.selectedSchool.value!.id,
                classId: selectedClass!.id,
                sectionId: section?.id,
              );
            }
          },
        ));
  }

  Widget _buildDateSelector(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: _DS.primary)),
            child: child!,
          ),
        );
        if (date != null) setState(() => selectedDate = date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(color: _DS.surfaceAlt, border: Border.all(color: _DS.border), borderRadius: BorderRadius.circular(_DS.radiusSm)),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, color: _DS.primary, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Due Date', style: TextStyle(fontSize: 9, color: _DS.textMuted, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(_formatDateShort(selectedDate), overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _DS.textPrimary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcademicYearField(BuildContext context) {
    return TextFormField(
      controller: academicYearController,
      style: TextStyle(fontSize: _Responsive.fontSize(context, mobile: 12, tablet: 13), fontWeight: FontWeight.w600, color: _DS.textPrimary),
      decoration: InputDecoration(
        labelText: 'Academic Year',
        labelStyle: TextStyle(fontSize: 12, color: _DS.textMuted),
        prefixIcon: Icon(Icons.school_outlined, color: _DS.primary, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(_DS.radiusSm), borderSide: const BorderSide(color: _DS.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_DS.radiusSm), borderSide: const BorderSide(color: _DS.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_DS.radiusSm), borderSide: const BorderSide(color: _DS.primary, width: 1.5)),
        filled: true,
        fillColor: _DS.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  // ─── Create Homework Form ──────────────────────────────────────────────────
  Widget _buildHomeworkForm(bool isTablet) {
    if (schoolController.selectedSchool.value == null || selectedClass == null) {
      return _emptyState(
        context,
        icon: Icons.touch_app_rounded,
        title: 'Select a class',
        subtitle: 'Choose a class from the filters above to create homework',
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
        children: [
          // Card header
          Container(
            padding: EdgeInsets.all(isTablet ? _DS.spacingXl : _DS.spacingLg),
            decoration: BoxDecoration(color: _DS.primarySoft, borderRadius: const BorderRadius.only(topLeft: Radius.circular(_DS.radiusLg), topRight: Radius.circular(_DS.radiusLg))),
            child: Row(
              children: [
                _iconBox(Icons.assignment_add, size: 20),
                const SizedBox(width: 12),
                Text('New Assignment', style: TextStyle(fontSize: _Responsive.headerFontSize(context), fontWeight: FontWeight.w700, color: _DS.primaryDark)),
                const Spacer(),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: _DS.primary, borderRadius: BorderRadius.circular(20)), child: Text(selectedClass!.name, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isTablet ? _DS.spacingXl : _DS.spacingLg),
            child: Column(
              children: [
                _field(subjectController, 'Subject Name', context, hint: 'e.g. Mathematics', prefix: '', icon: Icons.menu_book_rounded),
                const SizedBox(height: 14),
                _field(descriptionController, 'Description', context, hint: 'Describe the homework assignment...', prefix: '', maxLines: 4),
                const SizedBox(height: 14),
                _buildFileAttachments(isTablet),
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, height: 50, child: _primaryBtn(context: context, label: 'Create Homework', icon: Icons.add_task_rounded, onPressed: _createHomework, fullWidth: true)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── File Attachments ──────────────────────────────────────────────────────
  Widget _buildFileAttachments(bool isTablet) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: selectedFiles.isEmpty ? _DS.border : _DS.primary.withOpacity(0.4)), borderRadius: BorderRadius.circular(_DS.radiusSm), color: _DS.surfaceAlt),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.attach_file_rounded, color: _DS.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Attachments', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _DS.textPrimary)),
                      Text(selectedFiles.isEmpty ? 'No files selected' : '${selectedFiles.length} file${selectedFiles.length > 1 ? 's' : ''} selected', style: TextStyle(fontSize: 11, color: _DS.textMuted)),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickFiles,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add'),
                  style: TextButton.styleFrom(foregroundColor: _DS.primary, backgroundColor: _DS.primarySoft, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                ),
              ],
            ),
          ),
          if (selectedFiles.isNotEmpty) ...[
            Divider(height: 1, color: _DS.border),
            Padding(
              padding: const EdgeInsets.all(10),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: isTablet ? 4 : 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1),
                itemCount: selectedFiles.length,
                itemBuilder: (context, index) {
                  final file = selectedFiles[index];
                  return _filePreview(file: file, onRemove: () => setState(() => selectedFiles.removeAt(index)), context: context);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Homework List ─────────────────────────────────────────────────────────
  Widget _buildHomeworkList(bool isTablet) {
    return _card(
      context: context,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? _DS.spacingXl : _DS.spacingLg),
            decoration: BoxDecoration(color: _DS.primarySoft, borderRadius: const BorderRadius.only(topLeft: Radius.circular(_DS.radiusLg), topRight: Radius.circular(_DS.radiusLg))),
            child: Row(
              children: [
                _iconBox(Icons.list_alt_rounded, size: 20),
                const SizedBox(width: 12),
                Text('Assignments', style: TextStyle(fontSize: _Responsive.headerFontSize(context), fontWeight: FontWeight.w700, color: _DS.primaryDark)),
                const Spacer(),
                Obx(() {
                  final count = homeworkController.homeworkList.length;
                  return _badge('$count item${count != 1 ? 's' : ''}', bg: _DS.primary, fg: Colors.white);
                }),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isTablet ? _DS.spacingXl : _DS.spacingLg),
            child: _buildHomeworkItems(isTablet),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeworkItems(bool isTablet) {
    return Obx(() {
      if (homeworkController.isLoading.value) {
        return Center(child: Padding(padding: EdgeInsets.all(_DS.spacingXl), child: CircularProgressIndicator(color: _DS.primary, strokeWidth: 2)));
      }

      final homeworkItems = homeworkController.homeworkList;

      if (homeworkItems.isEmpty) {
        return _emptyState(
          context,
          icon: Icons.assignment_outlined,
          title: selectedClass == null ? 'Select a class' : 'No assignments found',
          subtitle: selectedClass == null ? 'Choose a class from the filters above to view homework' : 'No homework has been assigned for this class yet',
        );
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: homeworkItems.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = homeworkItems[index];
          final subjects = (item['subjects'] as List?) ?? [];

          return Column(
            children: subjects.map<Widget>((subject) {
              final dateStr = _formatDateString(item['homeworkDate']);
              final teacherName = (subject['teacherId'] is Map) ? (subject['teacherId']['userName'] ?? 'N/A') : 'N/A';
              final hasAttachments = (subject['attachments'] as List?)?.isNotEmpty ?? false;

              return GestureDetector(
                onTap: () => Get.to(() => HomeworkDetailView(homework: item)),
                child: Container(
                  decoration: BoxDecoration(color: _DS.surface, borderRadius: BorderRadius.circular(_DS.radius), border: Border.all(color: _DS.border), boxShadow: _DS.shadow),
                  child: Column(
                    children: [
                      // Header row
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
                        child: Row(
                          children: [
                            _iconBox(Icons.assignment_rounded, size: 18, bg: _DS.primarySoft, fg: _DS.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(subject['subjectName'] ?? 'Subject', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _DS.textPrimary)),
                                  const SizedBox(height: 4),
                                  _infoRow(Icons.calendar_today_rounded, dateStr, context),
                                  const SizedBox(height: 2),
                                  _infoRow(Icons.person_rounded, teacherName, context),
                                ],
                              ),
                            ),
                            // Actions
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // ── FIX: removed one extra closing parenthesis ──
                                _actionBtn(
                                  icon: Icons.visibility_rounded,
                                  color: _DS.primary,
                                  onTap: () => Get.to(() => HomeworkDetailView(
                                    homework: {
                                      'homeworkDate': item['homeworkDate'],
                                      'subjects': [subject],
                                    },
                                  )),
                                ),
                                if (ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/homework/updatetext') || ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/homework/deleteentireday'))
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.more_vert_rounded, color: _DS.textMuted, size: 20),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    itemBuilder: (context) => [
                                      if (ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/homework/updatetext'))
                                        PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 16, color: _DS.textPrimary), const SizedBox(width: 8), const Text('Edit')])),
                                      if (ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/homework/deleteentireday'))
                                        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_rounded, size: 16, color: _DS.danger), SizedBox(width: 8), Text('Delete', style: TextStyle(color: _DS.danger))])),
                                    ],
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showEditHomeworkDialog(subject);
                                      } else if (value == 'delete') {
                                        _showDeleteConfirmation(item);
                                      }
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Description preview
                      if ((subject['description'] ?? '').isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                          child: Text(subject['description'], maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: _Responsive.fontSize(context, mobile: 12, tablet: 13), color: _DS.textSecondary, height: 1.4)),
                        ),
                      // Attachment indicator
                      if (hasAttachments)
                        Container(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                          child: Row(
                            children: [
                              Icon(Icons.attach_file_rounded, size: 12, color: _DS.primary),
                              const SizedBox(width: 4),
                              Text('${(subject['attachments'] as List).length} attachment${(subject['attachments'] as List).length > 1 ? 's' : ''}', style: TextStyle(fontSize: 11, color: _DS.primary, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      );
    });
  }

  Widget _infoRow(IconData icon, String text, BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: _DS.textMuted),
        const SizedBox(width: 4),
        Flexible(child: Text(text, style: TextStyle(fontSize: _Responsive.fontSize(context, mobile: 11, tablet: 12), color: _DS.textSecondary))),
      ],
    );
  }

  Widget _actionBtn({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: _DS.primarySoft, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  // ─── Dialogs ───────────────────────────────────────────────────────────────
  void _showImagePreview(Uint8List bytes) {
    Get.dialog(Dialog(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Center(child: InteractiveViewer(child: Image.memory(bytes, fit: BoxFit.contain))),
          Positioned(
            top: 40,
            right: 20,
            child: GestureDetector(
              onTap: () => Get.back(),
              child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close_rounded, color: Colors.white, size: 24)),
            ),
          ),
        ],
      ),
    ));
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.any, withData: true);
    if (result != null) setState(() => selectedFiles.addAll(result.files));
  }

  void _createHomework() async {
    if (schoolController.selectedSchool.value == null || selectedClass == null || subjectController.text.isEmpty || descriptionController.text.isEmpty) {
      Get.snackbar('Missing Fields', 'Please fill all required fields', backgroundColor: _DS.danger, colorText: Colors.white, borderRadius: 12, margin: const EdgeInsets.all(16), icon: const Icon(Icons.warning_rounded, color: Colors.white));
      return;
    }

    final success = await homeworkController.createHomework(
      schoolId: schoolController.selectedSchool.value!.id,
      academicYear: academicYearController.text,
      classId: selectedClass!.id,
      sectionId: selectedSection?.id,
      homeworkDate: selectedDate.toIso8601String().split('T')[0],
      subjectName: subjectController.text,
      description: descriptionController.text,
      files: selectedFiles.isNotEmpty ? selectedFiles : null,
    );

    if (success) {
      subjectController.clear();
      descriptionController.clear();
      setState(() => selectedFiles.clear());
    }
  }

  void _showEditHomeworkDialog(Map<String, dynamic> subject) {
    final editSubjectController = TextEditingController(text: subject['subjectName']);
    final editDescriptionController = TextEditingController(text: subject['description']);
    final editFiles = <PlatformFile>[].obs;

    Get.dialog(StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radiusLg)),
        title: const Text('Edit Homework', style: TextStyle(fontWeight: FontWeight.w700, color: _DS.textPrimary)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(editSubjectController, 'Subject Name', context, maxLines: 1),
              const SizedBox(height: 14),
              _field(editDescriptionController, 'Description', context, maxLines: 3),
              const SizedBox(height: 14),
              Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${editFiles.length} file(s) selected', style: TextStyle(color: _DS.textMuted, fontSize: 12)),
                  const SizedBox(height: 8),
                  SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
                    if (result != null) editFiles.addAll(result.files);
                  }, icon: const Icon(Icons.attach_file_rounded, size: 16), label: const Text('Add Files'), style: OutlinedButton.styleFrom(foregroundColor: _DS.primary, side: BorderSide(color: _DS.primary)))),
                ],
              )),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _DS.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Get.back();
              if (editFiles.isEmpty) return;
              Get.dialog(WillPopScope(onWillPop: () async => false, child: const AlertDialog(content: Row(children: [CircularProgressIndicator(color: _DS.primary), SizedBox(width: 16), Text('Uploading...')]))), barrierDismissible: false);
              try {
                final homework = homeworkController.homeworkList.firstWhereOrNull((h) => (h['subjects'] as List).any((s) => s['_id'] == subject['_id']));
                if (homework == null) return;
                final success = await homeworkController.addAttachments(homeworkId: homework['_id'], subjectId: subject['_id'], files: editFiles);
                if (Get.isDialogOpen == true) Navigator.pop(Get.context!);
                if (success && schoolController.selectedSchool.value != null && selectedClass != null) {
                  await homeworkController.getAllHomework(schoolId: schoolController.selectedSchool.value!.id, classId: selectedClass!.id, sectionId: selectedSection?.id);
                }
              } catch (e) {
                if (Get.isDialogOpen == true) Get.back();
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    ));
  }

  void _showDeleteConfirmation(Map<String, dynamic> homework) {
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radiusLg)),
      title: const Row(children: [Icon(Icons.warning_rounded, color: _DS.danger, size: 20), SizedBox(width: 8), Text('Delete Homework', style: TextStyle(fontWeight: FontWeight.w700, color: _DS.textPrimary))]),
      content: const Text('Are you sure you want to delete this homework? This cannot be undone.', style: TextStyle(color: _DS.textSecondary)),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            Get.back();
            Get.dialog(WillPopScope(onWillPop: () async => false, child: const AlertDialog(content: Row(children: [CircularProgressIndicator(color: _DS.primary), SizedBox(width: 16), Text('Deleting...')]))), barrierDismissible: false);
            final homeworkId = homeworkController.homeworkList.firstWhereOrNull((h) => (h['subjects'] as List).any((s) => s['_id'] == homework['_id']))?['_id'];
            if (homeworkId != null) {
              final success = await homeworkController.deleteEntireDay(homeworkId);
              Get.back();
              if (success && schoolController.selectedSchool.value != null && selectedClass != null) {
                await homeworkController.getAllHomework(schoolId: schoolController.selectedSchool.value!.id, classId: selectedClass!.id, sectionId: selectedSection?.id);
              }
            } else {
              Get.back();
              Get.snackbar('Error', 'Could not find homework to delete', backgroundColor: _DS.danger, colorText: Colors.white);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: _DS.danger, foregroundColor: Colors.white),
          child: const Text('Delete'),
        ),
      ],
    ));
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────
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
}