import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/controllers/homework_controller.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/core/rbac/api_rbac.dart';
import 'package:school_app/core/utils/academic_year_utils.dart';
import 'package:school_app/models/school_models.dart';
import 'package:school_app/screens/homework_detail_view.dart';

// ─── Design tokens (matching StudentRecordsView style) ────────────────────────
const _kPrimary     = Color(0xFF2563EB);
const _kPrimaryBg   = Color(0xFFEFF6FF);
const _kBg          = Color(0xFFF0F5FF);
const _kSurface     = Color(0xFFFFFFFF);
const _kBorder      = Color(0xFFDDE6F5);
const _kText        = Color(0xFF1A2A3A);
const _kTextSub     = Color(0xFF475569);
const _kTextMuted   = Color(0xFF90A4BE);
const _kSuccess     = Color(0xFF10B981);
const _kWarning     = Color(0xFFF59E0B);
const _kDanger      = Color(0xFFEF4444);

IconData _getFileIcon(String extension) {
  switch (extension.toLowerCase()) {
    case 'pdf':  return Icons.picture_as_pdf_rounded;
    case 'doc':  case 'docx': return Icons.description_rounded;
    case 'jpg':  case 'jpeg': case 'png': case 'gif': return Icons.image_rounded;
    case 'mp4':  case 'avi':  case 'mov': return Icons.video_file_rounded;
    default: return Icons.insert_drive_file_rounded;
  }
}

Widget _filePreview({required PlatformFile file, required VoidCallback onRemove, required BuildContext context}) {
  final isImage = ['jpg', 'jpeg', 'png', 'gif'].contains(file.extension?.toLowerCase());
  return Container(
    decoration: BoxDecoration(color: _kSurface, borderRadius: BorderRadius.circular(10), border: Border.all(color: _kBorder)),
    child: Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: isImage && file.bytes != null
              ? Image.memory(file.bytes!, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
              : Container(
            padding: const EdgeInsets.all(10),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(_getFileIcon(file.extension ?? ''), color: _kPrimary, size: 22),
              const SizedBox(height: 4),
              Text(file.name, style: const TextStyle(fontSize: 10, color: _kText), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
            ]),
          ),
        ),
        Positioned(
          top: 3, right: 3,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: _kDanger, shape: BoxShape.circle), child: const Icon(Icons.close_rounded, color: Colors.white, size: 11)),
          ),
        ),
      ],
    ),
  );
}

// ─── MAIN VIEW ────────────────────────────────────────────────────────────────
class HomeworkManagementView extends StatefulWidget {
  @override
  State<HomeworkManagementView> createState() => _HomeworkManagementViewState();
}

