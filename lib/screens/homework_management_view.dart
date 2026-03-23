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
  
  @override
  void initState() {
    super.initState();
    final initialCount = _getAvailableTabsCount();
    _tabController = TabController(length: initialCount, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLandscape = screenSize.width > screenSize.height;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.appBarGradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD8D5E8).withOpacity(0.6),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(isTablet ? 24 : 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.assignment,
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
                                'Homework Management',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isTablet ? 24 : 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Create and manage homework assignments',
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
                  // Tab Bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelColor: Colors.orange.shade600,
                      unselectedLabelColor: Colors.white.withOpacity(0.7),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      tabs: _buildTabs(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _buildTabViews(isTablet, isLandscape),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTabs() {
    List<Widget> tabs = [];
    
    if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/homework/create')) {
      tabs.add(const Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_task, size: 18),
            SizedBox(width: 8),
            Text('Create'),
          ],
        ),
      ));
    }
    
    if (ApiPermissions.hasApiAccess(currentUserRole, 'GET /api/homework/getall')) {
      tabs.add(const Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.list_alt, size: 18),
            SizedBox(width: 8),
            Text('View All'),
          ],
        ),
      ));
    }
    
    return tabs.isNotEmpty ? tabs : [const Tab(text: 'No Access')];
  }

  List<Widget> _buildTabViews(bool isTablet, bool isLandscape) {
    List<Widget> views = [];
    
    if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/homework/create')) {
      views.add(_buildCreateTab(isTablet, isLandscape));
    }
    
    if (ApiPermissions.hasApiAccess(currentUserRole, 'GET /api/homework/getall')) {
      views.add(_buildViewAllTab(isTablet, isLandscape));
    }
    
    return views.isNotEmpty ? views : [_buildNoAccessView()];
  }

  Widget _buildCreateTab(bool isTablet, bool isLandscape) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: Column(
        children: [
          _buildSelectors(isTablet, isLandscape),
          const SizedBox(height: 20),
          _buildHomeworkForm(isTablet, isLandscape),
        ],
      ),
    );
  }

  Widget _buildViewAllTab(bool isTablet, bool isLandscape) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: Column(
        children: [
          _buildSelectors(isTablet, isLandscape),
          const SizedBox(height: 20),
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
          Icon(
            Icons.lock_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'No Access',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You don\'t have permission to access homework management',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectors(bool isTablet, bool isLandscape) {
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
                Icon(Icons.filter_list, color: Colors.orange.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Select Class & Date',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isTablet ? 18 : 16,
                    color: Colors.orange.shade600,
                  ),
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
                      if (ApiPermissions.hasSectionAccess(currentUserRole)) ...[
                        const SizedBox(width: 16),
                        Expanded(child: _buildSectionSelector()),
                      ],
                    ],
                  )
                : Column(
                    children: [
                      _buildSchoolSelector(),
                      const SizedBox(height: 12),
                      _buildClassSelector(),
                      if (ApiPermissions.hasSectionAccess(currentUserRole)) ...[
                        const SizedBox(height: 12),
                        _buildSectionSelector(),
                      ],
                    ],
                  ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildDateSelector()),
                const SizedBox(width: 16),
                Expanded(child: _buildAcademicYearField()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolSelector() {
    return Obx(() {
      if (ApiPermissions.isSchoolReadOnly(currentUserRole)) {
        final schoolName = schoolController.selectedSchool.value?.name ?? 'Loading...';
        return TextFormField(
          initialValue: schoolName,
          decoration: InputDecoration(
            labelText: 'School',
            prefixIcon: Icon(Icons.school, color: Colors.orange.shade600),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[200],
          ),
          enabled: false,
          style: TextStyle(color: Colors.black87),
        );
      }
      
      return DropdownButtonFormField<School>(
        isExpanded: true,
        decoration: InputDecoration(
          hintText: 'Choose School',
          prefixIcon: Icon(Icons.school, color: Colors.orange.shade600),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        value: schoolController.selectedSchool.value,
        selectedItemBuilder: (context) => schoolController.schools.map((s) => Text(s.name)).toList(),
        items: schoolController.schools.map((school) {
          return DropdownMenuItem<School>(
            value: school,
            child: Row(
              children: [
                Icon(Icons.school, size: 18, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                Expanded(child: Text(school.name, overflow: TextOverflow.ellipsis)),
              ],
            ),
          );
        }).toList(),
        onChanged: (school) {
          schoolController.selectedSchool.value = school;
          selectedClass = null;
          selectedSection = null;
          if (school != null) {
            schoolController.getAllClasses(school.id);
          }
        },
      );
    });
  }

  Widget _buildClassSelector() {
    return Obx(() {
      final sortedClasses = List<SchoolClass>.from(schoolController.classes);
      sortedClasses.sort((a, b) => _compareClassNames(a.name, b.name));
      
      // If no classes loaded yet, show loading state
      if (sortedClasses.isEmpty && schoolController.selectedSchool.value != null) {
        return DropdownButtonFormField<SchoolClass>(
          isExpanded: true,
          decoration: InputDecoration(
            hintText: 'Loading classes...',
            prefixIcon: Icon(Icons.class_, color: Colors.orange.shade600),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          items: [],
          onChanged: null,
        );
      }
      
      return DropdownButtonFormField<SchoolClass>(
        isExpanded: true,
        decoration: InputDecoration(
          hintText: 'Choose Class',
          prefixIcon: Icon(Icons.class_, color: Colors.orange.shade600),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        value: selectedClass,
        items: sortedClasses.map((cls) {
          return DropdownMenuItem<SchoolClass>(
            value: cls,
            child: Row(
              children: [
                Icon(_getClassIcon(cls.name), size: 20, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                Text(cls.name),
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
            schoolController.getAllSections(
              classId: cls.id,
              schoolId: schoolController.selectedSchool.value!.id,
            );
            // Load homework when class is selected
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
    
    // Hide section dropdown for roles without section access
    if (!ApiPermissions.hasSectionAccess(userRole)) {
      return SizedBox.shrink();
    }
    
    return Obx(() => DropdownButtonFormField<Section>(
      isExpanded: true,
      decoration: InputDecoration(
        hintText: 'Choose Section (Optional)',
        prefixIcon: Icon(Icons.group, color: Colors.orange.shade600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      value: selectedSection,
      items: [
        const DropdownMenuItem<Section>(
          value: null,
          child: Text('All Sections'),
        ),
        ...schoolController.sections.map((section) {
          return DropdownMenuItem<Section>(
            value: section,
            child: Text(section.name),
          );
        }),
      ],
      onChanged: (section) {
        setState(() {
          selectedSection = section;
        });
        // Reload homework when section changes
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

  Widget _buildDateSelector() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          setState(() {
            selectedDate = date;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.orange.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Homework Date',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
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
      decoration: InputDecoration(
        labelText: 'Academic Year',
        prefixIcon: Icon(Icons.school_outlined, color: Colors.orange.shade600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildHomeworkForm(bool isTablet, bool isLandscape) {
    if (schoolController.selectedSchool.value == null || selectedClass == null) {
      return _buildEmptyState('Select school and class to create homework');
    }

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
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.assignment_add, color: Colors.orange.shade600),
                const SizedBox(width: 12),
                Text(
                  'Create Homework',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade600,
                  ),
                ),
              ],
            ),
          ),
          // Form Content
          Padding(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            child: Column(
              children: [
                // Subject Name
                TextFormField(
                  controller: subjectController,
                  decoration: InputDecoration(
                    labelText: 'Subject Name',
                    prefixIcon: Icon(Icons.subject, color: Colors.orange.shade600),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Description
                TextFormField(
                  controller: descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Homework Description',
                    prefixIcon: Icon(Icons.description, color: Colors.orange.shade600),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                
                // File Attachments
                _buildFileAttachments(isTablet),
                const SizedBox(height: 20),
                
                // Create Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _createHomework,
                    icon: const Icon(Icons.add_task),
                    label: const Text('Create Homework'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  Widget _buildFileAttachments(bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.attach_file, color: Colors.orange.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'File Attachments',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${selectedFiles.length} files selected',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  height: 36,
                  child: ElevatedButton(
                    onPressed: _pickFiles,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade100,
                      foregroundColor: Colors.orange.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.add, size: 16),
                        SizedBox(width: 4),
                        Text('Add'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (selectedFiles.isNotEmpty) ...[
            const Divider(height: 1),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isTablet ? 4 : 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: selectedFiles.length,
              itemBuilder: (context, index) {
                final file = selectedFiles[index];
                final isImage = ['jpg', 'jpeg', 'png', 'gif'].contains(file.extension?.toLowerCase());
                
                return GestureDetector(
                  onTap: isImage && file.bytes != null
                      ? () => _showImagePreview(file.bytes!)
                      : null,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: isImage && file.bytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  file.bytes!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _getFileIcon(file.extension ?? ''),
                                      color: Colors.orange.shade600,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 4),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Text(
                                        file.name,
                                        style: const TextStyle(fontSize: 10),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedFiles.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
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
              },
            ),
          ],
        ],
      ),
    );
  }

  void _showImagePreview(Uint8List bytes) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.memory(bytes, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40,
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

  Widget _buildHomeworkList(bool isTablet) {
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
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.list_alt, color: Colors.blue.shade600),
                const SizedBox(width: 12),
                Text(
                  'Homework List',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Page 1 of 10',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            child: _buildHomeworkItems(isTablet),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeworkItems(bool isTablet) {
    return Obx(() {
      if (homeworkController.isLoading.value) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Loading homework...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      final homeworkItems = homeworkController.homeworkList;
      
      if (homeworkItems.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No homework found',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
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
              return GestureDetector(
                onTap: () {
                  Get.to(() => HomeworkDetailView(homework: item));
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade50, Colors.indigo.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: ExpansionTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.assignment,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    title: Text(
                      subject['subjectName'] ?? 'Subject',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      'Date: ${item['homeworkDate'] ?? 'N/A'} • Teacher: ${(subject['teacherId'] is Map) ? (subject['teacherId']['userName'] ?? 'N/A') : 'N/A'}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.visibility, color: Colors.blue.shade600),
                          onPressed: () {
                            Get.to(() => HomeworkDetailView(homework: {
                              'homeworkDate': item['homeworkDate'],
                              'subjects': [subject],
                            }));
                          },
                          tooltip: 'View Details',
                        ),
                        if (ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/homework/updatetext') ||
                            ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/homework/deleteentireday'))
                          PopupMenuButton<String>(
                            itemBuilder: (context) => [
                              if (ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/homework/updatetext'))
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
                              if (ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/homework/deleteentireday'))
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
                                _showEditHomeworkDialog(subject);
                              } else if (value == 'delete') {
                                _showDeleteConfirmation(item);
                              }
                            },
                          ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Description:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subject['description'] ?? 'No description',
                              style: const TextStyle(fontSize: 14),
                            ),
                            if ((subject['attachments'] as List?)?.isNotEmpty ?? false) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Attachments:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio: 1,
                                ),
                                itemCount: (subject['attachments'] as List).length,
                                itemBuilder: (context, index) {
                                  final attachment = (subject['attachments'] as List)[index];
                                  final url = attachment['url'] ?? '';
                                  final isImage = url.toLowerCase().contains(RegExp(r'\.(jpg|jpeg|png|gif)'));
                                  
                                  return GestureDetector(
                                    onTap: () => _showAttachmentPreview(attachment, subject),
                                    child: Stack(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey.shade300),
                                          ),
                                          child: isImage
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.network(
                                                    url,
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Center(
                                                        child: Icon(Icons.broken_image, color: Colors.grey),
                                                      );
                                                    },
                                                  ),
                                                )
                                              : Center(
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(Icons.insert_drive_file, size: 32, color: Colors.orange.shade600),
                                                      const SizedBox(height: 4),
                                                      Padding(
                                                        padding: const EdgeInsets.all(4),
                                                        child: Text(
                                                          attachment['name'] ?? 'File',
                                                          style: const TextStyle(fontSize: 10),
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                          textAlign: TextAlign.center,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                        ),
                                        if (ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/homework/deleteattachment'))
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: GestureDetector(
                                              onTap: () => _showDeleteAttachmentConfirmation(subject, attachment),
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: 14,
                                                ),
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

  Widget _buildEmptyState(String message) {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'mp4':
      case 'avi':
        return Icons.video_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
      withData: true, // Ensure bytes are loaded
    );
    
    if (result != null) {
      setState(() {
        selectedFiles.addAll(result.files);
      });
    }
  }

  void _createHomework() async {
    if (schoolController.selectedSchool.value == null || 
        selectedClass == null ||
        subjectController.text.isEmpty ||
        descriptionController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill all required fields',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
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
      // Clear form
      subjectController.clear();
      descriptionController.clear();
      setState(() {
        selectedFiles.clear();
      });
    }
  }

  void _showEditHomeworkDialog(Map<String, dynamic> subject) {
    final editSubjectController = TextEditingController(text: subject['subjectName']);
    final editDescriptionController = TextEditingController(text: subject['description']);
    final editFiles = <PlatformFile>[].obs;
    
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Homework'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: editSubjectController,
                  decoration: InputDecoration(
                    labelText: 'Subject Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: editDescriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Attachments: ${editFiles.length} files'),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(allowMultiple: true);
                          if (result != null) {
                            setState(() {
                              editFiles.addAll(result.files);
                            });
                          }
                        },
                        icon: const Icon(Icons.attach_file, size: 16),
                        label: const Text('Add Files'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade100,
                          foregroundColor: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () async {
                Get.back();

                if (editFiles.isEmpty) return;

                Get.dialog(
                  WillPopScope(
                    onWillPop: () async => false,
                    child: const AlertDialog(
                      content: Row(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 16),
                          Text('Uploading attachments...'),
                        ],
                      ),
                    ),
                  ),
                  barrierDismissible: false,
                );

                try {
                  final homework = homeworkController.homeworkList.firstWhereOrNull(
                        (h) => (h['subjects'] as List).any(
                          (s) => s['_id'] == subject['_id'],
                    ),
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
                  debugPrint('Upload error: $e');
                }
              },
              child: const Text('Update'),
            )
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> homework) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Homework'),
        content: Text('Are you sure you want to delete this homework?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              
              Get.dialog(
                WillPopScope(
                  onWillPop: () async => false,
                  child: AlertDialog(
                    content: Row(
                      children: const [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('Deleting...'),
                      ],
                    ),
                  ),
                ),
                barrierDismissible: false,
              );
              
              final homeworkId = homeworkController.homeworkList.firstWhereOrNull(
                (h) => (h['subjects'] as List).any((s) => s['_id'] == homework['_id']),
              )?['_id'];
              
              if (homeworkId != null) {
                final success = await homeworkController.deleteEntireDay(homeworkId);
                Get.back();
                
                if (success && schoolController.selectedSchool.value != null && selectedClass != null) {
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
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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
    if (lower == 'lkg' || lower == 'ukg') return Icons.child_care;
    if (lower.contains('grade 1') || lower.contains('grade 2') || lower.contains('grade 3')) return Icons.looks_one;
    if (lower.contains('grade 4') || lower.contains('grade 5') || lower.contains('grade 6')) return Icons.looks_two;
    if (lower.contains('grade 7') || lower.contains('grade 8') || lower.contains('grade 9')) return Icons.looks_3;
    return Icons.looks_4;
  }

  void _showAttachmentPreview(Map<String, dynamic> attachment, Map<String, dynamic> subject) {
    final url = attachment['url'] ?? '';
    final isImage = url.toLowerCase().contains(RegExp(r'\.(jpg|jpeg|png|gif)'));
    final auth = Get.find<AuthController>();
    final userRole = auth.user.value?.role?.toLowerCase() ?? '';
    
    Get.dialog(
      Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: isImage
                  ? InteractiveViewer(
                      child: Image.network(
                        url,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.broken_image, color: Colors.white, size: 64),
                          );
                        },
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.insert_drive_file, size: 80, color: Colors.white),
                          const SizedBox(height: 16),
                          Text(
                            attachment['name'] ?? 'File',
                            style: const TextStyle(color: Colors.white, fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: Row(
                children: [
                  if (ApiPermissions.hasApiAccess(userRole, 'DELETE /api/homework/deleteattachment'))
                    IconButton(
                      onPressed: () {
                        Get.back();
                        _showDeleteAttachmentConfirmation(subject, attachment);
                      },
                      icon: const Icon(Icons.delete, color: Colors.red, size: 30),
                    ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAttachmentConfirmation(Map<String, dynamic> subject, Map<String, dynamic> attachment) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Attachment'),
        content: Text('Are you sure you want to delete "${attachment['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              
              Get.dialog(
                WillPopScope(
                  onWillPop: () async => false,
                  child: const AlertDialog(
                    content: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('Deleting attachment...'),
                      ],
                    ),
                  ),
                ),
                barrierDismissible: false,
              );
              
              final homework = homeworkController.homeworkList.firstWhereOrNull(
                (h) => (h['subjects'] as List).any((s) => s['_id'] == subject['_id']),
              );
              
              if (homework != null) {
                final success = await homeworkController.deleteAttachment(
                  homeworkId: homework['_id'],
                  subjectId: subject['_id'],
                  attachmentId: attachment['_id'],
                );
                
                Navigator.pop(Get.context!);
                
                if (success && schoolController.selectedSchool.value != null && selectedClass != null) {
                  await homeworkController.getAllHomework(
                    schoolId: schoolController.selectedSchool.value!.id,
                    classId: selectedClass!.id,
                    sectionId: selectedSection?.id,
                  );
                }
              } else {
                Navigator.pop(Get.context!);
                Get.snackbar('Error', 'Could not find homework');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
