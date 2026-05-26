import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/controllers/homework_controller.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/core/rbac/api_rbac.dart';
import 'package:school_app/models/school_models.dart';
import 'package:school_app/screens/homework_detail_view.dart';

class HomeworkManagementView extends StatefulWidget {
  @override
  State<HomeworkManagementView> createState() => _HomeworkManagementViewState();
}

class _HomeworkManagementViewState extends State<HomeworkManagementView>
    with TickerProviderStateMixin {
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

  // Orange-based palette matching existing theme
  static const Color _primary = Color(0xFF2563EB);
  static const Color _primaryDark = Color(0xFF3949AB);
  static const Color _primaryLight = Color(0xFFEBF0FB);
  static const Color _blue = Color(0xFF3B6FD4);
  static const Color _blueLight = Color(0xFFEBF0FB);
  static const Color _surface = Color(0xFFFAFAFA);
  static const Color _cardBg = Colors.white;

  @override
  void initState() {
    super.initState();
    final initialCount = _getAvailableTabsCount();
    _tabController = TabController(length: initialCount, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // School is already selected from sidebar; just load classes for that school
      if (schoolController.selectedSchool.value != null) {
        schoolController.getAllClasses(schoolController.selectedSchool.value!.id);
      } else {
        schoolController.getAllSchools().then((_) {
          if (ApiPermissions.isSchoolReadOnly(currentUserRole)) {
            final userSchoolId = authController.user.value?.schoolId;
            if (userSchoolId != null) {
              final userSchool = schoolController.schools.firstWhereOrNull(
                    (s) => s.id == userSchoolId,
              );
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

  String get currentUserRole =>
      authController.user.value?.role?.toLowerCase() ?? '';

  int _getAvailableTabsCount() {
    int count = 0;
    if (ApiPermissions.hasApiAccess(
        currentUserRole, 'POST /api/homework/create')) count++;
    if (ApiPermissions.hasApiAccess(
        currentUserRole, 'GET /api/homework/getall')) count++;
    return count > 0 ? count : 1;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }


  // Compact format for tight spaces: "25 May '26"
  String _formatDateShort(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
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
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      backgroundColor: _surface,
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

  Widget _buildHeader(bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary, _primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.assignment_rounded,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Homework',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 22 : 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Create & manage assignments',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Show selected school name as a chip
                Obx(() {
                  final school = schoolController.selectedSchool.value;
                  if (school == null) return const SizedBox.shrink();
                  return Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.school_rounded,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 5),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 100),
                          child: Text(
                            school.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: _primary,
                unselectedLabelColor: Colors.white.withOpacity(0.8),
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 13),
                tabs: _buildTabs(),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  List<Widget> _buildTabs() {
    List<Widget> tabs = [];
    if (ApiPermissions.hasApiAccess(
        currentUserRole, 'POST /api/homework/create')) {
      tabs.add(const Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_task_rounded, size: 16),
            SizedBox(width: 6),
            Text('Create'),
          ],
        ),
      ));
    }
    if (ApiPermissions.hasApiAccess(
        currentUserRole, 'GET /api/homework/getall')) {
      tabs.add(const Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.list_alt_rounded, size: 16),
            SizedBox(width: 6),
            Text('View All'),
          ],
        ),
      ));
    }
    return tabs.isNotEmpty ? tabs : [const Tab(text: 'No Access')];
  }

  List<Widget> _buildTabViews(bool isTablet) {
    List<Widget> views = [];
    if (ApiPermissions.hasApiAccess(
        currentUserRole, 'POST /api/homework/create')) {
      views.add(_buildCreateTab(isTablet));
    }
    if (ApiPermissions.hasApiAccess(
        currentUserRole, 'GET /api/homework/getall')) {
      views.add(_buildViewAllTab(isTablet));
    }
    return views.isNotEmpty ? views : [_buildNoAccessView()];
  }

  Widget _buildCreateTab(bool isTablet) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: Column(
        children: [
          _buildFiltersCard(isTablet),
          const SizedBox(height: 16),
          _buildHomeworkForm(isTablet),
        ],
      ),
    );
  }

  Widget _buildViewAllTab(bool isTablet) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: Column(
        children: [
          _buildFiltersCard(isTablet),
          const SizedBox(height: 16),
          _buildHomeworkList(isTablet),
        ],
      ),
    );
  }

  Widget _buildNoAccessView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock_outline_rounded,
                size: 56, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          Text('No Access',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          Text(
            'You don\'t have permission\nto access homework management',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── Filters Card (no school selector) ──────────────────────────────────────

  Widget _buildFiltersCard(bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4)),
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
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _blueLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune_rounded, color: _primary, size: 16),
                      const SizedBox(width: 6),
                      Text('Filters',
                          style: TextStyle(
                              color: _primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildClassSelector(),
            if (ApiPermissions.hasSectionAccess(currentUserRole)) ...[
              const SizedBox(height: 12),
              _buildSectionSelector(),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildDateSelector()),
                const SizedBox(width: 12),
                Expanded(child: _buildAcademicYearField()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassSelector() {
    return Obx(() {
      final sortedClasses = List<SchoolClass>.from(schoolController.classes);
      sortedClasses.sort((a, b) => _compareClassNames(a.name, b.name));

      return DropdownButtonFormField<SchoolClass>(
        isExpanded: true,
        decoration: InputDecoration(
          hintText: sortedClasses.isEmpty &&
              schoolController.selectedSchool.value != null
              ? 'Loading classes...'
              : 'Select Class',
          prefixIcon:
          Icon(Icons.class_rounded, color: _primary, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _primary, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        value: selectedClass,
        items: sortedClasses.map((cls) {
          return DropdownMenuItem<SchoolClass>(
            value: cls,
            child: Row(
              children: [
                Icon(_getClassIcon(cls.name), size: 18, color: _primary),
                const SizedBox(width: 8),
                Text(cls.name,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
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
          if (cls != null &&
              schoolController.selectedSchool.value != null) {
            schoolController.getAllSections(
              classId: cls.id,
              schoolId: schoolController.selectedSchool.value!.id,
            );
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

  Widget _buildSectionSelector() {
    final userRole = authController.user.value?.role?.toLowerCase() ?? '';
    if (!ApiPermissions.hasSectionAccess(userRole)) return const SizedBox.shrink();

    return Obx(() => DropdownButtonFormField<Section>(
      isExpanded: true,
      decoration: InputDecoration(
        hintText: 'All Sections',
        prefixIcon: Icon(Icons.group_rounded, color: _primary, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primary, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      value: selectedSection,
      items: [
        const DropdownMenuItem<Section>(
            value: null, child: Text('All Sections')),
        ...schoolController.sections.map((section) => DropdownMenuItem<Section>(
          value: section,
          child: Text(section.name),
        )),
      ],
      onChanged: (section) {
        setState(() => selectedSection = section);
        if (selectedClass != null &&
            schoolController.selectedSchool.value != null) {
          homeworkController.getAllHomework(
            schoolId: schoolController.selectedSchool.value!.id,
            classId: selectedClass!.id,
            sectionId: section?.id,
          );
        }
      },
    ));
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(primary: _primary),
            ),
            child: child!,
          ),
        );
        if (date != null) setState(() => selectedDate = date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, color: _primary, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Due Date',
                      style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(
                    _formatDateShort(selectedDate),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcademicYearField() {
    return TextFormField(
      controller: academicYearController,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: 'Academic Year',
        labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        prefixIcon:
        Icon(Icons.school_outlined, color: _primary, size: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primary, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  // ─── Create Homework Form ────────────────────────────────────────────────────

  Widget _buildHomeworkForm(bool isTablet) {
    if (schoolController.selectedSchool.value == null || selectedClass == null) {
      return _buildEmptyState(
        icon: Icons.touch_app_rounded,
        message: 'Select a class to create homework',
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Card header
          Container(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            decoration: BoxDecoration(
              color: _primaryLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.assignment_add, color: _primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'New Assignment',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w700,
                    color: _primaryDark,
                  ),
                ),
                const Spacer(),
                // Class badge
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    selectedClass!.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            child: Column(
              children: [
                _buildInputField(
                  controller: subjectController,
                  label: 'Subject Name',
                  hint: 'e.g. Mathematics',
                  icon: Icons.menu_book_rounded,
                ),
                const SizedBox(height: 14),
                _buildInputField(
                  controller: descriptionController,
                  label: 'Description',
                  hint: 'Describe the homework assignment...',
                  icon: Icons.notes_rounded,
                  maxLines: 4,
                ),
                const SizedBox(height: 14),
                _buildFileAttachments(isTablet),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _createHomework,
                    icon: const Icon(Icons.add_task_rounded, size: 20),
                    label: const Text('Create Homework',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(icon, color: _primary, size: 20),
        alignLabelWithHint: maxLines > 1,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primary, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildFileAttachments(bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
            color: selectedFiles.isEmpty
                ? Colors.grey.shade200
                : _primary.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.attach_file_rounded, color: _primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Attachments',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(
                        selectedFiles.isEmpty
                            ? 'No files selected'
                            : '${selectedFiles.length} file${selectedFiles.length > 1 ? 's' : ''} selected',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickFiles,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add'),
                  style: TextButton.styleFrom(
                    foregroundColor: _primary,
                    backgroundColor: _primaryLight,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          if (selectedFiles.isNotEmpty) ...[
            Divider(height: 1, color: Colors.grey.shade200),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isTablet ? 4 : 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: selectedFiles.length,
              itemBuilder: (context, index) {
                final file = selectedFiles[index];
                final isImage = ['jpg', 'jpeg', 'png', 'gif']
                    .contains(file.extension?.toLowerCase());
                return GestureDetector(
                  onTap: isImage && file.bytes != null
                      ? () => _showImagePreview(file.bytes!)
                      : null,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 4)
                          ],
                        ),
                        child: isImage && file.bytes != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(file.bytes!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity),
                        )
                            : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_getFileIcon(file.extension ?? ''),
                                  color: _primary, size: 28),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4),
                                child: Text(file.name,
                                    style:
                                    const TextStyle(fontSize: 9),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 3,
                        right: 3,
                        child: GestureDetector(
                          onTap: () => setState(
                                  () => selectedFiles.removeAt(index)),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                                color: Colors.red, shape: BoxShape.circle),
                            child: const Icon(Icons.close_rounded,
                                color: Colors.white, size: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // ─── Homework List ───────────────────────────────────────────────────────────

  Widget _buildHomeworkList(bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            decoration: BoxDecoration(
              color: _blueLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _blue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.list_alt_rounded, color: _blue, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Assignments',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w700,
                    color: _blue,
                  ),
                ),
                const Spacer(),
                Obx(() {
                  final count = homeworkController.homeworkList.length;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$count item${count != 1 ? 's' : ''}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  );
                }),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            child: _buildHomeworkItems(isTablet),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeworkItems(bool isTablet) {
    return Obx(() {
      if (homeworkController.isLoading.value) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              CircularProgressIndicator(color: _primary, strokeWidth: 3),
              const SizedBox(height: 16),
              Text('Loading assignments...',
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 13)),
            ],
          ),
        );
      }

      final homeworkItems = homeworkController.homeworkList;

      if (homeworkItems.isEmpty) {
        return _buildEmptyState(
          icon: Icons.assignment_outlined,
          message: selectedClass == null
              ? 'Select a class to view homework'
              : 'No assignments found for this class',
        );
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: homeworkItems.length,
        itemBuilder: (context, index) {
          final item = homeworkItems[index];
          final subjects = (item['subjects'] as List?) ?? [];

          return Column(
            children: subjects.map<Widget>((subject) {
              final dateStr = _formatDateString(item['homeworkDate']);
              final teacherName = (subject['teacherId'] is Map)
                  ? (subject['teacherId']['userName'] ?? 'N/A')
                  : 'N/A';

              return GestureDetector(
                onTap: () => Get.to(() => HomeworkDetailView(homework: item)),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade100),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Row header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _blueLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.assignment_rounded,
                                  color: _blue, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    subject['subjectName'] ?? 'Subject',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14),
                                  ),
                                  const SizedBox(height: 3),
                                  // Date row
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today_rounded,
                                          size: 11,
                                          color: Colors.grey.shade400),
                                      const SizedBox(width: 4),
                                      Text(dateStr,
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade500)),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  // Teacher row
                                  Row(
                                    children: [
                                      Icon(Icons.person_rounded,
                                          size: 11,
                                          color: Colors.grey.shade400),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(teacherName,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade500)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Actions
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildIconBtn(
                                  icon: Icons.visibility_rounded,
                                  color: _blue,
                                  onTap: () => Get.to(() =>
                                      HomeworkDetailView(homework: {
                                        'homeworkDate': item['homeworkDate'],
                                        'subjects': [subject],
                                      })),
                                ),
                                if (ApiPermissions.hasApiAccess(
                                    currentUserRole,
                                    'PUT /api/homework/updatetext') ||
                                    ApiPermissions.hasApiAccess(
                                        currentUserRole,
                                        'DELETE /api/homework/deleteentireday'))
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.more_vert_rounded,
                                        color: Colors.grey.shade400, size: 20),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(12)),
                                    itemBuilder: (context) => [
                                      if (ApiPermissions.hasApiAccess(
                                          currentUserRole,
                                          'PUT /api/homework/updatetext'))
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Row(children: [
                                            Icon(Icons.edit_rounded,
                                                size: 16,
                                                color: Colors.grey.shade700),
                                            const SizedBox(width: 8),
                                            const Text('Edit'),
                                          ]),
                                        ),
                                      if (ApiPermissions.hasApiAccess(
                                          currentUserRole,
                                          'DELETE /api/homework/deleteentireday'))
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(children: [
                                            Icon(Icons.delete_rounded,
                                                size: 16, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Delete',
                                                style: TextStyle(
                                                    color: Colors.red)),
                                          ]),
                                        ),
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
                          child: Text(
                            subject['description'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                height: 1.4),
                          ),
                        ),
                      // Attachment count
                      if ((subject['attachments'] as List?)?.isNotEmpty ??
                          false)
                        Container(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                          child: Row(
                            children: [
                              Icon(Icons.attach_file_rounded,
                                  size: 12, color: _primary),
                              const SizedBox(width: 4),
                              Text(
                                '${(subject['attachments'] as List).length} attachment${(subject['attachments'] as List).length > 1 ? 's' : ''}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: _primary,
                                    fontWeight: FontWeight.w600),
                              ),
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

  Widget _buildIconBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  Widget _buildEmptyState(
      {required IconData icon, required String message}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text(message,
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ─── Dialogs (unchanged logic, improved styling) ─────────────────────────────

  void _showImagePreview(Uint8List bytes) {
    Get.dialog(Dialog(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Center(
              child: InteractiveViewer(
                  child: Image.memory(bytes, fit: BoxFit.contain))),
          Positioned(
            top: 40,
            right: 20,
            child: GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration:
                const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child:
                const Icon(Icons.close_rounded, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    ));
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf': return Icons.picture_as_pdf_rounded;
      case 'doc': case 'docx': return Icons.description_rounded;
      case 'jpg': case 'jpeg': case 'png': return Icons.image_rounded;
      case 'mp4': case 'avi': return Icons.video_file_rounded;
      default: return Icons.insert_drive_file_rounded;
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
        allowMultiple: true, type: FileType.any, withData: true);
    if (result != null) setState(() => selectedFiles.addAll(result.files));
  }

  void _createHomework() async {
    if (schoolController.selectedSchool.value == null ||
        selectedClass == null ||
        subjectController.text.isEmpty ||
        descriptionController.text.isEmpty) {
      Get.snackbar('Missing Fields', 'Please fill all required fields',
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white,
          borderRadius: 12,
          margin: const EdgeInsets.all(16),
          icon: const Icon(Icons.warning_rounded, color: Colors.white));
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
    final editSubjectController =
    TextEditingController(text: subject['subjectName']);
    final editDescriptionController =
    TextEditingController(text: subject['description']);
    final editFiles = <PlatformFile>[].obs;

    Get.dialog(StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Homework',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: editSubjectController,
                decoration: InputDecoration(
                  labelText: 'Subject Name',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: editDescriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${editFiles.length} file(s) selected',
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 12)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                            allowMultiple: true);
                        if (result != null) editFiles.addAll(result.files);
                      },
                      icon: const Icon(Icons.attach_file_rounded, size: 16),
                      label: const Text('Add Files'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: _primary,
                          side: BorderSide(color: _primary)),
                    ),
                  ),
                ],
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Get.back();
              if (editFiles.isEmpty) return;
              Get.dialog(
                WillPopScope(
                  onWillPop: () async => false,
                  child: const AlertDialog(
                    content: Row(children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Uploading...'),
                    ]),
                  ),
                ),
                barrierDismissible: false,
              );
              try {
                final homework =
                homeworkController.homeworkList.firstWhereOrNull(
                      (h) => (h['subjects'] as List)
                      .any((s) => s['_id'] == subject['_id']),
                );
                if (homework == null) return;
                final success = await homeworkController.addAttachments(
                  homeworkId: homework['_id'],
                  subjectId: subject['_id'],
                  files: editFiles,
                );
                if (Get.isDialogOpen == true) Navigator.pop(Get.context!);
                if (success &&
                    schoolController.selectedSchool.value != null &&
                    selectedClass != null) {
                  await homeworkController.getAllHomework(
                    schoolId: schoolController.selectedSchool.value!.id,
                    classId: selectedClass!.id,
                    sectionId: selectedSection?.id,
                  );
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.warning_rounded, color: Colors.red, size: 20),
          SizedBox(width: 8),
          Text('Delete Homework',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
      content:
      const Text('Are you sure you want to delete this homework? This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            Get.back();
            Get.dialog(
              WillPopScope(
                onWillPop: () async => false,
                child: const AlertDialog(
                  content: Row(children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text('Deleting...'),
                  ]),
                ),
              ),
              barrierDismissible: false,
            );
            final homeworkId = homeworkController.homeworkList
                .firstWhereOrNull(
                  (h) => (h['subjects'] as List)
                  .any((s) => s['_id'] == homework['_id']),
            )?['_id'];
            if (homeworkId != null) {
              final success =
              await homeworkController.deleteEntireDay(homeworkId);
              Get.back();
              if (success &&
                  schoolController.selectedSchool.value != null &&
                  selectedClass != null) {
                await homeworkController.getAllHomework(
                  schoolId: schoolController.selectedSchool.value!.id,
                  classId: selectedClass!.id,
                  sectionId: selectedSection?.id,
                );
              }
            } else {
              Get.back();
              Get.snackbar('Error', 'Could not find homework to delete');
            }
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, foregroundColor: Colors.white),
          child: const Text('Delete'),
        ),
      ],
    ));
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  int _compareClassNames(String a, String b) {
    final aLower = a.toLowerCase().trim();
    final bLower = b.toLowerCase().trim();
    int _getClassPriority(String className) {
      if (className == 'lkg') return 1;
      if (className == 'ukg') return 2;
      if (className.startsWith('grade ')) {
        final match =
        RegExp(r'grade (\d+)', caseSensitive: false).firstMatch(className);
        if (match != null) {
          final num = int.tryParse(match.group(1)!);
          if (num != null) return 2 + num;
        }
      }
      if (className.startsWith('class ')) {
        final match =
        RegExp(r'class (\d+)', caseSensitive: false).firstMatch(className);
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
    if (lower.contains('grade 1') ||
        lower.contains('grade 2') ||
        lower.contains('grade 3')) return Icons.looks_one_rounded;
    if (lower.contains('grade 4') ||
        lower.contains('grade 5') ||
        lower.contains('grade 6')) return Icons.looks_two_rounded;
    if (lower.contains('grade 7') ||
        lower.contains('grade 8') ||
        lower.contains('grade 9')) return Icons.looks_3_rounded;
    return Icons.looks_4_rounded;
  }
}