class _HomeworkManagementViewState extends State<HomeworkManagementView>
    with TickerProviderStateMixin {
  final schoolController  = Get.find<SchoolController>();
  final homeworkController = Get.put(HomeworkController());
  final authController    = Get.find<AuthController>();

  late TabController _tabController;

  SchoolClass? selectedClass;
  Section?     selectedSection;
  DateTime     selectedDate       = DateTime.now();
  final        subjectCtrl        = TextEditingController();
  final        descriptionCtrl    = TextEditingController();
 // final        academicYearCtrl   = TextEditingController(text: '2025-2026');
  static String _currentAcademicYear() {
    final now = DateTime.now();
    // Academic year starts in June — adjust month threshold to match your school
    final startYear = now.month >= 6 ? now.year : now.year - 1;
    return '$startYear-${startYear + 1}';
  }

  final academicYearCtrl = TextEditingController(text: AcademicYearUtils.getCurrentAcademicYear());
  List<PlatformFile> selectedFiles = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initSchool());
  }

  void _initSchool() {
    if (schoolController.selectedSchool.value != null) {
      schoolController.getAllClasses(schoolController.selectedSchool.value!.id);
    } else {
      schoolController.getAllSchools().then((_) {
        if (ApiPermissions.isSchoolReadOnly(currentRole)) {
          final id = authController.user.value?.schoolId;
          if (id != null) {
            final s = schoolController.schools.firstWhereOrNull((s) => s.id == id);
            if (s != null) {
              schoolController.selectedSchool.value = s;
              schoolController.getAllClasses(s.id);
            }
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    subjectCtrl.dispose();
    descriptionCtrl.dispose();
    academicYearCtrl.dispose();
    super.dispose();
  }

  String get currentRole => authController.user.value?.role?.toLowerCase() ?? '';

  int get _tabCount {
    int c = 0;
    if (ApiPermissions.hasApiAccess(currentRole, 'POST /api/homework/create')) c++;
    if (ApiPermissions.hasApiAccess(currentRole, 'GET /api/homework/getall'))  c++;
    return c > 0 ? c : 1;
  }

  // ── date helpers ──────────────────────────────────────────────────────────
  static const _months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

  String _fmtDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';
  String _fmtDateShort(DateTime d) {
    final yr = d.year.toString().substring(2);
    return "${d.day} ${_months[d.month - 1]} '$yr";
  }
  String _fmtDateStr(String? raw) {
    if (raw == null || raw.isEmpty) return 'N/A';
    try { return _fmtDate(DateTime.parse(raw).toLocal()); } catch (_) { return raw; }
  }

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(child: TabBarView(controller: _tabController, children: _buildTabViews())),
          ],
        ),
      ),
    );
  }

  // ── AppBar (matching student records style) ───────────────────────────────
  Widget _buildAppBar() {
    final tabs = _buildTabs();
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
        boxShadow: [BoxShadow(color: _kBorder.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _kPrimary.withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.assignment_rounded, color: _kPrimary, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Homework', style: TextStyle(color: _kText, fontSize: 15, fontWeight: FontWeight.w700)),
                      Text('Create & manage assignments', style: TextStyle(color: _kTextMuted, fontSize: 11)),
                    ],
                  ),
                ),
                Obx(() {
                  final school = schoolController.selectedSchool.value;
                  if (school == null) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: _kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                    child: Text(school.name.length > 12 ? '${school.name.substring(0, 12)}…' : school.name,
                        style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600, fontSize: 10)),
                  );
                }),
              ],
            ),
          ),
          // Tab bar
          Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kBorder)),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: _kPrimary,
                borderRadius: BorderRadius.circular(9),
                boxShadow: [BoxShadow(color: _kPrimary.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3))],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: _kTextMuted,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              tabs: tabs,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTabs() {
    final tabs = <Widget>[];
    if (ApiPermissions.hasApiAccess(currentRole, 'POST /api/homework/create')) {
      tabs.add(Tab(height: 34, child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.add_task_rounded, size: 13), SizedBox(width: 5), Text('Create')])));
    }
    if (ApiPermissions.hasApiAccess(currentRole, 'GET /api/homework/getall')) {
      tabs.add(Tab(height: 34, child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.list_alt_rounded, size: 13), SizedBox(width: 5), Text('View')])));
    }
    return tabs.isNotEmpty ? tabs : [const Tab(text: 'No Access')];
  }

  List<Widget> _buildTabViews() {
    final views = <Widget>[];
    if (ApiPermissions.hasApiAccess(currentRole, 'POST /api/homework/create')) views.add(_createTab());
    if (ApiPermissions.hasApiAccess(currentRole, 'GET /api/homework/getall'))  views.add(_viewTab());
    return views.isNotEmpty ? views : [_noAccessView()];
  }

  // ── Shared filter bar (chips, like student records) ───────────────────────
  Widget _buildFilterBar() {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: class + section chips
        Row(children: [
          _filterChip(
            label: selectedClass?.name ?? 'All Classes',
            icon: Icons.class_rounded,
            active: selectedClass != null,
            onTap: () => _showClassSheet(),
          ),
          const SizedBox(width: 8),
          if (ApiPermissions.hasSectionAccess(currentRole))
            _filterChip(
              label: selectedSection?.name ?? 'All Sections',
              icon: Icons.group_rounded,
              active: selectedSection != null,
              onTap: () => _showSectionSheet(),
            ),
        ]),
        const SizedBox(height: 10),
        // Row 2: date + academic year + search + clear
        Row(children: [
          // Due date chip
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: _kPrimary)),
                  child: child!,
                ),
              );
              if (d != null) setState(() => selectedDate = d);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: _kBorder),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.calendar_today_rounded, size: 13, color: _kTextMuted),
                const SizedBox(width: 5),
                Text(_fmtDateShort(selectedDate), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kTextSub)),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          // Academic year chip
          GestureDetector(
            onTap: () => _showAcademicYearSheet(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: _kBorder),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.school_outlined, size: 13, color: _kTextMuted),
                const SizedBox(width: 5),
                Text(academicYearCtrl.text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kTextSub)),
                const SizedBox(width: 3),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 13, color: _kTextMuted),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          // Search button
          // GestureDetector(
          //   onTap: _applyFilter,
          //   child: Container(
          //     padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          //     decoration: BoxDecoration(
          //       color: _kPrimary,
          //       borderRadius: BorderRadius.circular(100),
          //       boxShadow: [BoxShadow(color: _kPrimary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
          //     ),
          //     child: const Row(mainAxisSize: MainAxisSize.min, children: [
          //       Icon(Icons.search_rounded, size: 14, color: Colors.white),
          //       SizedBox(width: 5),
          //       Text('Search', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
          //     ]),
          //   ),
          // ),
          if (selectedClass != null || selectedSection != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() { selectedClass = null; selectedSection = null; }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(100)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.close_rounded, size: 13, color: Colors.red.shade600),
                  const SizedBox(width: 4),
                  Text('Clear', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red.shade600)),
                ]),
              ),
            ),
          ],
        ]),
      ],
    ));
  }

  Widget _filterChip({required String label, required IconData icon, required bool active, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _kPrimary.withOpacity(0.1) : _kSurface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: active ? _kPrimary : _kBorder, width: active ? 1.5 : 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: active ? _kPrimary : _kTextMuted),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? _kPrimary : _kTextSub)),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: active ? _kPrimary : _kTextMuted),
        ]),
      ),
    );
  }

  void _applyFilter() {
    if (schoolController.selectedSchool.value == null) {
      Get.snackbar('Error', 'No school selected');
      return;
    }
    if (selectedClass == null) {
      Get.snackbar('Select Class', 'Please select a class first');
      return;
    }
    homeworkController.getAllHomework(
      schoolId: schoolController.selectedSchool.value!.id,
      classId: selectedClass!.id,
      sectionId: selectedSection?.id,
      academicYear: academicYearCtrl.text.trim(),
    );
  }

  // ── Bottom sheet: class ───────────────────────────────────────────────────
  void _showClassSheet() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(color: _kSurface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
              decoration: BoxDecoration(color: _kBorder, borderRadius: BorderRadius.circular(100))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(children: [
              const Text('Select Class', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _kText)),
              const Spacer(),
              GestureDetector(onTap: () => Get.back(), child: const Icon(Icons.close_rounded, color: _kTextMuted, size: 22)),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFEAF0FB)),
          // All classes option
          ListTile(
            leading: Container(width: 36, height: 36,
                decoration: BoxDecoration(color: selectedClass == null ? _kPrimary.withOpacity(0.1) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.all_inclusive_rounded, size: 18, color: selectedClass == null ? _kPrimary : _kTextMuted)),
            title: const Text('All Classes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _kText)),
            trailing: selectedClass == null ? const Icon(Icons.check_circle_rounded, color: _kPrimary, size: 20) : null,
            onTap: () { setState(() { selectedClass = null; selectedSection = null; }); Get.back(); },
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 340),
            child: Obx(() {
              final sorted = List<SchoolClass>.from(schoolController.classes)
                ..sort((a, b) => _compareClassNames(a.name, b.name));
              return ListView.builder(
                shrinkWrap: true,
                itemCount: sorted.length,
                itemBuilder: (_, i) {
                  final c = sorted[i];
                  final isSelected = selectedClass?.id == c.id;
                  return ListTile(
                    leading: Container(width: 36, height: 36,
                        decoration: BoxDecoration(color: isSelected ? _kPrimary.withOpacity(0.1) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.class_rounded, size: 18, color: isSelected ? _kPrimary : _kTextMuted)),
                    title: Text(c.name, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, fontSize: 14, color: isSelected ? _kPrimary : _kText)),
                    trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: _kPrimary, size: 20) : null,
                    onTap: () {
                      setState(() { selectedClass = c; selectedSection = null; });
                      if (schoolController.selectedSchool.value != null) {
                        schoolController.getAllSections(classId: c.id, schoolId: schoolController.selectedSchool.value!.id);
                      }
                      Get.back();
                      _applyFilter();
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

  // ── Bottom sheet: section ─────────────────────────────────────────────────
  void _showSectionSheet() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(color: _kSurface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
              decoration: BoxDecoration(color: _kBorder, borderRadius: BorderRadius.circular(100))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(children: [
              const Text('Select Section', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _kText)),
              const Spacer(),
              GestureDetector(onTap: () => Get.back(), child: const Icon(Icons.close_rounded, color: _kTextMuted, size: 22)),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFEAF0FB)),
          ListTile(
            leading: Container(width: 36, height: 36,
                decoration: BoxDecoration(color: selectedSection == null ? _kPrimary.withOpacity(0.1) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.all_inclusive_rounded, size: 18, color: selectedSection == null ? _kPrimary : _kTextMuted)),
            title: const Text('All Sections', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _kText)),
            trailing: selectedSection == null ? const Icon(Icons.check_circle_rounded, color: _kPrimary, size: 20) : null,
            onTap: () { setState(() => selectedSection = null); Get.back(); },
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: Obx(() {
              if (schoolController.sections.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(selectedClass == null ? 'Select a class first' : 'No sections found',
                      style: const TextStyle(color: _kTextMuted, fontSize: 13)),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: schoolController.sections.length,
                itemBuilder: (_, i) {
                  final s = schoolController.sections[i];
                  final isSelected = selectedSection?.id == s.id;
                  return ListTile(
                    leading: Container(width: 36, height: 36,
                        decoration: BoxDecoration(color: isSelected ? _kPrimary.withOpacity(0.1) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.group_rounded, size: 18, color: isSelected ? _kPrimary : _kTextMuted)),
                    title: Text(s.name, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, fontSize: 14, color: isSelected ? _kPrimary : _kText)),
                    trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: _kPrimary, size: 20) : null,
                    onTap: () { setState(() => selectedSection = s); Get.back();_applyFilter();  },
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

  // ── Bottom sheet: academic year ───────────────────────────────────────────
  void _showAcademicYearSheet() {
    final now   = DateTime.now();
    final years = List.generate(5, (i) {
      final y = now.year - 2 + i;
      return '$y-${y + 1}';
    });
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(color: _kSurface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
              decoration: BoxDecoration(color: _kBorder, borderRadius: BorderRadius.circular(100))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(children: [
              const Text('Academic Year', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _kText)),
              const Spacer(),
              GestureDetector(onTap: () => Get.back(), child: const Icon(Icons.close_rounded, color: _kTextMuted, size: 22)),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFEAF0FB)),
          ...years.map((y) => ListTile(
            leading: Container(width: 36, height: 36,
                decoration: BoxDecoration(color: academicYearCtrl.text == y ? _kPrimary.withOpacity(0.1) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.school_outlined, size: 18, color: academicYearCtrl.text == y ? _kPrimary : _kTextMuted)),
            title: Text(y, style: TextStyle(fontWeight: academicYearCtrl.text == y ? FontWeight.w700 : FontWeight.w500, fontSize: 14, color: academicYearCtrl.text == y ? _kPrimary : _kText)),
            trailing: academicYearCtrl.text == y ? const Icon(Icons.check_circle_rounded, color: _kPrimary, size: 20) : null,
            onTap: () { setState(() => academicYearCtrl.text = y); Get.back(); _applyFilter(); },
          )),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  // ── Create tab ────────────────────────────────────────────────────────────
  Widget _createTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildFilterBar(),
        const SizedBox(height: 20),
        _buildHomeworkForm(),
      ]),
    );
  }

  // ── View tab ──────────────────────────────────────────────────────────────
  Widget _viewTab() {
    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: () async {
        if (schoolController.selectedSchool.value != null && selectedClass != null) {
          await homeworkController.getAllHomework(
            schoolId: schoolController.selectedSchool.value!.id,
            classId: selectedClass!.id,
            sectionId: selectedSection?.id,
            academicYear: academicYearCtrl.text.trim(),
          );
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildFilterBar(),
          const SizedBox(height: 20),
          _buildHomeworkList(),
        ]),
      ),
    );
  }

  // ── Homework form ─────────────────────────────────────────────────────────
  Widget _buildHomeworkForm() {
    if (selectedClass == null) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: _kSurface, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kBorder),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))]),
        child: Column(children: [
          Container(padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _kPrimary.withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(Icons.touch_app_rounded, size: 36, color: _kPrimary)),
          const SizedBox(height: 16),
          const Text('Select a class', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _kText)),
          const SizedBox(height: 6),
          const Text('Choose a class from the filters above to create homework', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: _kTextMuted)),
        ]),
      );
    }

    return Container(
      decoration: BoxDecoration(color: _kSurface, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(children: [
        // Card header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(color: _kPrimary.withOpacity(0.05), borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: _kBorder))),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(9)),
                child: const Icon(Icons.assignment_add, color: Colors.white, size: 16)),
            const SizedBox(width: 10),
            const Expanded(child: Text('New Assignment', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kText))),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(20)),
                child: Text(selectedClass!.name, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _buildField(subjectCtrl, 'Subject Name', Icons.menu_book_rounded, hint: 'e.g. Mathematics'),
            const SizedBox(height: 12),
            _buildField(descriptionCtrl, 'Description', Icons.description_rounded, hint: 'Describe the assignment...', maxLines: 4),
            const SizedBox(height: 12),
            _buildFileAttachments(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton.icon(
                onPressed: _createHomework,
                icon: const Icon(Icons.add_task_rounded, size: 18),
                label: const Text('Create Homework', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {String? hint, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13, color: _kText),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: _kPrimary, size: 18),
        labelStyle: const TextStyle(color: _kTextSub, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
      ),
    );
  }

  Widget _buildFileAttachments() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: selectedFiles.isEmpty ? _kBorder : _kPrimary.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFFF8FAFC),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(children: [
            const Icon(Icons.attach_file_rounded, color: _kPrimary, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Attachments', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: _kText)),
              Text(selectedFiles.isEmpty ? 'No files selected' : '${selectedFiles.length} file(s)',
                  style: const TextStyle(fontSize: 10, color: _kTextMuted)),
            ])),
            TextButton.icon(
              onPressed: _pickFiles,
              icon: const Icon(Icons.add_rounded, size: 14),
              label: const Text('Add'),
              style: TextButton.styleFrom(foregroundColor: _kPrimary, backgroundColor: _kPrimaryBg,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            ),
          ]),
        ),
        if (selectedFiles.isNotEmpty) ...[
          Divider(height: 1, color: _kBorder),
          Padding(
            padding: const EdgeInsets.all(10),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1),
              itemCount: selectedFiles.length,
              itemBuilder: (context, i) => _filePreview(file: selectedFiles[i], onRemove: () => setState(() => selectedFiles.removeAt(i)), context: context),
            ),
          ),
        ],
      ]),
    );
  }

  // ── Homework list ─────────────────────────────────────────────────────────
  // FIX: each item in homeworkList is ONE homework entry (a day),
  //      which contains multiple subjects. Show ONE card per homework entry,
  //      not one card per subject.
  Widget _buildHomeworkList() {
    return Obx(() {
      final loading = homeworkController.isLoading.value;
      final items   = homeworkController.homeworkList;

      return Container(
        decoration: BoxDecoration(color: _kSurface, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kBorder),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))]),
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(color: _kPrimary.withOpacity(0.05), borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: _kBorder))),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(9)),
                  child: const Icon(Icons.list_alt_rounded, color: Colors.white, size: 16)),
              const SizedBox(width: 10),
              const Expanded(child: Text('Assignments', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kText))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  // FIX: count is number of homework entries, not subjects
                  '${items.length} item${items.length != 1 ? 's' : ''}',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ]),
          ),

          // Body
          if (loading)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2)))
          else if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(children: [
                Container(padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: _kPrimary.withOpacity(0.08), shape: BoxShape.circle),
                    child: const Icon(Icons.assignment_outlined, size: 36, color: _kPrimary)),
                const SizedBox(height: 16),
                Text(selectedClass == null ? 'Select a class' : 'No assignments found',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _kText)),
                const SizedBox(height: 6),
                Text(selectedClass == null ? 'Use the filters above to load homework' : 'No homework assigned for this class yet',
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: _kTextMuted)),
              ]),
            )
          else
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: List.generate(items.length, (index) {
                  final item     = items[index];
                  final subjects = (item['subjects'] as List?) ?? [];
                  final dateStr  = _fmtDateStr(item['homeworkDate']);

                  // ONE card per homework entry (day), showing all subjects inside
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: _kSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _kBorder),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Date header row
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 3, 8),
                        child: Row(children: [
                          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: _kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.calendar_today_rounded, color: _kPrimary, size: 13)),
                          const SizedBox(width: 8),
                          Text(dateStr, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _kText)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: _kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                            child: Text('${subjects.length} subject${subjects.length != 1 ? 's' : ''}',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kPrimary)),
                          ),
                          const SizedBox(width: 6),
                          // View all button
                          GestureDetector(
                            onTap: () => Get.to(() => HomeworkDetailView(homework: item)),
                            child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: _kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.visibility_rounded, color: _kPrimary, size: 14)),
                          ),
                          if (ApiPermissions.hasApiAccess(currentRole, 'DELETE /api/homework/deleteentireday')) ...[
                            const SizedBox(width: 4),
                            PopupMenuButton<String>(
                              iconSize: 18,
                              icon: const Icon(Icons.more_vert_rounded, color: _kTextMuted, size: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_rounded, size: 16, color: _kDanger), SizedBox(width: 8), Text('Delete', style: TextStyle(color: _kDanger))])),
                              ],
                              onSelected: (v) { if (v == 'delete') _showDeleteConfirmation(item); },
                            ),
                          ],
                        ]),
                      ),
                      // Subjects list inside this homework entry
                      ...subjects.asMap().entries.map((e) {
                        final idx     = e.key;
                        final subject = e.value as Map<String, dynamic>;
                        final teacherName = (subject['teacherId'] is Map) ? (subject['teacherId']['userName'] ?? 'N/A') : 'N/A';
                        final hasAttachments = (subject['attachments'] as List?)?.isNotEmpty ?? false;
                        final isLast  = idx == subjects.length - 1;

                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              top: const BorderSide(color: Color(0xFFEAF0FB)),
                              bottom: isLast ? BorderSide.none : BorderSide.none,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Container(width: 32, height: 32, decoration: BoxDecoration(color: _kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.menu_book_rounded, color: _kPrimary, size: 15)),
                              const SizedBox(width: 10),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(subject['subjectName'] ?? 'Subject',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _kText)),
                                const SizedBox(height: 3),
                                Row(children: [
                                  const Icon(Icons.person_rounded, size: 11, color: _kTextMuted),
                                  const SizedBox(width: 3),
                                  Text(teacherName, style: const TextStyle(fontSize: 11, color: _kTextSub)),
                                ]),
                                if ((subject['description'] ?? '').toString().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(subject['description'], maxLines: 2, overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11, color: _kTextSub, height: 1.4)),
                                ],
                                if (hasAttachments) ...[
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    const Icon(Icons.attach_file_rounded, size: 11, color: _kPrimary),
                                    const SizedBox(width: 3),
                                    Text('${(subject['attachments'] as List).length} attachment(s)',
                                        style: const TextStyle(fontSize: 10, color: _kPrimary, fontWeight: FontWeight.w600)),
                                  ]),
                                ],
                              ])),
                              // Per-subject actions
                              Column(children: [
                                GestureDetector(
                                  onTap: () => Get.to(() => HomeworkDetailView(homework: {'homeworkDate': item['homeworkDate'], 'subjects': [subject]})),
                                  child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: _kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                      child: const Icon(Icons.visibility_rounded, color: _kPrimary, size: 13)),
                                ),
                                if (ApiPermissions.hasApiAccess(currentRole, 'PUT /api/homework/updatetext')) ...[
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: () => _showEditHomeworkDialog(subject, item),
                                    child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                        child: const Icon(Icons.edit_rounded, color: Colors.orange, size: 13)),
                                  ),
                                ],
                              ]),
                            ]),
                          ),
                        );
                      }).toList(),
                    ]),
                  );
                }),
              ),
            ),
        ]),
      );
    });
  }

  // ── No access ─────────────────────────────────────────────────────────────
  Widget _noAccessView() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: _kPrimary.withOpacity(0.08), shape: BoxShape.circle),
            child: const Icon(Icons.lock_outline_rounded, size: 48, color: _kTextMuted)),
        const SizedBox(height: 20),
        const Text('No Access', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kTextSub)),
        const SizedBox(height: 8),
        const Text('You don\'t have permission to access homework', style: TextStyle(fontSize: 13, color: _kTextMuted), textAlign: TextAlign.center),
      ]),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.any, withData: true);
    if (result != null) setState(() => selectedFiles.addAll(result.files));
  }

  void _createHomework() async {
    if (schoolController.selectedSchool.value == null || selectedClass == null ||
        subjectCtrl.text.isEmpty || descriptionCtrl.text.isEmpty) {
      Get.snackbar('Missing Fields', 'Please fill all required fields',
          backgroundColor: _kDanger, colorText: Colors.white, borderRadius: 12, margin: const EdgeInsets.all(16));
      return;
    }
    final success = await homeworkController.createHomework(
      schoolId: schoolController.selectedSchool.value!.id,
      academicYear: academicYearCtrl.text,
      classId: selectedClass!.id,
      sectionId: selectedSection?.id,
      homeworkDate: selectedDate.toIso8601String().split('T')[0],
      subjectName: subjectCtrl.text,
      description: descriptionCtrl.text,
      files: selectedFiles.isNotEmpty ? selectedFiles : null,
    );
    if (success) { subjectCtrl.clear(); descriptionCtrl.clear(); setState(() => selectedFiles.clear()); }
  }

  void _showEditHomeworkDialog(Map<String, dynamic> subject, Map<String, dynamic> parentHomework) {
    final editFiles = <PlatformFile>[].obs;
    Get.dialog(StatefulBuilder(
      builder: (ctx, sst) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Homework', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _kText)),
        content: SizedBox(
          width: 400,
          child: Obx(() => Column(mainAxisSize: MainAxisSize.min, children: [
            Text('${editFiles.length} file(s) selected', style: const TextStyle(color: _kTextMuted, fontSize: 12)),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(allowMultiple: true);
                if (result != null) editFiles.addAll(result.files);
              },
              icon: const Icon(Icons.attach_file_rounded, size: 16),
              label: const Text('Add Files'),
              style: OutlinedButton.styleFrom(foregroundColor: _kPrimary, side: const BorderSide(color: _kPrimary)),
            )),
          ])),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Get.back();
              if (editFiles.isEmpty) return;
              Get.dialog(const AlertDialog(content: Row(children: [CircularProgressIndicator(color: _kPrimary), SizedBox(width: 16), Text('Uploading...')])), barrierDismissible: false);
              try {
                final success = await homeworkController.addAttachments(homeworkId: parentHomework['_id'], subjectId: subject['_id'], files: editFiles);
                if (Get.isDialogOpen == true) Get.back();
                if (success && schoolController.selectedSchool.value != null && selectedClass != null) {
                  await homeworkController.getAllHomework(schoolId: schoolController.selectedSchool.value!.id, classId: selectedClass!.id, sectionId: selectedSection?.id);
                  final String schoolId =schoolController.selectedSchool.value!.id;
                  final String classId =selectedClass!.id;
                  final String? sectionId =selectedSection?.id;

                  print('schoolid:$schoolId');
                  print('schoolid:$classId');
                  print('schoolid:$sectionId');
                }
              } catch (_) { if (Get.isDialogOpen == true) Get.back(); }
            },
            child: const Text('Upload'),
          ),
        ],
      ),
    ));
  }

  void _showDeleteConfirmation(Map<String, dynamic> homework) {
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(children: [Icon(Icons.warning_rounded, color: _kDanger, size: 20), SizedBox(width: 8), Text('Delete Homework', style: TextStyle(fontWeight: FontWeight.w700, color: _kText))]),
      content: const Text('Delete this entire day\'s homework? This cannot be undone.', style: TextStyle(color: _kTextSub)),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            Get.back();
            final id = homework['_id'];
            if (id != null) {
              final success = await homeworkController.deleteEntireDay(id);
              if (success && schoolController.selectedSchool.value != null && selectedClass != null) {
                await homeworkController.getAllHomework(schoolId: schoolController.selectedSchool.value!.id, classId: selectedClass!.id, sectionId: selectedSection?.id);
              }
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: _kDanger, foregroundColor: Colors.white),
          child: const Text('Delete'),
        ),
      ],
    ));
  }

  // ── Class sort helper ─────────────────────────────────────────────────────
  int _compareClassNames(String a, String b) {
    int priority(String name) {
      final n = name.toLowerCase().trim();
      if (n == 'lkg') return 1;
      if (n == 'ukg') return 2;
      final gradeMatch = RegExp(r'grade\s+(\d+)', caseSensitive: false).firstMatch(n);
      if (gradeMatch != null) return 2 + (int.tryParse(gradeMatch.group(1)!) ?? 99);
      final classMatch = RegExp(r'class\s+(\d+)', caseSensitive: false).firstMatch(n);
      if (classMatch != null) return 20 + (int.tryParse(classMatch.group(1)!) ?? 99);
      return 999;
    }
    return priority(a).compareTo(priority(b));
  }
}